import 'package:acad_mate/app/providers.dart';
import 'package:acad_mate/core/widgets/brand_mark.dart';
import 'package:acad_mate/core/widgets/glass_card.dart';
import 'package:acad_mate/core/widgets/gradient_backdrop.dart';
import 'package:acad_mate/domain/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final TextEditingController _emailController;
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isBusy = false;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    // If we have an email, it means OTP was sent from RecoverPasswordScreen
    if (widget.email != null && widget.email!.isNotEmpty) {
      _otpSent = true;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final password = _passwordController.text;

    setState(() => _isBusy = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.resetPasswordWithOtp(
        email: email,
        code: otp,
        newPassword: password,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successful. You can now log in.')),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackdrop(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
          child: Column(
            children: [
              const BrandIntro(logoSize: 100, heroTag: 'acadmate-brand'),
              const SizedBox(height: 24),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Set New Password',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          if (widget.email != null)
                             Text(
                              'for ${widget.email}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 24),
                          if (!_otpSent) ...[
                            const SizedBox(height: 20),
                            _ResetActionButton(
                              isBusy: false,
                              label: 'Go Back to Recovery',
                              onPressed: () => context.go('/recover-password'),
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'A code has been sent to your email. Enter it below to proceed.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Verification Code',
                                prefixIcon: Icon(Icons.security_rounded),
                                hintText: '6-digit OTP',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().length != 6) {
                                  return 'Enter a valid 6-digit OTP';
                                }
                                return null;
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isBusy ? null : () async {
                                  final repo = ref.read(authRepositoryProvider);
                                  await repo.sendOtp(email: _emailController.text.trim(), type: 'password_reset');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Verification code resent')),
                                    );
                                  }
                                },
                                child: const Text('Resend Code?', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'New Password',
                                prefixIcon: Icon(Icons.lock_rounded),
                              ),
                              validator: (value) {
                                if (value == null || value.length < 6) return 'Password must be at least 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Confirm New Password',
                                prefixIcon: Icon(Icons.lock_clock_rounded),
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) return 'Passwords do not match';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _ResetActionButton(
                              isBusy: _isBusy,
                              label: 'Reset Password',
                              onPressed: _resetPassword,
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Back to Sign In'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResetActionButton extends StatelessWidget {
  const _ResetActionButton({
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
