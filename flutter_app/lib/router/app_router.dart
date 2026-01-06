import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../screens/landing_page.dart';
import '../screens/login_page.dart';
import '../screens/signup_page.dart';
import '../screens/set_password_page.dart';
import '../screens/dashboard.dart';
import '../screens/settings_page.dart';
import '../screens/context_history.dart';
import '../screens/session_detail.dart';
import '../screens/analytics_page.dart';
import '../screens/privacy_policy_page.dart';
import '../screens/terms_of_service_page.dart';
import '../screens/onboarding_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'landing',
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/set-password',
        name: 'set-password',
        builder: (context, state) => const SetPasswordPage(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const Dashboard(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const ContextHistory(),
      ),
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsPage(),
      ),
      GoRoute(
        path: '/session/:id',
        name: 'session',
        builder: (context, state) => SessionDetail(
          sessionId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/privacy-policy',
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: '/terms-of-service',
        name: 'terms-of-service',
        builder: (context, state) => const TermsOfServicePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}
