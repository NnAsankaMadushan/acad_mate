import 'package:acad_mate/core/data/academic_catalog.dart';
import 'package:acad_mate/data/mock/mock_academic_repository.dart';
import 'package:acad_mate/domain/entities/academic_filter.dart';
import 'package:acad_mate/domain/entities/past_paper.dart';
import 'package:acad_mate/domain/entities/question_set.dart';
import 'package:acad_mate/domain/repositories/academic_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseAcademicRepository implements AcademicRepository {
  FirebaseAcademicRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _fallbackRepository = MockAcademicRepository();

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final MockAcademicRepository _fallbackRepository;

  @override
  Future<List<QuestionSet>> fetchQuestionSets({
    required CatalogFilter filter,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection('question_sets').get();

      final List<QuestionSet> sets = snapshot.docs.map(_mapQuestionSet).toList();
      final List<QuestionSet> filtered =
          sets.where((QuestionSet set) => set.matches(filter)).toList();
      filtered.sort((QuestionSet a, QuestionSet b) {
        if (a.isFeatured != b.isFeatured) {
          return a.isFeatured ? -1 : 1;
        }
        return b.rating.compareTo(a.rating);
      });
      return filtered;
    } catch (_) {
      return _fallbackRepository.fetchQuestionSets(filter: filter);
    }
  }

  @override
  Future<QuestionSet?> fetchQuestionSetById(String setId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection('question_sets').doc(setId).get();
      if (!snapshot.exists) {
        return null;
      }
      return _mapQuestionSet(snapshot);
    } catch (_) {
      return _fallbackRepository.fetchQuestionSetById(setId);
    }
  }

  @override
  Future<List<PastPaper>> fetchPastPapers({
    required CatalogFilter filter,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection('past_papers').get();
      final List<PastPaper> papers = <PastPaper>[];

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
        final PastPaper paper = await _mapPastPaper(doc);
        if (paper.matches(filter)) {
          papers.add(paper);
        }
      }

      papers.sort((PastPaper a, PastPaper b) => b.year.compareTo(a.year));
      return papers;
    } catch (_) {
      return _fallbackRepository.fetchPastPapers(filter: filter);
    }
  }

  @override
  Future<PastPaper?> fetchPastPaperById(String paperId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection('past_papers').doc(paperId).get();
      if (!snapshot.exists) {
        return null;
      }
      return _mapPastPaper(snapshot);
    } catch (_) {
      return _fallbackRepository.fetchPastPaperById(paperId);
    }
  }

  @override
  Future<void> saveQuestionSet(QuestionSet questionSet) async {
    try {
      await _firestore
          .collection('question_sets')
          .doc(questionSet.id)
          .set(questionSet.toMap());
    } catch (_) {
      await _fallbackRepository.saveQuestionSet(questionSet);
    }
  }

  @override
  Future<void> deleteQuestionSet(String setId) async {
    try {
      await _firestore.collection('question_sets').doc(setId).delete();
    } catch (_) {
      await _fallbackRepository.deleteQuestionSet(setId);
    }
  }

  @override
  Future<void> savePastPaper(PastPaper pastPaper) async {
    try {
      await _firestore
          .collection('past_papers')
          .doc(pastPaper.id)
          .set(pastPaper.toMap());
    } catch (_) {
      await _fallbackRepository.savePastPaper(pastPaper);
    }
  }

  @override
  Future<void> deletePastPaper(String paperId) async {
    try {
      await _firestore.collection('past_papers').doc(paperId).delete();
    } catch (_) {
      await _fallbackRepository.deletePastPaper(paperId);
    }
  }

  QuestionSet _mapQuestionSet(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};
    final Map<String, dynamic> normalized = <String, dynamic>{
      ...data,
      'id': snapshot.id,
      'questions': data['questions'] ?? const <dynamic>[],
    };
    return QuestionSet.fromMap(normalized);
  }

  Future<PastPaper> _mapPastPaper(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};
    String pdfUrl = data['pdfUrl']?.toString() ?? '';
    final String? storagePath = data['storagePath']?.toString();

    if (pdfUrl.isEmpty && storagePath != null && storagePath.isNotEmpty) {
      pdfUrl = await _storage.ref(storagePath).getDownloadURL();
    }

    final Map<String, dynamic> normalized = <String, dynamic>{
      ...data,
      'id': snapshot.id,
      'pdfUrl': _normalizePdfUrl(pdfUrl),
      'storagePath': storagePath,
    };
    return PastPaper.fromMap(normalized);
  }

  String _normalizePdfUrl(String url) {
    if (url.contains('drive.google.com/file/d/')) {
      final RegExp regex = RegExp(r'/file/d/([^/]+)');
      final RegExpMatch? match = regex.firstMatch(url);
      if (match != null) {
        final String id = match.group(1)!;
        return 'https://drive.google.com/uc?export=download&id=$id';
      }
    }

    if (url.contains('drive.google.com/open?id=')) {
      final Uri uri = Uri.parse(url);
      final String? id = uri.queryParameters['id'];
      if (id != null && id.isNotEmpty) {
        return 'https://drive.google.com/uc?export=download&id=$id';
      }
    }

    return url;
  }

  List<String> grades() => AcademicCatalog.grades;

  List<String> streams() => AcademicCatalog.streams;

  List<String> subjectsFor({
    required String grade,
    required String stream,
  }) {
    return AcademicCatalog.subjectsFor(grade: grade, stream: stream);
  }
}

