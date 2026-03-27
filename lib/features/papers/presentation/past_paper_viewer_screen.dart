import 'package:acad_mate/app/providers.dart';
import 'package:acad_mate/core/theme/app_colors.dart';
import 'package:acad_mate/core/widgets/glass_card.dart';
import 'package:acad_mate/core/widgets/gradient_backdrop.dart';
import 'package:acad_mate/domain/entities/past_paper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class PastPaperViewerScreen extends ConsumerWidget {
  const PastPaperViewerScreen({
    super.key,
    required this.paperId,
  });

  final String paperId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paperAsync = ref.watch(pastPaperProvider(paperId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Paper'),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              final PastPaper? paper =
                  await ref.read(pastPaperProvider(paperId).future);
              if (paper != null && paper.pdfUrl.isNotEmpty) {
                await launchUrl(
                  Uri.parse(paper.pdfUrl),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: GradientBackdrop(
        child: paperAsync.when(
          data: (PastPaper? paper) {
            if (paper == null || paper.pdfUrl.isEmpty) {
              return const Center(
                child: GlassCard(
                  child: Text('Past paper not found.'),
                ),
              );
            }

            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${paper.examType} • ${paper.year} • ${paper.pages} pages',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: SfPdfViewer.network(
                        paper.pdfUrl,
                        canShowScrollHead: true,
                        canShowPaginationDialog: true,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (Object error, StackTrace stackTrace) => Center(
            child: GlassCard(
              child: Text(error.toString()),
            ),
          ),
        ),
      ),
    );
  }
}

