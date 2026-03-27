import 'package:acad_mate/app/providers.dart';
import 'package:acad_mate/core/data/academic_catalog.dart';
import 'package:acad_mate/core/theme/app_colors.dart';
import 'package:acad_mate/core/widgets/glass_card.dart';
import 'package:acad_mate/core/widgets/gradient_backdrop.dart';
import 'package:acad_mate/core/widgets/section_header.dart';
import 'package:acad_mate/domain/entities/academic_filter.dart';
import 'package:acad_mate/domain/entities/past_paper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PastPapersScreen extends ConsumerWidget {
  const PastPapersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CatalogFilter filter = ref.watch(catalogFilterProvider);
    final papersAsync = ref.watch(pastPapersProvider);
    final List<String> subjects = AcademicCatalog.subjectsFor(
      grade: filter.grade,
      stream: filter.stream,
    );
    final List<String> grades =
        AcademicCatalog.grades.where((String grade) => grade != 'All').toList();
    final List<String> streams =
        AcademicCatalog.streams.where((String stream) => stream != 'All').toList();

    return GradientBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
        children: <Widget>[
          const SectionHeader(
            title: 'Past papers',
            subtitle: 'PDF access with in-app preview or external open.',
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Use the same filters as practice to narrow the paper list.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
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
                        selected: filter.grade == grade,
                        onSelected: (_) => ref
                            .read(catalogFilterProvider.notifier)
                            .setGrade(grade),
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
                          selected: filter.stream == stream,
                          onSelected: (_) => ref
                              .read(catalogFilterProvider.notifier)
                              .setStream(stream),
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
                        selected: filter.subject == subject,
                        onSelected: (_) => ref
                            .read(catalogFilterProvider.notifier)
                            .setSubject(subject),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemCount: subjects.length,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) =>
                      ref.read(catalogFilterProvider.notifier).setSearch(value),
                  decoration: const InputDecoration(
                    hintText: 'Search papers or exam types',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          papersAsync.when(
            data: (List<PastPaper> papers) {
              if (papers.isEmpty) {
                return const _EmptyResult(
                  title: 'No papers found',
                  subtitle:
                      'Try switching grade, stream, or subject to find more PDFs.',
                );
              }

              return Column(
                children: papers
                    .map(
                      (PastPaper paper) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PaperCard(
                          paper: paper,
                          onTap: () => context.push('/paper/${paper.id}'),
                        ),
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
  });

  final PastPaper paper;
  final VoidCallback onTap;

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
                  ],
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

