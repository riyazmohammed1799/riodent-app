import 'package:flutter/material.dart';
import '../config/environment.dart';

/// Wraps [child] with an unobtrusive "BETA / STAGING" badge when running in STAGING.
///
/// In DEV and PROD, it renders [child] untouched without any overlay or performance overhead.
/// The badge uses [IgnorePointer] so touch events pass through to underlying UI elements freely.
class StagingIndicatorOverlay extends StatelessWidget {
  final Widget? child;
  final Environment? environment;

  const StagingIndicatorOverlay({
    super.key,
    required this.child,
    this.environment,
  });

  @override
  Widget build(BuildContext context) {
    if (child == null) return const SizedBox.shrink();
    final activeEnv = environment ?? Environment.current;
    if (!activeEnv.isStaging) return child!;

    return Stack(
      children: [
        child!,
        Positioned(
          top: 0,
          right: 16,
          child: SafeArea(
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.science_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'BETA / STAGING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
