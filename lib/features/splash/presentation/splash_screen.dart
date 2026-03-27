import 'package:acad_mate/app/providers.dart';
import 'package:acad_mate/core/config/app_config.dart';
import 'package:acad_mate/core/theme/app_colors.dart';
import 'package:acad_mate/core/widgets/brand_mark.dart';
import 'package:acad_mate/core/widgets/glass_card.dart';
import 'package:acad_mate/core/widgets/gradient_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted || _didNavigate) {
      return;
    }

    _didNavigate = true;
    final user = await ref.read(authRepositoryProvider).currentUser();
    if (!mounted) {
      return;
    }

    context.go(user == null ? '/login' : '/app');
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackdrop(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            borderRadius: BorderRadius.circular(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                BrandIntro(
                  logoSize: 170,
                  heroTag: 'acadmate-brand',
                )
                    .animate()
                    .fadeIn(duration: 700.ms)
                    .scale(
                      begin: const Offset(0.88, 0.88),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 26),
                Container(
                  width: 180,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.08),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 116,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: <Color>[
                            AppColors.primary,
                            AppColors.secondary,
                          ],
                        ),
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .moveX(begin: -8, end: 70, duration: 1200.ms),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Curated MCQs, past papers, and exam tracking',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : null,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppConfig.useMongoBackend
                      ? 'Firebase auth with MongoDB profile sync'
                      : AppConfig.useFirebase
                          ? 'Connected to Firebase'
                          : 'Demo mode ready for Firebase setup',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white60
                            : null,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

