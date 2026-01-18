import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'layouts/main_layout.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/home/home_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/profile/profile_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: ValueNotifier(authState), // Re-evaluate redirects on auth change
    redirect: (context, state) {
      final isLoggingIn = state.uri.path.startsWith('/auth');
      
      if (authState.isLoading) return null; // Wait for load

      if (!authState.isAuthenticated) {
        if (!isLoggingIn) return '/auth/login';
      } else {
        if (isLoggingIn) return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        redirect: (_, __) => '/auth/login',
        routes: [
          GoRoute(
            path: 'login',
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: 'register',
            builder: (context, state) => const RegisterPage(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );
});
