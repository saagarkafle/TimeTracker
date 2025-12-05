import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../utils/firebase_debug.dart';
import 'signup_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _isLoading = false;
  bool _showPassword = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final scaffold = ScaffoldMessenger.of(context);

    try {
      await auth.signInWithGoogle();
      if (!mounted) return;
      scaffold.showSnackBar(
        const SnackBar(content: Text('Signed in successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString();

      if (errorMsg.contains('DEVELOPER_ERROR') ||
          errorMsg.contains('Unable to obtain ID token') ||
          errorMsg.contains('SHA-1')) {
        FirebaseDebug.showSetupInstructions(context);
      } else {
        scaffold.showSnackBar(
          SnackBar(content: Text('Sign-in failed: $errorMsg')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final scaffold = ScaffoldMessenger.of(context);

    try {
      await auth.signInWithEmail(email, password);
      if (!mounted) return;
      scaffold.showSnackBar(
        const SnackBar(content: Text('Signed in successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      scaffold.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                  ]
                : [const Color(0xFF667eea), const Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),

                          // Enhanced App Logo
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.9),
                                    Colors.white.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.schedule,
                                size: 50,
                                color: Color(0xFF667eea),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // App name with better styling
                          Text(
                            'Track My Shift',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 28,
                                  letterSpacing: 0.5,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),

                          // Enhanced tagline
                          Text(
                            'Effortlessly manage your shifts\nand track your earnings',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          // Email input field
                          TextField(
                            controller: _emailController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              hintText: 'Email address',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: Colors.white,
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),

                          // Password input field
                          TextField(
                            controller: _passwordController,
                            enabled: !_isLoading,
                            obscureText: !_showPassword,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Colors.white,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                onPressed: () {
                                  setState(
                                    () => _showPassword = !_showPassword,
                                  );
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              if (!_isLoading) _signInWithEmail();
                            },
                          ),
                          const SizedBox(height: 12),

                          // Sign in button
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signInWithEmail,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF667eea),
                                  elevation: 0,
                                  disabledBackgroundColor: Colors.white
                                      .withValues(alpha: 0.6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                const Color(
                                                  0xFF667eea,
                                                ).withValues(alpha: 0.7),
                                              ),
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Enhanced Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'or continue with',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Sign in with Google button
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : _signInWithGoogle,
                                icon: const Icon(
                                  Icons.account_circle,
                                  size: 24,
                                ),
                                label: const Text(
                                  'Sign in with Google',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.15,
                                  ),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Create account button - Enhanced
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SignUpPage(),
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.person_add, size: 24),
                                label: const Text(
                                  'Create New Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Enhanced Privacy notice
                          Column(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                color: Colors.white.withValues(alpha: 0.6),
                                size: 20,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your data is securely stored\nand synced across all your devices',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
