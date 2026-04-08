import 'package:acad_mate/app/providers.dart';
import 'package:acad_mate/core/theme/app_colors.dart';
import 'package:acad_mate/core/widgets/brand_mark.dart';
import 'package:acad_mate/core/widgets/glass_card.dart';
import 'package:acad_mate/core/widgets/gradient_backdrop.dart';
import 'package:acad_mate/core/widgets/section_header.dart';
import 'package:acad_mate/features/papers/application/paper_favorites_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final favoritesAsync = ref.watch(paperFavoritesProvider);
    final int savedCount = favoritesAsync.maybeWhen(
      data: (PaperFavoritesState favorites) => favorites.favoritePaperIds.length,
      orElse: () => 0,
    );
    final user = userAsync.maybeWhen(data: (user) => user, orElse: () => null);

    return GradientBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
        children: <Widget>[
          const SectionHeader(
            title: 'Profile',
            subtitle: 'Your study progress and account status.',
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    BrandLogo(
                      size: 84,
                      heroTag: null,
                      imageUrl: user?.authProvider == 'google.com'
                          ? user?.avatarUrl
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            user?.name ?? 'AcadMate Student',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user?.email ?? 'Not signed in',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _MetricCard(
                        label: 'Streak',
                        value: '${user?.streakDays ?? 0} days',
                        icon: Icons.local_fire_department_rounded,
                        accent: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Solved',
                        value: '${user?.completedQuestions ?? 0}',
                        icon: Icons.check_circle_rounded,
                        accent: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Papers',
                        value: '$savedCount',
                        icon: Icons.picture_as_pdf_rounded,
                        accent: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onSignOut,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: accent),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
