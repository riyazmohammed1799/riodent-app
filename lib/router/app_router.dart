import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../screens/admin/admin_request_details_screen.dart';
import '../screens/admin/admin_request_list_screen.dart';
import '../screens/admin/admin_settings_screen.dart';
import '../screens/admin/dashboard_screen.dart';
import '../screens/admin/technician_assignment_screen.dart';
import '../screens/auth/admin_login_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/dentist/book_technician_screen.dart';
import '../screens/dentist/home_screen.dart';
import '../screens/dentist/my_requests_screen.dart';
import '../screens/dentist/request_details_screen.dart';
import '../screens/dentist/request_review_screen.dart';
import '../screens/dentist/request_submitted_screen.dart';
import '../screens/profile/profile_setup_screen.dart';
import '../screens/splash/splash_screen.dart';

/// Provider exposing the application router with declarative role-based routing.
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final profileAsync = ref.read(currentUserProfileProvider);

      final isAuthLoading = authAsync.isLoading;
      final user = authAsync.value;
      final profile = profileAsync.value;

      final loc = state.uri.path;

      // 1. If auth is still initializing, stay on splash
      if (isAuthLoading) {
        return loc == '/splash' ? null : '/splash';
      }

      // 2. Unauthenticated state
      if (user == null) {
        final isAuthRoute = loc == '/login' || loc == '/otp' || loc == '/admin/login';
        if (!isAuthRoute) {
          return '/login';
        }
        return null;
      }

      // 3. User is signed in. While profile is loading, stay on splash or current route
      if (profileAsync.isLoading) {
        return null;
      }

      // 4. Role-based routing
      if (profile != null) {
        if (profile.isAdmin) {
          // Admin logged in
          final isRestrictedForAdmin = loc == '/splash' ||
              loc == '/login' ||
              loc == '/otp' ||
              loc == '/admin/login' ||
              loc.startsWith('/dentist');
          if (isRestrictedForAdmin) {
            return '/admin';
          }
          return null;
        }

        if (profile.isDentist) {
          // Dentist logged in
          if (!profile.profileComplete) {
            return loc == '/profile-setup' ? null : '/profile-setup';
          }

          final isRestrictedForDentist = loc == '/splash' ||
              loc == '/login' ||
              loc == '/otp' ||
              loc == '/admin/login' ||
              loc == '/profile-setup' ||
              loc.startsWith('/admin');
          if (isRestrictedForDentist) {
            return '/dentist';
          }
          return null;
        }
      } else {
        // Authenticated user with no profile yet -> go to profile setup
        final isAuthRoute = loc == '/login' || loc == '/otp' || loc == '/admin/login' || loc == '/splash';
        if (isAuthRoute) {
          return '/profile-setup';
        }
      }

      return null;
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
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OtpScreen(
            verificationId: extra['verificationId'] as String? ?? '',
            phone: extra['phone'] as String? ?? '',
            resendToken: extra['resendToken'] as int?,
          );
        },
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // ── Dentist Routes ──────────────────────────────────────────
      GoRoute(
        path: '/dentist',
        builder: (context, state) => const DentistHomeScreen(),
        routes: [
          GoRoute(
            path: 'book',
            builder: (context, state) => const BookTechnicianScreen(),
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
              final requestId = state.extra as String? ?? '';
              return RequestSubmittedScreen(requestId: requestId);
            },
          ),
          GoRoute(
            path: 'requests',
            builder: (context, state) => const MyRequestsScreen(),
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
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'requests',
            builder: (context, state) => const AdminRequestListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return AdminRequestDetailsScreen(requestId: id);
                },
              ),
            ],
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

/// Listenable that notifies GoRouter to re-evaluate routes when auth or profile changes.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
    ref.listen(currentUserProfileProvider, (_, _) => notifyListeners());
  }
}
