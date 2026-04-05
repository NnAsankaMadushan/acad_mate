import 'package:acad_mate/core/config/app_config.dart';
import 'package:acad_mate/data/backend/backend_academic_repository.dart';
import 'package:acad_mate/data/backend/backend_profile_client.dart';
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
import 'package:acad_mate/features/practice/application/catalog_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final backendProfileClientProvider = Provider<BackendProfileClient?>((ref) {
  if (!AppConfig.useMongoBackend) {
    return null;
  }

  final BackendProfileClient client = BackendProfileClient(
    baseUrl: AppConfig.mongoBackendBaseUrl,
  );
  ref.onDispose(client.close);
  return client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.firebaseReady) {
    return FirebaseAuthRepository(
      backendProfileClient: ref.watch(backendProfileClientProvider),
    );
  }
  return MockAuthRepository();
});

final academicRepositoryProvider = Provider<AcademicRepository>((ref) {
  if (AppConfig.useMongoBackend) {
    return BackendAcademicRepository(
      baseUrl: AppConfig.mongoBackendBaseUrl,
    );
  }

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

