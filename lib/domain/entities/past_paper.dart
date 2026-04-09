import 'package:acad_mate/domain/entities/academic_filter.dart';

class PastPaper {
  const PastPaper({
    required this.id,
    required this.title,
    required this.grade,
    required this.subject,
    required this.stream,
    required this.year,
    required this.examType,
    required this.pdfUrl,
    this.answerPdfUrl = '',
    this.storagePath,
    this.pages = 0,
    this.fileSize = '',
  });

  final String id;
  final String title;
  final String grade;
  final String subject;
  final String stream;
  final int year;
  final String examType;
  final String pdfUrl;
  final String answerPdfUrl;
  final String? storagePath;
  final int pages;
  final String fileSize;

  bool matches(CatalogFilter filter) {
    final String search = filter.search.trim().toLowerCase();
    final bool gradeMatch = filter.grade == 'All' || grade == filter.grade;
    final bool subjectMatch =
        filter.subject == 'All' || subject == filter.subject;
    final bool streamMatch = filter.stream == 'All' || stream == filter.stream;
    final bool searchMatch = search.isEmpty ||
        title.toLowerCase().contains(search) ||
        subject.toLowerCase().contains(search) ||
        stream.toLowerCase().contains(search) ||
        examType.toLowerCase().contains(search);

    return gradeMatch && subjectMatch && streamMatch && searchMatch;
  }

  factory PastPaper.fromMap(Map<String, dynamic> map) {
    return PastPaper(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      grade: map['grade']?.toString() ?? 'All',
      subject: map['subject']?.toString() ?? 'All',
      stream: map['stream']?.toString() ?? 'All',
      year: (map['year'] as num?)?.toInt() ?? 2024,
      examType: map['examType']?.toString() ?? 'Paper',
      pdfUrl: map['pdfUrl']?.toString() ?? '',
      answerPdfUrl: map['answerPdfUrl']?.toString() ?? '',
      storagePath: map['storagePath']?.toString(),
      pages: (map['pages'] as num?)?.toInt() ?? 0,
      fileSize: map['fileSize']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'grade': grade,
      'subject': subject,
      'stream': stream,
      'year': year,
      'examType': examType,
      'pdfUrl': pdfUrl,
      'answerPdfUrl': answerPdfUrl,
      'storagePath': storagePath,
      'pages': pages,
      'fileSize': fileSize,
    };
  }
}

