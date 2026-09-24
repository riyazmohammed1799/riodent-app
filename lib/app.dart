import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/environment.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

/// Root application widget.
///
/// Sets up MaterialApp with theming, routing, and environment-aware
/// debug banner. Wrapped in [ProviderScope] at the call site (main.dart).
class RioDentApp extends StatelessWidget {
  const RioDentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final env = Environment.current;

    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: env.isDebug,
      home: const _TemporaryHomeScreen(),
    );
  }
}

/// Temporary placeholder screen — will be replaced by go_router
/// and splash/auth flow in the next phase.
class _TemporaryHomeScreen extends StatelessWidget {
  const _TemporaryHomeScreen();

  @override
  Widget build(BuildContext context) {
    final env = Environment.current;
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.medical_services_rounded,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.appTagline,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  'Environment: ${env.label}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Project initialized. Firebase setup pending.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
