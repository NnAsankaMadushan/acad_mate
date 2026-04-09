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

class _PracticeScreenState extends ConsumerState<PracticeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Consumer(
          builder: (BuildContext context, WidgetRef sheetRef, Widget? child) {
            final CatalogFilter filter = sheetRef.watch(catalogFilterProvider);
            final List<String> subjects = AcademicCatalog.subjectsFor(
              grade: filter.grade,
              stream: filter.stream,
            );
            final List<String> grades = AcademicCatalog.grades;
            final List<String> streams =
                AcademicCatalog.streams.where((String stream) => stream != 'All').toList();

            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          'Filters',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            sheetRef.read(catalogFilterProvider.notifier).reset();
                            _searchController.clear();
                            Navigator.pop(context);
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Grade',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: grades.map((String grade) {
                        return ChoiceChip(
                          label: Text(grade),
                          showCheckmark: false,
                          selected: filter.grade == grade,
                          onSelected: (_) {
                            sheetRef.read(catalogFilterProvider.notifier).setGrade(grade);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    if (filter.grade == 'A/L') ...<Widget>[
                      Text(
                        'Stream',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: streams.map((String stream) {
                          return ChoiceChip(
                            label: Text(stream),
                            showCheckmark: false,
                            selected: filter.stream == stream,
                            onSelected: (_) {
                              sheetRef
                                  .read(catalogFilterProvider.notifier)
                                  .setStream(stream);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      'Subject',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: subjects.map((String subject) {
                        return ChoiceChip(
                          label: Text(subject),
                          showCheckmark: false,
                          selected: filter.subject == subject,
                          onSelected: (_) {
                            sheetRef
                                .read(catalogFilterProvider.notifier)
                                .setSubject(subject);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionSetsAsync = ref.watch(questionSetsProvider);

    return GradientBackdrop(
      child: Column(
        children: <Widget>[
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: <Widget>[
                const SectionHeader(
                  title: 'Practice by category',
                  subtitle: 'Use filters to narrow down practice sets.',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 0.7,
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: EdgeInsets.zero,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.text,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: const <Widget>[
                      Tab(text: 'All'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => ref
                                  .read(catalogFilterProvider.notifier)
                                  .setSearch(value),
                              decoration: const InputDecoration(
                                hintText: 'Search by topic, subject, or stream',
                                prefixIcon: Icon(Icons.search_rounded),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _showFilterBottomSheet,
                            icon: const Icon(Icons.filter_list_rounded),
                            tooltip: 'Filters',
                          ),
                        ],
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final filter = ref.watch(catalogFilterProvider);
                          final List<String> activeFilters = [];
                          if (filter.grade != 'All') activeFilters.add(filter.grade);
                          if (filter.grade == 'A/L' && filter.stream != 'All') activeFilters.add(filter.stream);
                          if (filter.subject != 'All') activeFilters.add(filter.subject);
                          
                          if (activeFilters.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: activeFilters
                                  .map((f) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                        ),
                                        child: Text(
                                          f,
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          );
                        },
                      ),

                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _buildQuestionSetsList(questionSetsAsync, filter: _filterAllSets),
                _buildQuestionSetsList(questionSetsAsync, filter: _filterCompletedSets),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<QuestionSet> _filterAllSets(List<QuestionSet> sets, AppUser? user) {
    if (user == null) return sets;

    final Set<String> perfectQuizIds = user.quizResults
        .where((result) => result.isPerfect)
        .map((result) => result.quizId)
        .toSet();

    return sets.where((set) => !perfectQuizIds.contains(set.id)).toList();
  }

  List<QuestionSet> _filterCompletedSets(List<QuestionSet> sets, AppUser? user) {
    if (user == null) return [];
    
    final Set<String> completedQuizIds = user.quizResults
        .where((result) => result.isPerfect)
        .map((result) => result.quizId)
        .toSet();
    
    return sets.where((set) => completedQuizIds.contains(set.id)).toList();
  }

  Widget _buildQuestionSetsList(
    AsyncValue<List<QuestionSet>> questionSetsAsync, {
    required List<QuestionSet> Function(List<QuestionSet>, AppUser?) filter,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
      children: <Widget>[
        questionSetsAsync.when(
          data: (List<QuestionSet> sets) {
            final userAsync = ref.watch(authStateProvider);
            final user = userAsync.maybeWhen(data: (u) => u, orElse: () => null);
            final filteredSets = filter(sets, user);

            if (filteredSets.isEmpty) {
              return const _EmptyResult(
                title: 'No sets found',
                subtitle: 'Try a different subject, stream, or search term.',
              );
            }

            return Column(
              children: filteredSets.map((QuestionSet set) {
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

