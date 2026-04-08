import 'dart:ui';

import 'package:acad_mate/app/providers.dart';
import 'package:acad_mate/core/theme/app_colors.dart';
import 'package:acad_mate/core/widgets/brand_mark.dart';
import 'package:acad_mate/core/widgets/glass_card.dart';
import 'package:acad_mate/core/widgets/gradient_backdrop.dart';
import 'package:acad_mate/core/widgets/section_header.dart';
import 'package:acad_mate/domain/entities/past_paper.dart';
import 'package:acad_mate/domain/entities/question_set.dart';
import 'package:acad_mate/features/papers/application/paper_favorites_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onOpenPractice,
    required this.onOpenPapers,
  });

  final VoidCallback onOpenPractice;
  final VoidCallback onOpenPapers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final questionSetsAsync = ref.watch(questionSetsProvider);
    final papersAsync = ref.watch(pastPapersProvider);
    final favoritesAsync = ref.watch(paperFavoritesProvider);
    final int favoritesCount = favoritesAsync.maybeWhen(
      data: (PaperFavoritesState favorites) => favorites.favoritePaperIds.length,
      orElse: () => 0,
    );
    final user = userAsync.maybeWhen(
      data: (user) => user,
      orElse: () => null,
    );

    return GradientBackdrop(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 140),
        children: <Widget>[
          _HeroCard(
            userName: _firstName(user?.name) ?? 'Student',
            avatarUrl: user?.avatarUrl,
            streakDays: user?.streakDays ?? 0,
            completedQuestions: user?.completedQuestions ?? 0,
            bookmarkedPapers: favoritesCount,
            onOpenPractice: onOpenPractice,
            onOpenPapers: onOpenPapers,
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08, end: 0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 20),
                const SectionHeader(
                  title: 'Smart shortcuts',
                  subtitle: 'Jump straight into common study lanes.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    _ShortcutTile(
                      title: 'A/L Science',
                      subtitle: 'Physics, Chemistry, Biology',
                      icon: Icons.science_rounded,
                      accent: AppColors.primary,
                      onTap: () {
                        final controller = ref.read(catalogFilterProvider.notifier);
                        controller
                          ..setGrade('A/L')
                          ..setStream('Science');
                        onOpenPractice();
                      },
                    ),
                    _ShortcutTile(
                      title: 'A/L Commerce',
                      subtitle: 'Accounting, Economics, IS',
                      icon: Icons.account_balance_rounded,
                      accent: AppColors.secondary,
                      onTap: () {
                        final controller = ref.read(catalogFilterProvider.notifier);
                        controller
                          ..setGrade('A/L')
                          ..setStream('Commerce');
                        onOpenPractice();
                      },
                    ),
                    _ShortcutTile(
                      title: 'O/L Mathematics',
                      subtitle: 'Equation and algebra drills',
                      icon: Icons.calculate_rounded,
                      accent: AppColors.accent,
                      onTap: () {
                        final controller = ref.read(catalogFilterProvider.notifier);
                        controller
                          ..setGrade('O/L')
                          ..setSubject('Mathematics');
                        onOpenPractice();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SectionHeader(
                  title: 'Featured question sets',
                  subtitle: 'Built for quick practice sessions.',
                  actionLabel: 'Practice',
                  onAction: onOpenPractice,
                ),
                const SizedBox(height: 12),
                questionSetsAsync.when(
                  data: (List<QuestionSet> sets) {
                    final List<QuestionSet> featured = sets.take(3).toList();
                    if (featured.isEmpty) {
                      return const _EmptyCard(
                        title: 'No sets match your current filters.',
                        subtitle: 'Open Practice and tweak the filters.',
                      );
                    }

                    return Column(
                      children: featured
                          .map(
                            (QuestionSet set) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _QuestionSetMiniCard(
                                set: set,
                                onTap: onOpenPractice,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                  loading: () => const _LoadingStack(),
                  error: (Object error, StackTrace stackTrace) => _EmptyCard(
                    title: 'Could not load practice sets',
                    subtitle: error.toString(),
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeader(
                  title: 'Past papers',
                  subtitle: 'PDFs ready for in-app review.',
                  actionLabel: 'Open',
                  onAction: onOpenPapers,
                ),
                const SizedBox(height: 12),
                papersAsync.when(
                  data: (List<PastPaper> papers) {
                    final List<PastPaper> latest = papers.take(2).toList();
                    if (latest.isEmpty) {
                      return const _EmptyCard(
                        title: 'No papers match your current filters.',
                        subtitle: 'Open Papers and try a different subject.',
                      );
                    }

                    return Column(
                      children: latest
                          .map(
                            (PastPaper paper) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _PaperMiniCard(
                                paper: paper,
                                onTap: onOpenPapers,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                  loading: () => const _LoadingStack(),
                  error: (Object error, StackTrace stackTrace) => _EmptyCard(
                    title: 'Could not load papers',
                    subtitle: error.toString(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.userName,
    this.avatarUrl,
    required this.streakDays,
    required this.completedQuestions,
    required this.bookmarkedPapers,
    required this.onOpenPractice,
    required this.onOpenPapers,
  });

  final String userName;
  final String? avatarUrl;
  final int streakDays;
  final int completedQuestions;
  final int bookmarkedPapers;
  final VoidCallback onOpenPractice;
  final VoidCallback onOpenPapers;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: <Widget>[
        // Background Curved Shape
        GlassCard(
          margin: const EdgeInsets.only(bottom: 60), // Room for the floating card overlay
          borderRadius: const BorderRadius.vertical(
            top: Radius.zero,
            bottom: Radius.circular(72), // Pronounced bottom curve
          ),
          blurSigma: 18,
          opacity: 0.24,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white24,
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (avatarUrl != null && avatarUrl!.isNotEmpty)
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: NetworkImage(avatarUrl!),
                    backgroundColor: Colors.white,
                  )
                else
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Hi, $userName',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep the momentum going. Practice a set or open a paper in seconds.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        
        // Floating Card
        Positioned(
          bottom: 0,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _FloatingStat(
                  label: 'Streak',
                  value: '$streakDays',
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFFF9800), // Orange
                ),
                _FloatingStat(
                  label: 'Solved',
                  value: '$completedQuestions',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF4CAF50), // Green
                ),
                _FloatingStat(
                  label: 'Saved',
                  value: '$bookmarkedPapers',
                  icon: Icons.bookmark_rounded,
                  color: const Color(0xFF2196F3), // Blue
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionSetMiniCard extends StatelessWidget {
  const _QuestionSetMiniCard({
    required this.set,
    required this.onTap,
  });

  final QuestionSet set;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 8,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: set.accentColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _Badge(label: set.badge, color: set.accentColor),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  set.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  set.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  '${set.grade} • ${set.subject} • ${set.questionCount} questions',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${set.estimatedMinutes} min',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: set.accentColor,
                    ),
              ),
              const SizedBox(height: 34),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaperMiniCard extends StatelessWidget {
  const _PaperMiniCard({
    required this.paper,
    required this.onTap,
  });

  final PastPaper paper;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: AppColors.secondary.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  paper.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${paper.grade} • ${paper.subject} • ${paper.year}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${paper.examType} • ${paper.pages} pages • ${paper.fileSize}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // If the background is essentially very dark, and the color is also dark,
    // we want to guarantee the text is visible.
    final bool isDark = color.computeLuminance() < 0.25;
    final Color textColor = isDark ? Colors.white : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
      ),
    );
  }
}

class _FloatingStat extends StatelessWidget {
  const _FloatingStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _LoadingStack extends StatelessWidget {
  const _LoadingStack();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(2, (int index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            child: Row(
              children: <Widget>[
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: AppColors.border.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        height: 16,
                        width: 160,
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 120,
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

String? _firstName(String? name) {
  if (name == null || name.trim().isEmpty) {
    return null;
  }
  return name.trim().split(RegExp(r'\s+')).first;
}

