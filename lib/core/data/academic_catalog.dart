class AcademicCatalog {
  static const List<String> grades = <String>[
    'All',
    'Grade 1',
    'Grade 2',
    'Grade 3',
    'Grade 4',
    'Grade 5',
    'Grade 6',
    'Grade 7',
    'Grade 8',
    'Grade 9',
    'O/L',
    'A/L',
  ];

  static const List<String> streams = <String>[
    'All',
    'Science',
    'Commerce',
    'Arts',
    'Technology',
  ];

  static List<String> subjectsFor({
    required String grade,
    required String stream,
  }) {
    if (grade == 'A/L') {
      switch (stream) {
        case 'Science':
          return <String>[
            'All',
            'Physics',
            'Chemistry',
            'Biology',
            'Combined Maths',
            'ICT',
          ];
        case 'Commerce':
          return <String>[
            'All',
            'Accounting',
            'Business Studies',
            'Economics',
            'Information Systems',
            'ICT',
          ];
        case 'Arts':
          return <String>[
            'All',
            'History',
            'Geography',
            'Political Science',
            'Logic',
            'Sinhala',
          ];
        case 'Technology':
          return <String>[
            'All',
            'Science for Technology',
            'Engineering Technology',
            'ICT',
            'Agriculture',
          ];
        default:
          return <String>[
            'All',
            'Physics',
            'Chemistry',
            'Biology',
            'Combined Maths',
            'Accounting',
            'Economics',
            'History',
            'Geography',
            'ICT',
          ];
      }
    }

    if (grade == 'All') {
      const List<String> allPrimary = <String>[
        'Mathematics',
        'Science',
        'English',
        'Sinhala',
        'Tamil',
        'Religion',
        'Environmental Studies',
      ];
      const List<String> allOl = <String>[
        'Mathematics',
        'Science',
        'English',
        'History',
        'Geography',
        'ICT',
      ];
      final Set<String> allAlSubjects = <String>{
        'Physics',
        'Chemistry',
        'Biology',
        'Combined Maths',
        'ICT',
        'Accounting',
        'Business Studies',
        'Economics',
        'Information Systems',
        'History',
        'Geography',
        'Political Science',
        'Logic',
        'Sinhala',
        'Science for Technology',
        'Engineering Technology',
        'Agriculture',
      };

      return <String>[
        'All',
        ...allPrimary,
        ...allOl.where((subject) => !allPrimary.contains(subject)),
        ...allAlSubjects.where((subject) =>
            !allPrimary.contains(subject) && !allOl.contains(subject)),
      ];
    }

    return <String>[
      'All',
      'Mathematics',
      'Science',
      'English',
      'Sinhala',
      'Tamil',
      'Religion',
      'Environmental Studies',
    ];
  }
}

