import 'package:acad_mate/domain/entities/academic_filter.dart';
import 'package:acad_mate/domain/entities/past_paper.dart';
import 'package:acad_mate/domain/entities/question.dart';
import 'package:acad_mate/domain/entities/question_set.dart';
import 'package:acad_mate/domain/repositories/academic_repository.dart';

class MockAcademicRepository implements AcademicRepository {
  MockAcademicRepository()
      : _questionSets = _sampleQuestionSets,
        _pastPapers = _samplePastPapers;

  final List<QuestionSet> _questionSets;
  final List<PastPaper> _pastPapers;

  @override
  Future<List<QuestionSet>> fetchQuestionSets({
    required CatalogFilter filter,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 550));

    final List<QuestionSet> results =
        _questionSets.where((QuestionSet set) => set.matches(filter)).toList();
    results.sort((QuestionSet a, QuestionSet b) {
      if (a.isFeatured != b.isFeatured) {
        return a.isFeatured ? -1 : 1;
      }
      return b.rating.compareTo(a.rating);
    });
    return results;
  }

  @override
  Future<QuestionSet?> fetchQuestionSetById(String setId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (final QuestionSet set in _questionSets) {
      if (set.id == setId) {
        return set;
      }
    }
    return null;
  }

  @override
  Future<List<PastPaper>> fetchPastPapers({
    required CatalogFilter filter,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 550));
    final List<PastPaper> results =
        _pastPapers.where((PastPaper paper) => paper.matches(filter)).toList();
    results.sort((PastPaper a, PastPaper b) => b.year.compareTo(a.year));
    return results;
  }

  @override
  Future<PastPaper?> fetchPastPaperById(String paperId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (final PastPaper paper in _pastPapers) {
      if (paper.id == paperId) {
        return paper;
      }
    }
    return null;
  }

  @override
  Future<void> saveQuestionSet(QuestionSet questionSet) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final int index = _questionSets.indexWhere((QuestionSet set) => set.id == questionSet.id);
    if (index >= 0) {
      _questionSets[index] = questionSet;
      return;
    }
    _questionSets.add(questionSet);
  }

  @override
  Future<void> deleteQuestionSet(String setId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _questionSets.removeWhere((QuestionSet set) => set.id == setId);
  }

  @override
  Future<void> savePastPaper(PastPaper pastPaper) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final int index = _pastPapers.indexWhere((PastPaper paper) => paper.id == pastPaper.id);
    if (index >= 0) {
      _pastPapers[index] = pastPaper;
      return;
    }
    _pastPapers.add(pastPaper);
  }

  @override
  Future<void> deletePastPaper(String paperId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _pastPapers.removeWhere((PastPaper paper) => paper.id == paperId);
  }
}

const String _samplePdf =
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';

final List<QuestionSet> _sampleQuestionSets = _generateSampleQuestionSets();

