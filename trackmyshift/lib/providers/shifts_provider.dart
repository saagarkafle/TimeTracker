import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/shift.dart';
import '../services/firestore_service.dart';
import '../utils/notifications.dart';

class ShiftsProvider extends ChangeNotifier {
  static const _shiftsKey = 'shifts_history_json';
  static const _paidKey = 'weeks_paid_json';

  // Keyed by date string 'yyyy-MM-dd'
  final Map<String, Shift> _shifts = {};
  // Keyed by week-start date string 'yyyy-MM-dd' -> true if paid
  final Map<String, bool> _weekPaid = {};

  ShiftsProvider() {
    _loadFromPrefs();
  }

  // Firestore helpers
  FirestoreService? _firestore;
  StreamSubscription<List<MapEntry<String, Shift>>>? _shiftsSub;
  StreamSubscription<Map<String, bool>>? _paidSub;
  String? _attachedUid;

  /// Attach a logged-in user (uid) to enable cloud sync. Passing null disables sync.
  void attachUser(String? uid) async {
    // detach previous
    if (_attachedUid == uid) return;
    _attachedUid = uid;
    await _shiftsSub?.cancel();
    await _paidSub?.cancel();
    _firestore = null;

    if (uid == null) {
      // Logged out: clear local data
      _shifts.clear();
      _weekPaid.clear();
      await _saveToPrefs();
      notifyListeners();
      return;
    }

    _firestore = FirestoreService();

    // Keep a snapshot of local data BEFORE clearing
    final localShifts = Map<String, Shift>.from(_shifts);
    final localPaid = Map<String, bool>.from(_weekPaid);

    // Do NOT clear data here - wait for Firestore to populate first
    // This prevents data loss if there's a network delay or Firestore is empty

    // Listen to remote shifts for the new user
    _shiftsSub = _firestore!.listenShifts(uid).listen((remoteList) {
      var updated = false;
      final Map<String, Shift> remoteMap = {};

      for (final e in remoteList) {
        final key = e.key;
        final shift = e.value;
        remoteMap[key] = shift;
        final local = _shifts[key];
        if (local == null || local != shift) {
          _shifts[key] = shift;
          updated = true;
        }
      }

      // Merge local-only data (data recorded before syncing) into the map
      for (final e in localShifts.entries) {
        if (!remoteMap.containsKey(e.key)) {
          // This data exists locally but not on Firestore - keep it and upload
          _shifts[e.key] = e.value;
          unawaited(_firestore!.uploadShift(uid, e.key, e.value));
          updated = true;
        }
      }

      if (updated) {
        _saveToPrefs();
        notifyListeners();
      }
    });

    _paidSub = _firestore!.listenWeekPaid(uid).listen((map) {
      var updated = false;

      // Merge remote data with existing local data instead of clearing
      final remoteMap = Map<String, bool>.from(map);

      // Add any local-only week paid data
      for (final e in localPaid.entries) {
        if (!remoteMap.containsKey(e.key)) {
          remoteMap[e.key] = e.value;
          updated = true;
        }
      }

      // Update _weekPaid only if something changed
      if (remoteMap.length != _weekPaid.length ||
          !remoteMap.entries.every((e) => _weekPaid[e.key] == e.value)) {
        _weekPaid.clear();
        _weekPaid.addAll(remoteMap);
        updated = true;
      }

      if (updated) {
        _saveToPrefs();
      }

      notifyListeners();
    });
  }

  // Convenience getters for today's arrival/departure (used by existing UI)
  DateTime? get arrival => _shiftForDate(DateTime.now())?.arrival;
  DateTime? get departure => _shiftForDate(DateTime.now())?.departure;

  Shift? _shiftForDate(DateTime date) {
    final key = _dateKey(date);
    return _shifts[key];
  }

  void recordArrival() {
    final now = DateTime.now();
    final key = _dateKey(now);
    final existing = _shifts[key];
    _shifts[key] = Shift(
      arrival: now,
      departure: existing?.departure,
      manager: existing?.manager,
    );
    _saveToPrefs();
    notifyListeners();
  }

  /// Record arrival at a specific [dateTime]. Useful for manual/edited entries.
  void recordArrivalAt(DateTime dateTime, {String? manager}) {
    final key = _dateKey(dateTime);
    final existing = _shifts[key];
    _shifts[key] = Shift(
      arrival: dateTime,
      departure: existing?.departure,
      manager: manager ?? existing?.manager,
    );
    _saveToPrefs();
    notifyListeners();
  }

