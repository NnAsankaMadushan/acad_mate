import 'package:acad_mate/app/providers.dart';
import 'package:acad_mate/core/widgets/glass_card.dart';
import 'package:acad_mate/features/home/presentation/home_screen.dart';
import 'package:acad_mate/features/papers/presentation/past_papers_screen.dart';
import 'package:acad_mate/features/practice/presentation/practice_screen.dart';
import 'package:acad_mate/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppShellScreen extends ConsumerStatefulWidget {
  const AppShellScreen({super.key});

  @override
  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends ConsumerState<AppShellScreen> {
  int _selectedIndex = 0;

  void _openPractice() {
    setState(() => _selectedIndex = 1);
  }

  void _openPapers() {
    setState(() => _selectedIndex = 2);
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      HomeScreen(
        onOpenPractice: _openPractice,
        onOpenPapers: _openPapers,
      ),
      const PracticeScreen(),
      const PastPapersScreen(),
      ProfileScreen(onSignOut: _signOut),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(30),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() => _selectedIndex = index);
            },
            height: 74,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            backgroundColor: Colors.transparent,
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.fact_check_rounded),
                label: 'Practice',
              ),
              NavigationDestination(
                icon: Icon(Icons.picture_as_pdf_rounded),
                label: 'Papers',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

