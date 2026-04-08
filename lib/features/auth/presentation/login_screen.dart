import 'package:acad_mate/app/providers.dart';
import 'package:acad_mate/core/config/app_config.dart';
import 'package:acad_mate/core/theme/app_colors.dart';
import 'package:acad_mate/core/widgets/brand_mark.dart';
import 'package:acad_mate/core/widgets/glass_card.dart';
import 'package:acad_mate/core/widgets/gradient_backdrop.dart';
import 'package:acad_mate/domain/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _signInFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _signUpFormKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isSignIn = true;
  bool _isBusy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formKey = _isSignIn ? _signInFormKey : _signUpFormKey;
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_isSignIn) {
      await _runAuthAction((AuthRepository repo) async {
        await repo.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      });
    } else {
      // Sign up flow with OTP
      final String email = _emailController.text.trim();
      final String name = _nameController.text.trim();
      final String password = _passwordController.text;

      setState(() => _isBusy = true);
      try {
        final AuthRepository repo = ref.read(authRepositoryProvider);
        await repo.sendOtp(email: email, type: 'signup');
        if (!mounted) {
          return;
        }

        final String? otp = await _showOtpDialog(email, 'signup');
        if (otp == null || otp.trim().isEmpty) {
          setState(() => _isBusy = false);
          return;
        }

        await repo.verifyOtp(email: email, code: otp, type: 'signup');

        // Now register
        await _runAuthAction((AuthRepository repo) async {
          await repo.register(
            name: name,
            email: email,
            password: password,
            grade: 'A/L',
            stream: 'Science',
          );
        });
      } catch (error) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _signInWithProvider(SocialAuthProvider provider) async {
    await _runAuthAction((AuthRepository repo) {
      return repo.signInWithProvider(provider);
    });
  }

  Future<void> _runAuthAction(
    Future<void> Function(AuthRepository repo) action,
  ) async {
    FocusScope.of(context).unfocus();
    setState(() => _isBusy = true);

    final AuthRepository repo = ref.read(authRepositoryProvider);
    try {
      await action(repo);

      if (!mounted) {
        return;
      }
      context.go('/app');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    context.push('/recover-password?email=$email');
  }

  Future<String?> _showOtpDialog(String email, String type) async {
    final TextEditingController otpController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Verify Email'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('A verification code has been sent to $email'),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Enter OTP',
                    hintText: '6-digit code',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, otpController.text),
                child: const Text('Verify'),
              ),
            ],
          ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final bool supportsFederatedAuth =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final Widget socialAuthSection =
        supportsFederatedAuth || !AppConfig.useFirebase
        ? Row(
            children: <Widget>[
              Expanded(
                child: _SocialAuthButton(
                  label: 'Google',
                  accent: const Color(0xFFDB4437),
                  borderColor: const Color(0xFFDB4437),
                  icon: const Icon(Icons.g_mobiledata, size: 18),
                  isBusy: _isBusy,
                  onPressed: () =>
                      _signInWithProvider(SocialAuthProvider.google),
                ),
              ),
              // Removed Facebook login button
              /* const SizedBox(width: 12),
              Expanded(
                child: _SocialAuthButton(
                  label: 'Facebook',
                  accent: const Color(0xFF1877F2),
                  icon: const Icon(Icons.facebook, size: 18),
                  isBusy: _isBusy,
                  onPressed: () =>
                      _signInWithProvider(SocialAuthProvider.facebook),
                ),
              ), */
              const SizedBox(width: 12),
              Expanded(
                child: _SocialAuthButton(
                  label: 'Apple',
                  accent: Colors.black,
                  borderColor: Colors.white,
                  icon: const Icon(Icons.apple, size: 18),
                  isBusy: _isBusy,
                  onPressed: () =>
                      _signInWithProvider(SocialAuthProvider.apple),
                ),
              ),
            ],
          )
        : Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Social login is available on mobile, macOS, and web.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackdrop(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      BrandLogo(
                        size: 120,
                        heroTag: 'acadmate-brand',
                        imageUrl: 'assets/branding/app_icon.png',
                      ),
                      const SizedBox(height: 18),
                      const BrandWordmark(),
                      const SizedBox(height: 8),
                      Text(
                        AppConfig.tagline,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  GlassCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: InkWell(
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(20),
                                  ),
                                  onTap: () => setState(() => _isSignIn = true),
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: _isSignIn
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      borderRadius: const BorderRadius.horizontal(
                                        left: Radius.circular(20),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Sign In',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: _isSignIn
                                                ? Colors.white
                                                : AppColors.text,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(20),
                                  ),
                                  onTap: () => setState(() => _isSignIn = false),
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: !_isSignIn
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      borderRadius: const BorderRadius.horizontal(
                                        right: Radius.circular(20),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Create Account',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: !_isSignIn
                                                ? Colors.white
                                                : AppColors.text,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          child: _isSignIn
                              ? Form(
                                  key: _signInFormKey,
                                  child: Column(
                                    key: const ValueKey<String>('signIn'),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: const InputDecoration(
                                          labelText: 'Email address',
                                          prefixIcon: Icon(Icons.email_rounded),
                                        ),
                                        validator: _validateEmail,
                                      ),
                                      const SizedBox(height: 14),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon: Icon(Icons.lock_rounded),
                                        ),
                                        validator: _validatePassword,
                                      ),
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: _forgotPassword,
                                          child: const Text('Forgot password?'),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      _ActionButton(
                                        isBusy: _isBusy,
                                        label: 'Sign In',
                                        onPressed: _submit,
                                      ),
                                    ],
                                  ),
                                )
                              : Form(
                                  key: _signUpFormKey,
                                  child: Column(
                                    key: const ValueKey<String>('signUp'),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      TextFormField(
                                        controller: _nameController,
                                        textInputAction: TextInputAction.next,
                                        decoration: const InputDecoration(
                                          labelText: 'Full name',
                                          prefixIcon: Icon(Icons.person_rounded),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().length < 3) {
                                            return 'Enter your full name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 14),
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        decoration: const InputDecoration(
                                          labelText: 'Email address',
                                          prefixIcon: Icon(Icons.email_rounded),
                                        ),
                                        validator: _validateEmail,
                                      ),
                                      const SizedBox(height: 14),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon: Icon(Icons.lock_rounded),
                                        ),
                                        validator: _validatePassword,
                                      ),
                                      const SizedBox(height: 16),
                                      _ActionButton(
                                        isBusy: _isBusy,
                                        label: 'Create account',
                                        onPressed: _submit,
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: <Widget>[
                            const Expanded(child: Divider()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'Or continue with',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        socialAuthSection,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Enter your email';
    }
    final bool valid = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(text);
    if (!valid) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.isBusy,
    required this.label,
    required this.onPressed,
  });

  final bool isBusy;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: isBusy ? null : onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: isBusy
              ? const SizedBox(
                  key: ValueKey<String>('loading'),
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : Text(label, key: ValueKey<String>(label)),
        ),
      ),
    );
  }
}

class _SocialAuthButton extends StatelessWidget {
  const _SocialAuthButton({
    required this.label,
    required this.accent,
    required this.icon,
    required this.borderColor,
    required this.isBusy,
    required this.onPressed,
  });

  final String label;
  final Color accent;
  final Color borderColor;
  final Widget icon;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: isBusy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: borderColor),
        foregroundColor: colors.onSurface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: icon,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