  /// Record arrival with an explicit manager (for check-in flows).
  void recordArrivalWithManager(String manager) {
    final now = DateTime.now();
    final key = _dateKey(now);
    final existing = _shifts[key];
    _shifts[key] = Shift(
      arrival: now,
      departure: existing?.departure,
      manager: manager,
    );
    _saveToPrefs();
    // notify user about check-in
    Notifications.showNotification(
      now.hashCode & 0x7fffffff,
      'Checked in',
      'You checked in with manager $manager at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    );
    notifyListeners();
  }

  void recordDeparture() {
    final now = DateTime.now();
    final key = _dateKey(now);
    final existing = _shifts[key];
    _shifts[key] = Shift(
      arrival: existing?.arrival,
      departure: now,
      manager: existing?.manager,
    );
    _saveToPrefs();
    // notify user about check-out
    Notifications.showNotification(
      now.hashCode & 0x7fffffff,
      'Checked out',
      'You checked out at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    );
    notifyListeners();
  }

  /// Record departure at a specific [dateTime]. Useful for manual/edited entries.
  void recordDepartureAt(DateTime dateTime) {
    final key = _dateKey(dateTime);
    final existing = _shifts[key];
    _shifts[key] = Shift(
      arrival: existing?.arrival,
      departure: dateTime,
      manager: existing?.manager,
    );
    _saveToPrefs();
    notifyListeners();
  }

  void clear() {
    _shifts.clear();
    _saveToPrefs();
    notifyListeners();
  }

  void clearArrival() {
    final key = _dateKey(DateTime.now());
    final existing = _shifts[key];
    if (existing != null) {
      _shifts[key] = Shift(arrival: null, departure: existing.departure);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void clearDeparture() {
    final key = _dateKey(DateTime.now());
    final existing = _shifts[key];
    if (existing != null) {
      _shifts[key] = Shift(arrival: existing.arrival, departure: null);
      _saveToPrefs();
      notifyListeners();
    }
  }

  /// Clear today's record (remove today's entry).
  void clearToday() {
    final key = _dateKey(DateTime.now());
    if (_shifts.containsKey(key)) {
      _shifts.remove(key);
      _saveToPrefs();
      notifyListeners();
    }
  }

  // Return a copy of the internal map (keys sorted descending)
  Map<String, Shift> get allShifts {
    final map = Map<String, Shift>.fromEntries(
      _shifts.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
    return map;
  }

  // Get past shifts (before today)
  Map<String, Shift> get pastShifts {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final map = Map<String, Shift>.fromEntries(
      _shifts.entries.where((e) {
        final dt = DateTime.tryParse(e.key);
        return dt != null && dt.isBefore(today);
      }).toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
    return map;
  }

  // Get upcoming shifts (today and future)
  Map<String, Shift> get upcomingShifts {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final map = Map<String, Shift>.fromEntries(
      _shifts.entries.where((e) {
        final dt = DateTime.tryParse(e.key);
        return dt != null && !dt.isBefore(today);
      }).toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return map;
  }

  // Group past shifts by month (for history view)
  Map<String, List<MapEntry<String, Shift>>> groupPastByMonth() {
    final Map<String, List<MapEntry<String, Shift>>> out = {};
    final entries = pastShifts.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    for (final e in entries) {
      if (!_isValidDateKey(e.key)) continue;
      final dt = DateTime.tryParse(e.key);
      if (dt == null) continue;
      final monthKey =
          '${dt.year.toString().padLeft(4, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}';
      out.putIfAbsent(monthKey, () => []).add(e);
    }
    return out;
  }

  // Group upcoming shifts by month
  Map<String, List<MapEntry<String, Shift>>> groupUpcomingByMonth() {
    final Map<String, List<MapEntry<String, Shift>>> out = {};
    final entries = upcomingShifts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final e in entries) {
      if (!_isValidDateKey(e.key)) continue;
      final dt = DateTime.tryParse(e.key);
      if (dt == null) continue;
      final monthKey =
          '${dt.year.toString().padLeft(4, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}';
      out.putIfAbsent(monthKey, () => []).add(e);
    }
    return out;
  }

  // Validate if a key is in valid date format (yyyy-MM-dd)
  bool _isValidDateKey(String key) {
    if (key.isEmpty) return false;
    final parts = key.split('-');
    if (parts.length != 3) return false;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return false;
    if (year < 2000 || year > 2100) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    return true;
  }

  // Group shifts by month key 'yyyy-MM'
  Map<String, List<MapEntry<String, Shift>>> groupByMonth() {
    final Map<String, List<MapEntry<String, Shift>>> out = {};
    final entries = _shifts.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    for (final e in entries) {
      if (!_isValidDateKey(e.key)) continue;
      final dt = DateTime.tryParse(e.key);
      if (dt == null) continue;
      final monthKey =
          '${dt.year.toString().padLeft(4, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}';
      out.putIfAbsent(monthKey, () => []).add(e);
    }
    return out;
  }

  // For a given month (year, month) group entries by week start (Monday)
  Map<String, List<MapEntry<String, Shift>>> weeksForMonth(
    int year,
    int month,
  ) {
    final Map<String, List<MapEntry<String, Shift>>> out = {};
    final entries = _shifts.entries.where((e) {
      if (!_isValidDateKey(e.key)) return false;
      final dt = DateTime.tryParse(e.key);
      return dt != null && dt.year == year && dt.month == month;
    }).toList()..sort((a, b) => a.key.compareTo(b.key));

    for (final e in entries) {
      final dt = DateTime.tryParse(e.key);
      if (dt == null) continue;
      final weekStart = _weekStart(dt);
      final weekKey = _dateKey(weekStart);
      out.putIfAbsent(weekKey, () => []).add(e);
    }
    return out;
  }

  // Group all shifts by week start (Monday). Keyed by 'yyyy-MM-dd' week start.
  Map<String, List<MapEntry<String, Shift>>> groupByWeek() {
    final Map<String, List<MapEntry<String, Shift>>> out = {};
    final entries = _shifts.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    for (final e in entries) {
      final dt = DateTime.tryParse(e.key);
      if (dt == null) continue;
      final weekStart = _weekStart(dt);
      final weekKey = _dateKey(weekStart);
      out.putIfAbsent(weekKey, () => []).add(e);
    }
    return out;
  }

  DateTime _weekStart(DateTime dt) {
    // Week starts Monday
    final int diff = dt.weekday - 1; // Monday=1
    return DateTime(dt.year, dt.month, dt.day).subtract(Duration(days: diff));
  }

  String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_shiftsKey);
    if (jsonStr == null || jsonStr.isEmpty) return;
    try {
      final Map<String, dynamic> decoded =
          json.decode(jsonStr) as Map<String, dynamic>;
      _shifts.clear();
      decoded.forEach((key, value) {
        // Only load valid date keys
        if (_isValidDateKey(key) && value is Map<String, dynamic>) {
          _shifts[key] = Shift.fromJson(value);
        }
      });
      // load paid weeks map
      final paidStr = prefs.getString(_paidKey);
      if (paidStr != null && paidStr.isNotEmpty) {
        try {
          final Map<String, dynamic> paidDecoded =
              json.decode(paidStr) as Map<String, dynamic>;
          _weekPaid.clear();
          paidDecoded.forEach((k, v) {
            if (_isValidDateKey(k)) {
              _weekPaid[k] = v == true || v == 'true' || v == 1;
            }
          });
        } catch (_) {
          // ignore paid parse
        }
      }
      notifyListeners();
    } catch (_) {
      // ignore parse errors
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> toSave = {};
    _shifts.forEach((k, v) => toSave[k] = v.toJson());
    await prefs.setString(_shiftsKey, json.encode(toSave));
    // save paid weeks
    final Map<String, dynamic> paidToSave = {};
    _weekPaid.forEach((k, v) => paidToSave[k] = v);
    await prefs.setString(_paidKey, json.encode(paidToSave));
    // if attached to a user, also propagate to Firestore asynchronously
    if (_attachedUid != null && _firestore != null) {
      final uid = _attachedUid!;
      // upload shifts
      for (final e in _shifts.entries) {
        unawaited(_firestore!.uploadShift(uid, e.key, e.value));
      }
      // upload weeks paid map
      unawaited(_firestore!.setWeekPaidMap(uid, _weekPaid));
    }
  }

  /// Remove a specific day's record (key in 'yyyy-MM-dd')
  void removeDay(String dateKey) {
    if (_shifts.containsKey(dateKey)) {
      _shifts.remove(dateKey);
      _saveToPrefs();
      notifyListeners();
    }
  }

  /// Week paid status helpers. Week keys are the week-start dateKey (Monday).
  bool isWeekPaid(String weekKey) => _weekPaid[weekKey] ?? false;

  void setWeekPaid(String weekKey, bool paid) {
    final prev = _weekPaid[weekKey] ?? false;
    _weekPaid[weekKey] = paid;
    _saveToPrefs();
    // notify only when changed
    if (prev != paid) {
      Notifications.showNotification(
        weekKey.hashCode & 0x7fffffff,
        paid ? 'Week marked Paid' : 'Week marked Not Paid',
        paid
            ? 'Week starting $weekKey marked as Paid'
            : 'Week starting $weekKey marked as Not Paid',
      );
      // If attached to a user, propagate weeks map immediately
      if (_attachedUid != null && _firestore != null) {
        unawaited(_firestore!.setWeekPaidMap(_attachedUid!, _weekPaid));
      }
    }
    notifyListeners();
  }
}
