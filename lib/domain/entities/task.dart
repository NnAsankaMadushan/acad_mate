import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high }

class Task {
  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.isDone = false,
    this.priority = TaskPriority.medium,
    this.dueDate,
  });

  final String id;
  final String title;
  final String description;
  final bool isDone;
  final TaskPriority priority;
  final DateTime? dueDate;

  Color get priorityColor => switch (priority) {
        TaskPriority.high => const Color(0xFFE5484D),
        TaskPriority.medium => const Color(0xFFF59E0B),
        TaskPriority.low => const Color(0xFF12B76A),
      };

  String get priorityLabel => switch (priority) {
        TaskPriority.high => 'High',
        TaskPriority.medium => 'Medium',
        TaskPriority.low => 'Low',
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'title': title,
        'description': description,
        'isDone': isDone,
        'priority': priority.name,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      };

  factory Task.fromMap(String id, Map<String, dynamic> map) {
    final dynamic dueDateRaw = map['dueDate'];
    return Task(
      id: id,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      isDone: map['isDone'] as bool? ?? false,
      priority: TaskPriority.values.firstWhere(
        (TaskPriority p) => p.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      dueDate: dueDateRaw is Timestamp ? dueDateRaw.toDate() : null,
    );
  }

  Task copyWith({
    String? title,
    String? description,
    bool? isDone,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    );
  }
}
