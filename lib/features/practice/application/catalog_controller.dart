import 'package:acad_mate/core/data/academic_catalog.dart';
import 'package:acad_mate/domain/entities/academic_filter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CatalogFilterController extends Notifier<CatalogFilter> {
  @override
  CatalogFilter build() => const CatalogFilter();

  void setGrade(String grade) {
    state = state.copyWith(
      grade: grade,
      subject: 'All',
      stream: grade == 'A/L' ? state.stream : 'All',
    );
  }

  void setSubject(String subject) {
    state = state.copyWith(subject: subject);
  }

  void setStream(String stream) {
    state = state.copyWith(
      stream: stream,
      subject: 'All',
    );
  }

  void setSearch(String search) {
    state = state.copyWith(search: search);
  }

  void reset() {
    state = const CatalogFilter();
  }

  List<String> subjectsForCurrentSelection() {
    return AcademicCatalog.subjectsFor(
      grade: state.grade,
      stream: state.stream,
    );
  }
}

