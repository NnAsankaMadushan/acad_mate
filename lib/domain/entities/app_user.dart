class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.grade,
    required this.stream,
    this.avatarUrl,
    this.authProvider,
    this.streakDays = 0,
    this.completedQuestions = 0,
    this.bookmarkedPapers = 0,
    this.isFirebaseAccount = false,
  });

  final String uid;
  final String name;
  final String email;
  final String grade;
  final String stream;
  final String? avatarUrl;
  final String? authProvider;
  final int streakDays;
  final int completedQuestions;
  final int bookmarkedPapers;
  final bool isFirebaseAccount;

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? grade,
    String? stream,
    String? avatarUrl,
    String? authProvider,
    int? streakDays,
    int? completedQuestions,
    int? bookmarkedPapers,
    bool? isFirebaseAccount,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      grade: grade ?? this.grade,
      stream: stream ?? this.stream,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      authProvider: authProvider ?? this.authProvider,
      streakDays: streakDays ?? this.streakDays,
      completedQuestions: completedQuestions ?? this.completedQuestions,
      bookmarkedPapers: bookmarkedPapers ?? this.bookmarkedPapers,
      isFirebaseAccount: isFirebaseAccount ?? this.isFirebaseAccount,
    );
  }
}