List<QuestionSet> _generateSampleQuestionSets() {
  const List<String> primaryGrades = <String>[
    'Grade 1',
    'Grade 2',
    'Grade 3',
    'Grade 4',
    'Grade 5',
    'Grade 6',
    'Grade 7',
    'Grade 8',
    'Grade 9',
  ];

  const List<String> primarySubjects = <String>[
    'Mathematics',
    'Science',
    'English',
    'Sinhala',
    'Tamil',
    'Religion',
    'Environmental Studies',
  ];

  const List<String> olSubjects = <String>[
    'Mathematics',
    'Science',
    'English',
    'History',
    'Geography',
    'ICT',
  ];

  const Map<String, List<String>> alStreams = <String, List<String>>{
    'Science': ['Physics', 'Chemistry', 'Biology', 'Combined Maths', 'ICT'],
    'Commerce': ['Accounting', 'Business Studies', 'Economics', 'Information Systems', 'ICT'],
    'Arts': ['History', 'Geography', 'Political Science', 'Logic', 'Sinhala'],
    'Technology': ['Science for Technology', 'Engineering Technology', 'ICT', 'Agriculture'],
  };

  final Map<String, Map<String, String>> subjectPracticeData = <String, Map<String, String>>{
    'Mathematics': {
      'topic': 'Numbers & shapes',
      'answer': 'equations',
      'tool': 'calculator',
      'activity': 'solving problems',
    },
    'Science': {
      'topic': 'Experiments & observation',
      'answer': 'experiments',
      'tool': 'laboratory',
      'activity': 'reviewing diagrams',
    },
    'English': {
      'topic': 'Grammar & writing',
      'answer': 'sentences',
      'tool': 'dictionary',
      'activity': 'reading passages',
    },
    'Sinhala': {
      'topic': 'Language skills',
      'answer': 'sentences',
      'tool': 'textbook',
      'activity': 'reading passages',
    },
    'Tamil': {
      'topic': 'Language skills',
      'answer': 'sentences',
      'tool': 'textbook',
      'activity': 'reading passages',
    },
    'Religion': {
      'topic': 'Beliefs & values',
      'answer': 'faith',
      'tool': 'scripture',
      'activity': 'thinking about stories',
    },
    'Environmental Studies': {
      'topic': 'Nature & conservation',
      'answer': 'ecosystem',
      'tool': 'fieldwork',
      'activity': 'observing nature',
    },
    'History': {
      'topic': 'Events & timelines',
      'answer': 'independence',
      'tool': 'archive',
      'activity': 'reviewing dates',
    },
    'Geography': {
      'topic': 'Maps & places',
      'answer': 'maps',
      'tool': 'compass',
      'activity': 'studying locations',
    },
    'ICT': {
      'topic': 'Computers & systems',
      'answer': 'software',
      'tool': 'computer',
      'activity': 'solving logic puzzles',
    },
    'Physics': {
      'topic': 'Forces & motion',
      'answer': 'forces',
      'tool': 'meter stick',
      'activity': 'solving problems',
    },
    'Chemistry': {
      'topic': 'Matter & reactions',
      'answer': 'atoms',
      'tool': 'test tube',
      'activity': 'balancing equations',
    },
    'Biology': {
      'topic': 'Living systems',
      'answer': 'cells',
      'tool': 'microscope',
      'activity': 'labeling parts',
    },
    'Combined Maths': {
      'topic': 'Algebra & geometry',
      'answer': 'functions',
      'tool': 'graph paper',
      'activity': 'solving formulas',
    },
    'Accounting': {
      'topic': 'Ledgers & records',
      'answer': 'ledger',
      'tool': 'calculator',
      'activity': 'recording transactions',
    },
    'Business Studies': {
      'topic': 'Business planning',
      'answer': 'marketing',
      'tool': 'spreadsheet',
      'activity': 'reviewing examples',
    },
    'Economics': {
      'topic': 'Markets & money',
      'answer': 'demand',
      'tool': 'graph',
      'activity': 'studying supply curves',
    },
    'Information Systems': {
      'topic': 'Information flow',
      'answer': 'database',
      'tool': 'computer',
      'activity': 'reviewing systems',
    },
    'Political Science': {
      'topic': 'Governments & power',
      'answer': 'government',
      'tool': 'constitution',
      'activity': 'studying systems',
    },
    'Logic': {
      'topic': 'Reasoning & argument',
      'answer': 'deduction',
      'tool': 'proof',
      'activity': 'solving puzzles',
    },
    'Science for Technology': {
      'topic': 'Applied science',
      'answer': 'materials',
      'tool': 'measurement tools',
      'activity': 'reviewing devices',
    },
    'Engineering Technology': {
      'topic': 'Machines & systems',
      'answer': 'circuits',
      'tool': 'toolkit',
      'activity': 'reviewing blueprints',
    },
    'Agriculture': {
      'topic': 'Farming & growth',
      'answer': 'crops',
      'tool': 'tractor',
      'activity': 'studying soil',
    },
  };

  final List<QuestionSet> sets = <QuestionSet>[];

  for (final String grade in primaryGrades) {
    for (final String subject in primarySubjects) {
      sets.add(_buildQuestionSet(grade, subject, 'All', subjectPracticeData));
    }
  }

  for (final String subject in olSubjects) {
    sets.add(_buildQuestionSet('O/L', subject, 'All', subjectPracticeData));
  }

  for (final String stream in alStreams.keys) {
    for (final String subject in alStreams[stream]!) {
      sets.add(_buildQuestionSet('A/L', subject, stream, subjectPracticeData));
    }
  }

  return sets;
}

