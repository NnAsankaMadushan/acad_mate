import 'package:acad_mate/core/config/app_config.dart';
import 'package:acad_mate/data/firebase/firebase_academic_repository.dart';
import 'package:acad_mate/data/firebase/firebase_auth_repository.dart';
import 'package:acad_mate/data/mock/mock_academic_repository.dart';
import 'package:acad_mate/data/mock/mock_auth_repository.dart';
import 'package:acad_mate/domain/entities/academic_filter.dart';
import 'package:acad_mate/domain/entities/app_user.dart';
import 'package:acad_mate/domain/entities/past_paper.dart';
import 'package:acad_mate/domain/entities/question_set.dart';
import 'package:acad_mate/domain/repositories/academic_repository.dart';
import 'package:acad_mate/domain/repositories/auth_repository.dart';
import 'package:acad_mate/data/firebase/firebase_task_repository.dart';
import 'package:acad_mate/domain/entities/task.dart';
import 'package:acad_mate/domain/repositories/task_repository.dart';
import 'package:acad_mate/features/papers/application/paper_favorites_controller.dart';
import 'package:acad_mate/features/practice/application/catalog_controller.dart';
import 'package:acad_mate/features/tasks/application/tasks_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.firebaseReady) {
    return FirebaseAuthRepository();
  }
  return MockAuthRepository();
});

final academicRepositoryProvider = Provider<AcademicRepository>((ref) {
  if (AppConfig.firebaseReady) {
    return FirebaseAcademicRepository();
  }
  return MockAcademicRepository();
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final catalogFilterProvider =
    NotifierProvider<CatalogFilterController, CatalogFilter>(
  CatalogFilterController.new,
);

final questionSetsProvider = FutureProvider<List<QuestionSet>>((ref) {
  final repository = ref.watch(academicRepositoryProvider);
  final filter = ref.watch(catalogFilterProvider);
  return repository.fetchQuestionSets(filter: filter);
});

final questionSetProvider =
    FutureProvider.family<QuestionSet?, String>((ref, setId) {
  return ref.watch(academicRepositoryProvider).fetchQuestionSetById(setId);
});

final pastPapersProvider = FutureProvider<List<PastPaper>>((ref) {
  final repository = ref.watch(academicRepositoryProvider);
  final filter = ref.watch(catalogFilterProvider);
  return repository.fetchPastPapers(filter: filter);
});

final pastPaperProvider =
    FutureProvider.family<PastPaper?, String>((ref, paperId) {
  return ref.watch(academicRepositoryProvider).fetchPastPaperById(paperId);
});

final paperFavoritesProvider =
    AsyncNotifierProvider<PaperFavoritesController, PaperFavoritesState>(
  PaperFavoritesController.new,
);

final pastPaperViewModeProvider =
    NotifierProvider<PastPaperViewModeNotifier, PastPaperViewMode>(
  PastPaperViewModeNotifier.new,
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (_) => FirebaseTaskRepository(),
);

final tasksProvider =
    AsyncNotifierProvider<TasksController, List<Task>>(TasksController.new);

class PastPaperViewModeNotifier extends Notifier<PastPaperViewMode> {
  @override
  PastPaperViewMode build() => PastPaperViewMode.all;

  void setMode(PastPaperViewMode mode) => state = mode;
}
