import 'package:acad_mate/core/theme/app_colors.dart';
import 'package:acad_mate/domain/entities/academic_filter.dart';
import 'package:acad_mate/domain/entities/question.dart';
import 'package:flutter/material.dart';

class QuestionSet {
  const QuestionSet({
    required this.id,
    required this.title,
    required this.grade,
    required this.subject,
    required this.stream,
    required this.topic,
    required this.description,
    required this.estimatedMinutes,
    required this.rating,
    required this.badge,
    required this.accentColorValue,
    required this.questions,
    this.isFeatured = false,
  });

  final String id;
  final String title;
  final String grade;
  final String subject;
  final String stream;
  final String topic;
  final String description;
  final int estimatedMinutes;
  final double rating;
  final String badge;
  final int accentColorValue;
  final List<Question> questions;
  final bool isFeatured;

  int get questionCount => questions.length;

  Color get accentColor => Color(accentColorValue).withValues(alpha: 1.0);

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
        topic.toLowerCase().contains(search) ||
        description.toLowerCase().contains(search);

    return gradeMatch && subjectMatch && streamMatch && searchMatch;
  }

  factory QuestionSet.fromMap(Map<String, dynamic> map) {
    return QuestionSet(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      grade: map['grade']?.toString() ?? 'All',
      subject: map['subject']?.toString() ?? 'All',
      stream: map['stream']?.toString() ?? 'All',
      topic: map['topic']?.toString() ?? 'General',
      description: map['description']?.toString() ?? '',
      estimatedMinutes: (map['estimatedMinutes'] as num?)?.toInt() ?? 10,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      badge: map['badge']?.toString() ?? 'Practice',
      accentColorValue: (map['accentColorValue'] as num?)?.toInt() ??
          AppColors.primary.toARGB32(),
      isFeatured: map['isFeatured'] as bool? ?? false,
      questions: (map['questions'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) =>
              Question.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'grade': grade,
      'subject': subject,
      'stream': stream,
      'topic': topic,
      'description': description,
      'estimatedMinutes': estimatedMinutes,
      'rating': rating,
      'badge': badge,
      'accentColorValue': accentColorValue,
      'isFeatured': isFeatured,
      'questions': questions.map((Question question) => question.toMap()).toList(),
    };
  }
}

