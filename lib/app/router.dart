import 'package:acad_mate/features/auth/presentation/login_screen.dart';
import 'package:acad_mate/features/auth/presentation/recover_password_screen.dart';
import 'package:acad_mate/features/auth/presentation/reset_password_screen.dart';
import 'package:acad_mate/features/papers/presentation/past_paper_viewer_screen.dart';
import 'package:acad_mate/features/quiz/presentation/quiz_session_screen.dart';
import 'package:acad_mate/features/splash/presentation/splash_screen.dart';
import 'package:acad_mate/features/home/presentation/app_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        redirect: (context, state) => '/splash',
      ),
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _fadePage(
          state,
          const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fadePage(
          state,
          const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/recover-password',
        pageBuilder: (context, state) {
          final queryParams = state.uri.queryParameters;
          return _fadePage(
            state,
            RecoverPasswordScreen(initialEmail: queryParams['email']),
          );
        },
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) {
          final queryParams = state.uri.queryParameters;
          return _fadePage(
            state,
            ResetPasswordScreen(email: queryParams['email']),
          );
        },
      ),
      GoRoute(
        path: '/app',
        pageBuilder: (context, state) => _fadePage(
          state,
          const AppShellScreen(),
        ),
      ),
      GoRoute(
        path: '/quiz/:setId',
        pageBuilder: (context, state) => _fadePage(
          state,
          QuizSessionScreen(setId: state.pathParameters['setId'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/paper/:paperId',
        pageBuilder: (context, state) => _fadePage(
          state,
          PastPaperViewerScreen(paperId: state.pathParameters['paperId'] ?? ''),
        ),
      ),
    ],
  );
});

CustomTransitionPage<void> _fadePage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final CurvedAnimation curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final Animation<Offset> slide = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(curve);

      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: slide,
          child: child,
        ),
      );
    },
  );
}

