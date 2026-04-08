import 'package:acad_mate/domain/entities/academic_filter.dart';
import 'package:acad_mate/domain/entities/past_paper.dart';
import 'package:acad_mate/domain/entities/question_set.dart';

abstract class AcademicRepository {
  Future<List<QuestionSet>> fetchQuestionSets({
    required CatalogFilter filter,
  });

  Future<QuestionSet?> fetchQuestionSetById(String setId);

  Future<List<PastPaper>> fetchPastPapers({
    required CatalogFilter filter,
  });

  Future<PastPaper?> fetchPastPaperById(String paperId);

  Future<void> saveQuestionSet(QuestionSet questionSet);

  Future<void> deleteQuestionSet(String setId);

  Future<void> savePastPaper(PastPaper pastPaper);

  Future<void> deletePastPaper(String paperId);
}

