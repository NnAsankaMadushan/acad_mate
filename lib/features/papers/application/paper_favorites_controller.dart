import 'dart:convert';
import 'dart:io';

import 'package:acad_mate/domain/entities/past_paper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PastPaperViewMode {
  all,
  favorites,
}

class PaperFavoritesState {
  const PaperFavoritesState({
    this.favoritePaperIds = const <String>{},
    this.downloadedPaths = const <String, String>{},
  });

  final Set<String> favoritePaperIds;
  final Map<String, String> downloadedPaths;

  bool isFavorite(String paperId) => favoritePaperIds.contains(paperId);

  String? localPath(String paperId) => downloadedPaths[paperId];

  PaperFavoritesState copyWith({
    Set<String>? favoritePaperIds,
    Map<String, String>? downloadedPaths,
  }) {
    return PaperFavoritesState(
      favoritePaperIds: favoritePaperIds ?? this.favoritePaperIds,
      downloadedPaths: downloadedPaths ?? this.downloadedPaths,
    );
  }
}

class PaperFavoritesController extends AsyncNotifier<PaperFavoritesState> {
  static const String _favoritePapersKey = 'favoritePaperIds';
  static const String _downloadedPathsKey = 'favoritePaperDownloadedPaths';

  late final SharedPreferences _preferences;

  @override
  Future<PaperFavoritesState> build() async {
    _preferences = await SharedPreferences.getInstance();

    final Set<String> favorites = _preferences
            .getStringList(_favoritePapersKey)
            ?.toSet() ??
        <String>{};

    final String? downloadedPathsJson =
        _preferences.getString(_downloadedPathsKey);
    final Map<String, String> downloadedPaths = <String, String>{};

    if (downloadedPathsJson != null) {
      final Map<String, dynamic> parsed =
          jsonDecode(downloadedPathsJson) as Map<String, dynamic>;
      for (final MapEntry<String, dynamic> entry in parsed.entries) {
        downloadedPaths[entry.key] = entry.value.toString();
      }
    }

    return PaperFavoritesState(
      favoritePaperIds: favorites,
      downloadedPaths: downloadedPaths,
    );
  }

  Future<void> toggleFavorite(String paperId) async {
    final PaperFavoritesState current = state.value ?? const PaperFavoritesState();
    final Set<String> updatedFavorites = Set<String>.from(current.favoritePaperIds);

    if (updatedFavorites.contains(paperId)) {
      updatedFavorites.remove(paperId);
    } else {
      updatedFavorites.add(paperId);
    }

    await _preferences.setStringList(_favoritePapersKey, updatedFavorites.toList());
    state = AsyncData(current.copyWith(favoritePaperIds: updatedFavorites));
  }

  Future<String> downloadPastPaper(PastPaper paper) async {
    final http.Response response = await http.get(Uri.parse(paper.pdfUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to download paper.');
    }

    final Directory directory = await getApplicationDocumentsDirectory();
    final Directory paperFolder = Directory('${directory.path}/past_papers');
    await paperFolder.create(recursive: true);

    final File file = File('${paperFolder.path}/${paper.id}.pdf');
    await file.writeAsBytes(response.bodyBytes);

    final PaperFavoritesState current = state.value ?? const PaperFavoritesState();
    final Map<String, String> updatedPaths = Map<String, String>.from(current.downloadedPaths);
    updatedPaths[paper.id] = file.path;

    await _preferences.setString(_downloadedPathsKey, jsonEncode(updatedPaths));
    state = AsyncData(current.copyWith(downloadedPaths: updatedPaths));

    return file.path;
  }
}
