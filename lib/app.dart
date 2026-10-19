import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

/// Root application widget.
///
/// Configures MaterialApp.router with RioDent brand theme,
/// environment awareness, dark/light theme switching, and declarative go_router routing.
class RioDentApp extends ConsumerWidget {
  const RioDentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: '${AppConstants.appName} - ${AppConstants.appTagline}',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // When viewed on desktop/wide screens (> 640px), avoid full-width mobile stretching for doctor screens.
            // Admin screens utilize the full desktop width for comprehensive dashboard tables and metrics.
            if (constraints.maxWidth > 640) {
              final currentPath = router.routerDelegate.currentConfiguration.uri.path;
              final isAdminRoute = currentPath.startsWith('/admin');
              if (isAdminRoute) {
                return child ?? const SizedBox.shrink();
              }

              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Scaffold(
                backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                body: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 580),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.45)
                              : const Color(0xFF0F172A).withValues(alpha: 0.08),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.symmetric(
                        vertical: BorderSide(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                    ),
                    child: ClipRect(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              );
            }
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}

