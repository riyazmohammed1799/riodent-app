import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../screens/admin/admin_request_details_screen.dart';
import '../screens/admin/admin_settings_screen.dart';
import '../screens/admin/dashboard_screen.dart';
import '../screens/admin/technician_assignment_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dentist/book_technician_screen.dart';
import '../screens/dentist/home_screen.dart';
import '../screens/dentist/my_requests_screen.dart';
import '../screens/dentist/request_details_screen.dart';
import '../screens/dentist/request_review_screen.dart';
import '../screens/dentist/request_submitted_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash/splash_screen.dart';

/// Global navigation key used for deep linking, FCM push notification routing, and dialogs.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Provider exposing the application router with declarative role-based routing.
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final adminClaimAsync = ref.read(adminClaimProvider);

      final isAuthLoading = authAsync.isLoading;
      final user = authAsync.value;

      final loc = state.uri.path;

      // 1. Initializing auth state -> stay on /splash
      if (isAuthLoading) {
        return loc == '/splash' ? null : '/splash';
      }

      // 2. Unauthenticated state -> only /login
      if (user == null) {
        return loc == '/login' ? null : '/login';
      }

      // 3. User is signed in. While checking admin custom claim, stay on splash or current
      if (adminClaimAsync.isLoading) {
        return null;
      }

      final isAdmin = adminClaimAsync.value ?? false;

      // 4. Role-based routing: Admin vs Doctor
      if (isAdmin) {
        // Admin: default landing is /admin
        final isRestrictedForAdmin = loc == '/splash' ||
            loc == '/login' ||
            loc == '/admin/login';
        if (isRestrictedForAdmin) {
          return '/admin';
        }
        return null;
      } else {
        // Doctor: cannot open admin routes; registration goes straight to /dentist
        final isRestrictedForDoctor = loc == '/splash' ||
            loc == '/login' ||
            loc.startsWith('/admin') ||
            loc == '/profile-setup' ||
            loc == '/otp';
        if (isRestrictedForDoctor) {
          return '/dentist';
        }
        return null;
      }
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Dentist Routes ──────────────────────────────────────────
      GoRoute(
        path: '/dentist',
        builder: (context, state) => const DentistHomeScreen(),
        routes: [
          GoRoute(
            path: 'book',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return BookTechnicianScreen(initialCategory: extra?['category'] as String?);
            },
          ),
          GoRoute(
            path: 'review',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return RequestReviewScreen(requestData: extra);
            },
          ),
          GoRoute(
            path: 'submitted',
            builder: (context, state) {
              return RequestSubmittedScreen(requestId: state.extra ?? '');
            },
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'requests',
            builder: (context, state) {
              final initialFilter = state.uri.queryParameters['filter'];
              return MyRequestsScreen(initialFilter: initialFilter);
            },
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return RequestDetailsScreen(requestId: id);
                },
              ),
            ],
          ),
        ],
      ),

      // ── Admin Routes ────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'requests/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return AdminRequestDetailsScreen(requestId: id);
            },
          ),
          GoRoute(
            path: 'assign/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return TechnicianAssignmentScreen(requestId: id);
            },
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const AdminSettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
    ref.listen(adminClaimProvider, (_, _) => notifyListeners());
  }
}
