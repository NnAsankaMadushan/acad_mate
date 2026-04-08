import 'package:acad_mate/app/providers.dart';
import 'package:acad_mate/core/data/academic_catalog.dart';
import 'package:acad_mate/features/papers/application/paper_favorites_controller.dart';
import 'package:acad_mate/core/theme/app_colors.dart';
import 'package:acad_mate/core/widgets/glass_card.dart';
import 'package:acad_mate/core/widgets/gradient_backdrop.dart';
import 'package:acad_mate/core/widgets/section_header.dart';
import 'package:acad_mate/domain/entities/academic_filter.dart';
import 'package:acad_mate/domain/entities/past_paper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PastPapersScreen extends ConsumerStatefulWidget {
  const PastPapersScreen({super.key});

  @override
  ConsumerState<PastPapersScreen> createState() => _PastPapersScreenState();
}

class _PastPapersScreenState extends ConsumerState<PastPapersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(pastPaperViewModeProvider.notifier).setMode(
          _tabController.index == 0
              ? PastPaperViewMode.all
              : PastPaperViewMode.favorites,
        );
      }
    });
  }

  @override
  void dispose() {
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
    final papersAsync = ref.watch(pastPapersProvider);
    final AsyncValue<PaperFavoritesState> favoritesAsync =
        ref.watch(paperFavoritesProvider);
    final PastPaperViewMode viewMode = ref.watch(pastPaperViewModeProvider);
    
    if (_tabController.index != (viewMode == PastPaperViewMode.all ? 0 : 1)) {
        _tabController.index = viewMode == PastPaperViewMode.all ? 0 : 1;
    }

    return GradientBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
        children: <Widget>[
          const SectionHeader(
            title: 'Past papers',
            subtitle: 'Use filters to narrow down the paper list.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
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
                Tab(text: 'All papers'),
                Tab(text: 'Saved'),
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
                        onChanged: (value) =>
                            ref.read(catalogFilterProvider.notifier).setSearch(value),
                        decoration: const InputDecoration(
                          hintText: 'Search papers or exam types',
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
          const SizedBox(height: 18),
          favoritesAsync.when(
            data: (PaperFavoritesState favorites) {
              return papersAsync.when(
                data: (List<PastPaper> papers) {
                  final Set<String> favoriteIds = favorites.favoritePaperIds;
                  final List<PastPaper> displayPapers = viewMode == PastPaperViewMode.favorites
                      ? papers.where((PastPaper paper) => favoriteIds.contains(paper.id)).toList()
                      : papers;

                  if (displayPapers.isEmpty) {
                    return _EmptyResult(
                      title: viewMode == PastPaperViewMode.favorites
                          ? 'No saved papers yet'
                          : 'No papers found',
                      subtitle: viewMode == PastPaperViewMode.favorites
                          ? 'Tap the bookmark icon on a paper to save it for later.'
                          : 'Try switching grade, stream, or subject to find more PDFs.',
                    );
                  }

                  final Map<String, List<PastPaper>> groupedPapers = <String, List<PastPaper>>{};
                  for (final PastPaper paper in displayPapers) {
                    groupedPapers.putIfAbsent(paper.grade, () => <PastPaper>[]).add(paper);
                  }

                  final List<String> gradeOrder = AcademicCatalog.grades
                      .where((String grade) => grade != 'All')
                      .toList();

                  final List<MapEntry<String, List<PastPaper>>> sortedGroups = groupedPapers.entries.toList()
                    ..sort((MapEntry<String, List<PastPaper>> a, MapEntry<String, List<PastPaper>> b) {
                      return gradeOrder.indexOf(a.key).compareTo(gradeOrder.indexOf(b.key));
                    });

                  return Column(
                    children: sortedGroups
                        .map(
                          (MapEntry<String, List<PastPaper>> group) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  group.key,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                              ...group.value.map(
                                (PastPaper paper) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _PaperCard(
                                    paper: paper,
                                    isFavorite: favoriteIds.contains(paper.id),
                                    localPath: favorites.localPath(paper.id),
                                    onToggleFavorite: () => ref
                                        .read(paperFavoritesProvider.notifier)
                                        .toggleFavorite(paper.id),
                                    onTap: () => context.push('/paper/${paper.id}'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const _LoadingCards(),
                error: (Object error, StackTrace stackTrace) => _EmptyResult(
                  title: 'Could not load past papers',
                  subtitle: error.toString(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace stackTrace) => _EmptyResult(
              title: 'Could not load saved papers',
              subtitle: error.toString(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  const _PaperCard({
    required this.paper,
    required this.onTap,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.localPath,
  });

  final PastPaper paper;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final String? localPath;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
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
                const SizedBox(height: 6),
                Text(
                  '${paper.grade} • ${paper.subject} • ${paper.year}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _MetaChip(text: paper.examType),
                    _MetaChip(text: '${paper.pages} pages'),
                    _MetaChip(text: paper.fileSize),
                    if (localPath != null)
                      const _MetaChip(text: 'Saved locally'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: <Widget>[
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  color: isFavorite ? AppColors.primary : AppColors.textMuted,
                ),
                onPressed: onToggleFavorite,
              ),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
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
            child: Row(
              children: <Widget>[
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.border.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 12,
                        width: 160,
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

