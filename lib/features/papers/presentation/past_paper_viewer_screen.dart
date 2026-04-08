import 'package:acad_mate/app/providers.dart';
import 'package:acad_mate/features/papers/application/paper_favorites_controller.dart';
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
    final AsyncValue<PaperFavoritesState> favoritesAsync =
        ref.watch(paperFavoritesProvider);
    final paperAsync = ref.watch(pastPaperProvider(paperId));

    Future<void> _openLocalFile(String path) async {
      final Uri fileUri = Uri.file(path);
      if (await canLaunchUrl(fileUri)) {
        await launchUrl(fileUri);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          paperAsync.value?.title ?? 'Past Paper',
          overflow: TextOverflow.ellipsis,
        ),
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

            final bool isFavorite = favoritesAsync.maybeWhen(
                  data: (PaperFavoritesState favorites) =>
                      favorites.isFavorite(paper.id),
                  orElse: () => false,
                ) ||
                false;
            final String? localPath = favoritesAsync.maybeWhen(
                  data: (PaperFavoritesState favorites) =>
                      favorites.localPath(paper.id),
                  orElse: () => null,
                );

            return Column(
              children: <Widget>[
                const SizedBox(height: 8),
                if (favoritesAsync is AsyncData<PaperFavoritesState>)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        IconButton(
                          icon: Icon(
                            isFavorite
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: isFavorite
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          tooltip: isFavorite ? 'Remove saved paper' : 'Save paper',
                          onPressed: () {
                            ref
                                .read(paperFavoritesProvider.notifier)
                                .toggleFavorite(paper.id);
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
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

