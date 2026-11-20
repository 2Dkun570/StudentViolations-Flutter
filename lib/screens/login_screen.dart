import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/fcm_service.dart';
import '../services/demo_mode.dart';
import '../theme/app_theme.dart';

const _red = AppColors.red;
const _navy = AppColors.navy;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/aclc_campus_background.jpg',
              key: const ValueKey('login-campus-background'),
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x4D090C47), Color(0x80090C47)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 28),

                          // ── Card ──────────────────────────────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF173B5C,
                              ).withValues(alpha: 0.38),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.8),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _navy.withValues(alpha: 0.35),
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                key: const ValueKey('login-glass-card'),
                                filter: ImageFilter.blur(
                                  sigmaX: 22,
                                  sigmaY: 22,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                  child: Padding(
                                    padding: const EdgeInsets.all(28.0),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Login',
                                            style: TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            'Welcome back, please sign in to your account',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const SizedBox(height: 28),

                                          // ── Username ──────────────────────────
                                          _buildTextField(
                                            controller: _usernameController,
                                            label: 'Email or Username',
                                            icon: Icons.person_outline_rounded,
                                            validator: (v) =>
                                                (v == null || v.isEmpty)
                                                ? 'Please enter your email or username'
                                                : null,
                                          ),
                                          const SizedBox(height: 16),

                                          // ── Password ──────────────────────────
                                          _buildTextField(
                                            controller: _passwordController,
                                            label: 'Password',
                                            icon: Icons.lock_outline_rounded,
                                            obscure: _obscurePassword,
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons
                                                          .visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: Colors.white70,
                                                size: 20,
                                              ),
                                              onPressed: () => setState(
                                                () => _obscurePassword =
                                                    !_obscurePassword,
                                              ),
                                            ),
                                            validator: (v) =>
                                                (v == null || v.isEmpty)
                                                ? 'Please enter your password'
                                                : null,
                                          ),
                                          CheckboxListTile(
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                            activeColor: const Color(
                                              0xFF78B8D1,
                                            ),
                                            checkColor: _navy,
                                            title: const Text(
                                              'Remember me',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white,
                                              ),
                                            ),
                                            value: _rememberMe,
                                            onChanged: (value) => setState(
                                              () =>
                                                  _rememberMe = value ?? false,
                                            ),
                                          ),
                                          const SizedBox(height: 20),

                                          // ── Login Button ──────────────────────
                                          _buildLoginButton(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/images/ACLC.png',
                key: const ValueKey('login-aclc-logo'),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'ACLC College of Mandaue',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _red.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _red.withValues(alpha: 0.35)),
          ),
          child: const Text(
            'Student Violation System',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ── Text field ───────────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.65)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.65)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }

  // ── Login button ─────────────────────────────────────────────────────────────
  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        return Container(
          height: 56,
          decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _navy.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Login',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Login logic ──────────────────────────────────────────────────────────────
  void _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(
        _usernameController.text,
        _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (authProvider.pendingAuthenticator != null) {
        final verified = await _showAuthenticatorDialog(authProvider);
        if (!verified) return;
      }

      if (authProvider.currentUser != null) {
        final recoveryCodes = authProvider.consumeRecoveryCodes();
        if (recoveryCodes.isNotEmpty) {
          await _showRecoveryCodes(recoveryCodes);
        }
        if (!mounted) return;
        if (!DemoMode.enabled) {
          await FCMService.registerTokenAfterLogin();
        }
        if (mounted) Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Login failed'),
              backgroundColor: _red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  Future<bool> _showAuthenticatorDialog(AuthProvider authProvider) async {
    final flow = authProvider.pendingAuthenticator!;
    final isSetup = flow['requiresAuthenticatorSetup'] == true;
    final qrDataUri = flow['qrCodeDataUri']?.toString();
    final manualKey = flow['manualEntryKey']?.toString();
    final challengeCodeController = TextEditingController();
    var submitting = false;
    String? dialogError;

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> submitCode() async {
            final code = challengeCodeController.text.trim();
            if (code.isEmpty) {
              setDialogState(
                () => dialogError = 'Enter an authenticator or recovery code.',
              );
              return;
            }

            setDialogState(() {
              dialogError = null;
              submitting = true;
            });
            await authProvider.verifyAuthenticatorCode(code);
            if (!dialogContext.mounted) return;
            if (authProvider.currentUser != null) {
              Navigator.of(dialogContext).pop(true);
            } else {
              setDialogState(() {
                dialogError =
                    authProvider.error ?? 'Authenticator verification failed.';
                submitting = false;
              });
            }
          }

          return AlertDialog(
            title: Text(
              isSetup ? 'Set up authenticator' : 'Verify sign-in',
              style: const TextStyle(color: _navy, fontWeight: FontWeight.w700),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isSetup
                        ? 'Scan this QR code with an authenticator app, then enter the generated code.'
                        : 'Enter the current code from your authenticator app. You may also use a recovery code.',
                  ),
                  if (isSetup && qrDataUri != null) ...[
                    const SizedBox(height: 16),
                    Image.memory(
                      base64Decode(
                        qrDataUri.substring(qrDataUri.indexOf(',') + 1),
                      ),
                      width: 180,
                      height: 180,
                      errorBuilder: (_, _, _) => const Text(
                        'Could not display the QR code. Use the manual key below.',
                      ),
                    ),
                  ],
                  if (isSetup && manualKey != null) ...[
                    const SizedBox(height: 12),
                    const Text('Manual setup key'),
                    SelectableText(
                      manualKey,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: challengeCodeController,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Authenticator or recovery code',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => submitCode(),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 10),
                    Text(dialogError!, style: const TextStyle(color: _red)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: submitting ? null : submitCode,
                style: ElevatedButton.styleFrom(backgroundColor: _navy),
                child: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verify'),
              ),
            ],
          );
        },
      ),
    );

    challengeCodeController.dispose();
    return verified == true;
  }

  Future<void> _showRecoveryCodes(List<String> codes) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save your recovery codes'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'These codes can each be used once if you lose access to your authenticator. Save them somewhere safe.',
              ),
              const SizedBox(height: 12),
              for (final code in codes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: SelectableText(code),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
