class Question {
  const Question({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.hint,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String? hint;

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id']?.toString() ?? '',
      prompt: map['prompt']?.toString() ?? '',
      options: (map['options'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic option) => option.toString())
          .toList(),
      correctIndex: (map['correctIndex'] as num?)?.toInt() ?? 0,
      explanation: map['explanation']?.toString() ?? '',
      hint: map['hint']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'prompt': prompt,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'hint': hint,
    };
  }
}

