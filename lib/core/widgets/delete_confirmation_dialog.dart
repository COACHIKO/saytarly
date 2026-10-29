import 'dart:ui';

import 'package:flutter/material.dart';

/// A beautiful, adaptive delete confirmation dialog for CRM entities.
/// Works seamlessly on both mobile and Windows/desktop.
///
/// Usage:
/// ```dart
/// final confirmed = await showDeleteConfirmationDialog(
///   context: context,
///   entityType: 'Lead',
///   entityName: 'John Doe',
/// );
/// ```
Future<bool> showDeleteConfirmationDialog({
  required BuildContext context,
  required String entityType,
  String? entityName,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (context, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(curved),
        child: FadeTransition(
          opacity: anim1,
          child: _DeleteConfirmationContent(
            entityType: entityType,
            entityName: entityName,
          ),
        ),
      );
    },
  );
  return result ?? false;
}

class _DeleteConfirmationContent extends StatelessWidget {
  final String entityType;
  final String? entityName;

  const _DeleteConfirmationContent({
    required this.entityType,
    this.entityName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final dialogWidth = isDesktop ? 420.0 : screenWidth * 0.85;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: dialogWidth,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E2E).withOpacity(0.95)
                  : Colors.white.withOpacity(0.97),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.red.withOpacity(isDark ? 0.08 : 0.05),
                  blurRadius: 60,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated danger icon
                    _DangerIcon(isDark: isDark),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'Delete $entityType',
                      style: TextStyle(
                        fontSize: isDesktop ? 22 : 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Are you sure you want to delete ',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF64748B),
                              height: 1.5,
                            ),
                          ),
                          if (entityName != null && entityName!.isNotEmpty)
                            TextSpan(
                              text: '"$entityName"',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                                height: 1.5,
                              ),
                            ),
                          if (entityName == null || entityName!.isEmpty)
                            TextSpan(
                              text: 'this ${entityType.toLowerCase()}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                                height: 1.5,
                              ),
                            ),
                          TextSpan(
                            text: '? This action cannot be undone.',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF64748B),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Action Buttons
                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: _CancelButton(isDark: isDark),
                        ),
                        const SizedBox(width: 12),
                        // Delete Button
                        Expanded(
                          child: _DeleteButton(isDark: isDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DangerIcon extends StatelessWidget {
  final bool isDark;
  const _DangerIcon({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF4757).withOpacity(0.15),
            const Color(0xFFFF6B81).withOpacity(0.08),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFF4757).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF4757),
                Color(0xFFE84141),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4757).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final bool isDark;
  const _CancelButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).pop(false),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.12)
                : const Color(0xFFE2E8F0),
          ),
          foregroundColor: isDark ? Colors.white70 : const Color(0xFF64748B),
        ),
        child: const Text(
          'Cancel',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final bool isDark;
  const _DeleteButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(true),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF4757),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, size: 18),
            SizedBox(width: 6),
            Text(
              'Delete',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
