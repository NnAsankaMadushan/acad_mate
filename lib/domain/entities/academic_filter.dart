class CatalogFilter {
  const CatalogFilter({
    this.grade = 'All',
    this.subject = 'All',
    this.stream = 'All',
    this.search = '',
  });

  final String grade;
  final String subject;
  final String stream;
  final String search;

  CatalogFilter copyWith({
    String? grade,
    String? subject,
    String? stream,
    String? search,
  }) {
    return CatalogFilter(
      grade: grade ?? this.grade,
      subject: subject ?? this.subject,
      stream: stream ?? this.stream,
      search: search ?? this.search,
    );
  }
}

