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
}

const String _samplePdf =
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';

const List<QuestionSet> _sampleQuestionSets = <QuestionSet>[
  QuestionSet(
    id: 'ol_maths_linear',
    title: 'O/L Mathematics - Linear Equations',
    grade: 'O/L',
    subject: 'Mathematics',
    stream: 'All',
    topic: 'Algebra Basics',
    description:
        'Build confidence with short, exam-style questions on linear equations and number operations.',
    estimatedMinutes: 8,
    rating: 4.8,
    badge: 'Popular',
    accentColorValue: 0xFF1A63E8,
    isFeatured: true,
    questions: <Question>[
      Question(
        id: 'q1',
        prompt: 'Solve 2x + 5 = 13.',
        options: <String>['x = 2', 'x = 4', 'x = 6', 'x = 8'],
        correctIndex: 1,
        explanation: '2x = 8, so x = 4.',
      ),
      Question(
        id: 'q2',
        prompt: 'What is 10% of 200?',
        options: <String>['10', '15', '20', '25'],
        correctIndex: 2,
        explanation: '10% of 200 is 20.',
      ),
      Question(
        id: 'q3',
        prompt: 'Area of a rectangle with length 8 and width 3?',
        options: <String>['11', '21', '24', '27'],
        correctIndex: 2,
        explanation: 'Area = 8 × 3 = 24.',
      ),
      Question(
        id: 'q4',
        prompt: 'If x = -3, what is x2?',
        options: <String>['-9', '0', '3', '9'],
        correctIndex: 3,
        explanation: '(-3)² = 9.',
      ),
    ],
  ),
  QuestionSet(
    id: 'ol_english_grammar',
    title: 'O/L English - Grammar Sprint',
    grade: 'O/L',
    subject: 'English',
    stream: 'All',
    topic: 'Grammar',
    description:
        'Sharpen verb forms, prepositions, and sentence structure with fast-paced practice.',
    estimatedMinutes: 7,
    rating: 4.6,
    badge: 'New',
    accentColorValue: 0xFFFF8A00,
    questions: <Question>[
      Question(
        id: 'q1',
        prompt: 'Choose the correct sentence.',
        options: <String>[
          'She go to school every day.',
          'She goes to school every day.',
          'She going to school every day.',
          'She gone to school every day.',
        ],
        correctIndex: 1,
        explanation: 'Third person singular needs "goes".',
      ),
      Question(
        id: 'q2',
        prompt: 'Select the correct preposition: The book is ___ the table.',
        options: <String>['on', 'in', 'at', 'by'],
        correctIndex: 0,
        explanation: 'Use "on" for surface placement.',
      ),
      Question(
        id: 'q3',
        prompt: 'Identify the adjective.',
        options: <String>['quickly', 'blue', 'run', 'beyond'],
        correctIndex: 1,
        explanation: '"Blue" describes a noun, so it is an adjective.',
      ),
      Question(
        id: 'q4',
        prompt: 'Choose the correct plural form of "child".',
        options: <String>['childs', 'childes', 'children', 'childrens'],
        correctIndex: 2,
        explanation: 'The irregular plural is children.',
      ),
    ],
  ),
  QuestionSet(
    id: 'al_physics_mechanics',
    title: 'A/L Physics - Mechanics Focus',
    grade: 'A/L',
    subject: 'Physics',
    stream: 'Science',
    topic: 'Mechanics',
    description:
        'Practice motion, forces, and energy with targeted science-stream questions.',
    estimatedMinutes: 12,
    rating: 4.9,
    badge: 'Top Pick',
    accentColorValue: 0xFF31C48D,
    isFeatured: true,
    questions: <Question>[
      Question(
        id: 'q1',
        prompt: 'A force of 10 N acts on a 2 kg mass. Acceleration?',
        options: <String>['2 m/s²', '5 m/s²', '10 m/s²', '20 m/s²'],
        correctIndex: 1,
        explanation: 'a = F / m = 10 / 2 = 5 m/s².',
      ),
      Question(
        id: 'q2',
        prompt: 'The unit of work is:',
        options: <String>['Watt', 'Newton', 'Joule', 'Pascal'],
        correctIndex: 2,
        explanation: 'Work is measured in joules.',
      ),
      Question(
        id: 'q3',
        prompt: 'Which quantity is a vector?',
        options: <String>['Speed', 'Mass', 'Distance', 'Velocity'],
        correctIndex: 3,
        explanation: 'Velocity has magnitude and direction.',
      ),
      Question(
        id: 'q4',
        prompt: 'Momentum equals:',
        options: <String>['m × v', 'F × t', 'm ÷ v', 'v ÷ t'],
        correctIndex: 0,
        explanation: 'Momentum = mass × velocity.',
      ),
    ],
  ),
  QuestionSet(
    id: 'al_accounting_ledgers',
    title: 'A/L Accounting - Ledgers & Books',
    grade: 'A/L',
    subject: 'Accounting',
    stream: 'Commerce',
    topic: 'Bookkeeping',
    description:
        'Reinforce double-entry bookkeeping, ledgers, and trial balance logic.',
    estimatedMinutes: 10,
    rating: 4.7,
    badge: 'Trending',
    accentColorValue: 0xFFF59E0B,
    questions: <Question>[
      Question(
        id: 'q1',
        prompt: 'A debit balance in cash book means:',
        options: <String>[
          'Overdraft',
          'Cash at bank',
          'Suspense item',
          'Credit note',
        ],
        correctIndex: 1,
        explanation: 'A debit cash balance is cash at bank or in hand.',
      ),
      Question(
        id: 'q2',
        prompt: 'The accounting equation is:',
        options: <String>[
          'Assets = Liabilities + Equity',
          'Assets = Income + Expenses',
          'Revenue = Assets - Liabilities',
          'Capital = Revenue + Expenses',
        ],
        correctIndex: 0,
        explanation: 'Assets equal liabilities plus equity.',
      ),
      Question(
        id: 'q3',
        prompt: 'Which book records credit sales?',
        options: <String>[
          'Sales day book',
          'Purchases day book',
          'Cash book',
          'General journal',
        ],
        correctIndex: 0,
        explanation: 'Credit sales are recorded in the sales day book.',
      ),
      Question(
        id: 'q4',
        prompt: 'Trial balance is prepared to check:',
        options: <String>[
          'Only profits',
          'Arithmetic accuracy',
          'Tax liability',
          'Cash flow',
        ],
        correctIndex: 1,
        explanation: 'It checks the arithmetic accuracy of ledger balances.',
      ),
    ],
  ),
  QuestionSet(
    id: 'al_history_nation',
    title: 'A/L History - Nation Building',
    grade: 'A/L',
    subject: 'History',
    stream: 'Arts',
    topic: 'Sri Lanka',
    description:
        'A focused set on social change, independence, and post-colonial developments.',
    estimatedMinutes: 11,
    rating: 4.5,
    badge: 'Study',
    accentColorValue: 0xFF8B5CF6,
    questions: <Question>[
      Question(
        id: 'q1',
        prompt: 'Sri Lanka gained independence in:',
        options: <String>['1945', '1948', '1956', '1972'],
        correctIndex: 1,
        explanation: 'Sri Lanka became independent in 1948.',
      ),
      Question(
        id: 'q2',
        prompt: 'The Mahavamsa is primarily a:',
        options: <String>[
          'Trade manual',
          'Chronicle',
          'Law code',
          'Travel diary',
        ],
        correctIndex: 1,
        explanation: 'Mahavamsa is an ancient chronicle of Sri Lankan history.',
      ),
      Question(
        id: 'q3',
        prompt: 'A major theme after independence was:',
        options: <String>[
          'Colonial expansion',
          'Nation building',
          'Industrial abolition',
          'Monarchy restoration',
        ],
        correctIndex: 1,
        explanation: 'The country focused on nation building and reform.',
      ),
      Question(
        id: 'q4',
        prompt: 'The official language policy changed notably in:',
        options: <String>['1931', '1948', '1956', '1978'],
        correctIndex: 2,
        explanation: 'The 1956 policy shift is a major milestone.',
      ),
    ],
  ),
  QuestionSet(
    id: 'al_ict_networks',
    title: 'A/L ICT - Networks & Security',
    grade: 'A/L',
    subject: 'ICT',
    stream: 'Technology',
    topic: 'Networks',
    description:
        'Cover protocols, security, and internet basics in a clean, exam-focused format.',
    estimatedMinutes: 9,
    rating: 4.8,
    badge: 'Hot',
    accentColorValue: 0xFF1A63E8,
    questions: <Question>[
      Question(
        id: 'q1',
        prompt: 'Which device forwards packets between networks?',
        options: <String>['Switch', 'Router', 'Printer', 'Hub'],
        correctIndex: 1,
        explanation: 'Routers forward packets between networks.',
      ),
      Question(
        id: 'q2',
        prompt: 'HTTPS primarily uses which protocol for security?',
        options: <String>['TLS', 'FTP', 'SMTP', 'SNMP'],
        correctIndex: 0,
        explanation: 'HTTPS is secured with TLS.',
      ),
      Question(
        id: 'q3',
        prompt: 'What does DNS do?',
        options: <String>[
          'Compresses files',
          'Maps domain names to IP addresses',
          'Encrypts emails',
          'Stores user photos',
        ],
        correctIndex: 1,
        explanation: 'DNS resolves domain names into IP addresses.',
      ),
      Question(
        id: 'q4',
        prompt: 'A strong password should include:',
        options: <String>[
          'Only letters',
          'Only numbers',
          'A mix of characters',
          'Your name',
        ],
        correctIndex: 2,
        explanation: 'A mix of letters, numbers, and symbols is stronger.',
      ),
    ],
  ),
];

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

