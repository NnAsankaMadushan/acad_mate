import 'package:acad_mate/app/providers.dart';
import 'package:acad_mate/core/data/academic_catalog.dart';
import 'package:acad_mate/core/theme/app_colors.dart';
import 'package:acad_mate/core/widgets/glass_card.dart';
import 'package:acad_mate/core/widgets/gradient_backdrop.dart';
import 'package:acad_mate/core/widgets/section_header.dart';
import 'package:acad_mate/domain/entities/academic_filter.dart';
import 'package:acad_mate/domain/entities/app_user.dart';
import 'package:acad_mate/domain/entities/question_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CatalogFilter filter = ref.watch(catalogFilterProvider);
    final List<String> subjects = AcademicCatalog.subjectsFor(
      grade: filter.grade,
      stream: filter.stream,
    );
    final questionSetsAsync = ref.watch(questionSetsProvider);
    final List<String> grades = AcademicCatalog.grades;
    final List<String> streams =
        AcademicCatalog.streams.where((String stream) => stream != 'All').toList();

    return GradientBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
        children: <Widget>[
          const SectionHeader(
            title: 'Practice by category',
            subtitle: 'Grade, subject, and stream filters stay in sync.',
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  controller: _searchController,
                  onChanged: (value) => ref
                      .read(catalogFilterProvider.notifier)
                      .setSearch(value),
                  decoration: const InputDecoration(
                    hintText: 'Search by topic, subject, or stream',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Grade',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (BuildContext context, int index) {
                      final String grade = grades[index];
                      return ChoiceChip(
                        label: Text(grade),
                        showCheckmark: false,
                        selected: filter.grade == grade,
                        onSelected: (_) {
                          ref.read(catalogFilterProvider.notifier).setGrade(grade);
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemCount: grades.length,
                  ),
                ),
                const SizedBox(height: 16),
                if (filter.grade == 'A/L') ...<Widget>[
                  Text(
                    'Stream',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext context, int index) {
                        final String stream = streams[index];
                        return ChoiceChip(
                          label: Text(stream),
                          showCheckmark: false,
                          selected: filter.stream == stream,
                          onSelected: (_) {
                            ref
                                .read(catalogFilterProvider.notifier)
                                .setStream(stream);
                          },
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemCount: streams.length,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Subject',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (BuildContext context, int index) {
                      final String subject = subjects[index];
                      return ChoiceChip(
                        label: Text(subject),
                        showCheckmark: false,
                        selected: filter.subject == subject,
                        onSelected: (_) {
                          ref
                              .read(catalogFilterProvider.notifier)
                              .setSubject(subject);
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemCount: subjects.length,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${questionSetsAsync.maybeWhen(data: (sets) => sets.length, orElse: () => 0)} sets available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(catalogFilterProvider.notifier).reset();
                        _searchController.clear();
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          questionSetsAsync.when(
            data: (List<QuestionSet> sets) {
              if (sets.isEmpty) {
                return const _EmptyResult(
                  title: 'No sets found',
                  subtitle: 'Try a different subject, stream, or search term.',
                );
              }

              final userAsync = ref.watch(authStateProvider);
              final user = userAsync.maybeWhen(data: (u) => u, orElse: () => null);

              return Column(
                children: sets.map((QuestionSet set) {
                  QuizResult? bestResult;
                  if (user != null) {
                    final results = user.quizResults.where((r) => r.quizId == set.id).toList();
                    if (results.isNotEmpty) {
                      results.sort((a, b) => (b.score / b.total).compareTo(a.score / a.total));
                      bestResult = results.first;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _QuestionSetCard(
                      set: set,
                      bestResult: bestResult,
                      onTap: () => context.push('/quiz/${set.id}'),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const _LoadingCards(),
            error: (Object error, StackTrace stackTrace) => _EmptyResult(
              title: 'Could not load practice sets',
              subtitle: error.toString(),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionSetCard extends StatelessWidget {
  const _QuestionSetCard({
    required this.set,
    required this.bestResult,
    required this.onTap,
  });

  final QuestionSet set;
  final QuizResult? bestResult;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double? accuracy = bestResult != null ? (bestResult!.score / bestResult!.total) : null;
    final bool attempted = bestResult != null;
    final String? bestScoreText = attempted ? '${bestResult!.score}/${bestResult!.total} marks' : null;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: set.accentColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  set.badge,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: set.accentColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (accuracy != null) ...<Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        '${(accuracy * 100).round()}% correct',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],
              _RatingPill(value: set.rating),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            set.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            set.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _MetaChip(text: set.grade, icon: Icons.school_rounded),
              _MetaChip(text: set.subject, icon: Icons.menu_book_rounded),
              _MetaChip(text: set.stream, icon: Icons.layers_rounded),
              _MetaChip(
                text: '${set.questionCount} questions',
                icon: Icons.quiz_rounded,
              ),
              _MetaChip(
                text: '${set.estimatedMinutes} min',
                icon: Icons.timer_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              FilledButton(
                onPressed: onTap,
                child: Text(attempted ? 'Try again' : 'Start now'),
              ),
              const SizedBox(width: 12),
              Text(
                set.topic,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          if (attempted) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Done before',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 12),
                Text(
                  bestScoreText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value.toStringAsFixed(1),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
            ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({
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
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _LoadingCards extends StatelessWidget {
  const _LoadingCards();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(2, (int index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 14,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.border.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 22,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.border.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 14,
                  width: 220,
                  decoration: BoxDecoration(
                    color: AppColors.border.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
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

