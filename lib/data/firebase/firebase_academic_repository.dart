import 'package:acad_mate/core/data/academic_catalog.dart';
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
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Future<List<QuestionSet>> fetchQuestionSets({
    required CatalogFilter filter,
  }) async {
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
  }

  @override
  Future<QuestionSet?> fetchQuestionSetById(String setId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _firestore.collection('question_sets').doc(setId).get();
    if (!snapshot.exists) {
      return null;
    }
    return _mapQuestionSet(snapshot);
  }

  @override
  Future<List<PastPaper>> fetchPastPapers({
    required CatalogFilter filter,
  }) async {
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
  }

  @override
  Future<PastPaper?> fetchPastPaperById(String paperId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _firestore.collection('past_papers').doc(paperId).get();
    if (!snapshot.exists) {
      return null;
    }
    return _mapPastPaper(snapshot);
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
      'pdfUrl': pdfUrl,
      'storagePath': storagePath,
    };
    return PastPaper.fromMap(normalized);
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

