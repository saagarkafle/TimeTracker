import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/shift.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userShiftsRef(String uid) =>
      _db.collection('users').doc(uid).collection('shifts');

  DocumentReference<Map<String, dynamic>> _weekPaidDoc(String uid) =>
      _db.collection('users').doc(uid).collection('meta').doc('weeksPaid');

  Future<void> uploadShift(String uid, String dateKey, Shift shift) async {
    final ref = _userShiftsRef(uid).doc(dateKey);
    await ref.set(shift.toJson());
  }

  Future<void> removeShift(String uid, String dateKey) async {
    final ref = _userShiftsRef(uid).doc(dateKey);
    await ref.delete();
  }

  Stream<List<MapEntry<String, Shift>>> listenShifts(String uid) {
    return _userShiftsRef(uid).snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        return MapEntry(d.id, Shift.fromJson(data));
      }).toList();
    });
  }

  Future<Map<String, bool>> getWeekPaid(String uid) async {
    final doc = await _weekPaidDoc(uid).get();
    if (!doc.exists) return {};
    final data = doc.data() ?? {};
    final out = <String, bool>{};
    data.forEach((k, v) {
      out[k] = v == true || v == 'true' || v == 1;
    });
    return out;
  }

  Future<void> setWeekPaidMap(String uid, Map<String, bool> map) async {
    await _weekPaidDoc(uid).set(map);
  }

  Stream<Map<String, bool>> listenWeekPaid(String uid) {
    return _weekPaidDoc(uid).snapshots().map((snap) {
      final data = snap.data() ?? <String, dynamic>{};
      final out = <String, bool>{};
      data.forEach((k, v) {
        out[k] = v == true || v == 'true' || v == 1;
      });
      return out;
    });
  }
}