QuestionSet _buildQuestionSet(
  String grade,
  String subject,
  String stream,
  Map<String, Map<String, String>> practiceData,
) {
  final Map<String, String> details = practiceData[subject] ?? <String, String>{
    'topic': 'Core concepts',
    'answer': 'principles',
    'tool': 'materials',
    'activity': 'working examples',
  };

  return QuestionSet(
    id: '${grade.toLowerCase()}_${stream.toLowerCase()}_${subject.toLowerCase().replaceAll(' ', '_')}',
    title: '$grade $subject - Quick Practice',
    grade: grade,
    subject: subject,
    stream: stream,
    topic: details['topic']!,
    description: 'Practice the fundamentals of $subject for $grade${stream != 'All' ? ' ($stream)' : ''}.',
    estimatedMinutes: 8,
    rating: 4.5,
    badge: grade == 'A/L' ? 'Top Pick' : grade == 'O/L' ? 'Practice' : 'Starter',
    accentColorValue: _accentColor(subject),
    isFeatured: grade == 'A/L',
    questions: _buildQuestions(subject, details),
  );
}

int _accentColor(String subject) {
  const List<int> colors = <int>[
    0xFF1A63E8,
    0xFFFF8A00,
    0xFF31C48D,
    0xFFF59E0B,
    0xFF8B5CF6,
    0xFFEF4444,
    0xFF0EA5E9,
  ];
  return colors[subject.length % colors.length];
}

List<Question> _buildQuestions(
  String subject,
  Map<String, String> details,
) {
  return <Question>[
    Question(
      id: 'q1',
      prompt: 'Which term is most related to $subject?',
      options: <String>[
        details['answer']!,
        'sentence',
        'graph',
        'balance sheet',
      ],
      correctIndex: 0,
      explanation: '${details['answer']} is a key idea in $subject.',
    ),
    Question(
      id: 'q2',
      prompt: '$subject practice often includes questions about:',
      options: <String>[
        details['topic']!,
        'poetry',
        'elections',
        'accounts',
      ],
      correctIndex: 0,
      explanation: '${details['topic']} is a core $subject theme.',
    ),
    Question(
      id: 'q3',
      prompt: 'Which tool is commonly used in $subject?',
      options: <String>[
        details['tool']!,
        'brush',
        'ruler',
        'notebook',
      ],
      correctIndex: 0,
      explanation: '${details['tool']} is closely associated with $subject.',
    ),
    Question(
      id: 'q4',
      prompt: 'To improve in $subject, you should practice:',
      options: <String>[
        details['activity']!,
        'drawing',
        'memorizing dates',
        'cooking',
      ],
      correctIndex: 0,
      explanation: '${details['activity']} helps strengthen $subject skills.',
    ),
  ];
}

const List<PastPaper> _samplePastPapers = <PastPaper>[
  PastPaper(
    id: 'ol_maths_2024',
    title: 'O/L Mathematics - Past Paper',
    grade: 'O/L',
    subject: 'Mathematics',
    stream: 'All',
    year: 2024,
    examType: 'Annual Exam',
    pdfUrl: _samplePdf,
    pages: 16,
    fileSize: '4.2 MB',
  ),
  PastPaper(
    id: 'ol_english_2023',
    title: 'O/L English - Past Paper',
    grade: 'O/L',
    subject: 'English',
    stream: 'All',
    year: 2023,
    examType: 'Annual Exam',
    pdfUrl: _samplePdf,
    pages: 12,
    fileSize: '3.1 MB',
  ),
  PastPaper(
    id: 'al_physics_2024',
    title: 'A/L Physics - Past Paper',
    grade: 'A/L',
    subject: 'Physics',
    stream: 'Science',
    year: 2024,
    examType: 'Theory Paper',
    pdfUrl: _samplePdf,
    pages: 20,
    fileSize: '5.4 MB',
  ),
  PastPaper(
    id: 'al_accounting_2023',
    title: 'A/L Accounting - Past Paper',
    grade: 'A/L',
    subject: 'Accounting',
    stream: 'Commerce',
    year: 2023,
    examType: 'Theory Paper',
    pdfUrl: _samplePdf,
    pages: 18,
    fileSize: '4.8 MB',
  ),
  PastPaper(
    id: 'al_history_2022',
    title: 'A/L History - Past Paper',
    grade: 'A/L',
    subject: 'History',
    stream: 'Arts',
    year: 2022,
    examType: 'Theory Paper',
    pdfUrl: _samplePdf,
    pages: 15,
    fileSize: '3.7 MB',
  ),
  PastPaper(
    id: 'al_ict_2024',
    title: 'A/L ICT - Past Paper',
    grade: 'A/L',
    subject: 'ICT',
    stream: 'Technology',
    year: 2024,
    examType: 'Theory Paper',
    pdfUrl: _samplePdf,
    pages: 14,
    fileSize: '3.9 MB',
  ),
];

