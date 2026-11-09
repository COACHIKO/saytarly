import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:saytarly/core/localization/messages.dart';
import 'package:saytarly/core/updater/release_info.dart';

String _humanSize(int bytes) {
  if (bytes <= 0) return '';
  final mb = bytes / (1024 * 1024);
  if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
  return '${(bytes / 1024).toStringAsFixed(0)} KB';
}

/// حوار "في نسخة جديدة" — إبداعي:
/// هيدر متدرج باللون الأساسي + نسخة كبيرة + حجم الملف + ملاحظات التحديث
/// + زرار تحميل (قبول) وزرار لاحقًا (إلغاء).
Future<bool?> showUpdatePrompt({
  required BuildContext context,
  required String currentVersion,
  required GithubRelease release,
}) {
  final version = release.versionFromTag;
  final notes = release.notes.trim().isEmpty ? release.name : release.notes;
  final sizeText =
      release.zipAsset != null ? _humanSize(release.zipAsset!.size) : null;

  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'update',
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder:
        (dialogContext, _, __) => _UpdatePromptBody(
          version: version,
          currentVersion: currentVersion,
          notes: notes,
          sizeText: sizeText,
        ),
    transitionBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
  );
}

class _UpdatePromptBody extends StatelessWidget {
  const _UpdatePromptBody({
    required this.version,
    required this.currentVersion,
    required this.notes,
    this.sizeText,
  });

  final String version;
  final String currentVersion;
  final String notes;
  final String? sizeText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 420,
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── الهيدر المتدرج ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.primary, scheme.tertiary],
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.rocket_launch_rounded,
                      size: 34,
                      color: scheme.onPrimary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'نسخة جديدة متاحة'.tr(),
                      style: textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      version,
                      style: textTheme.headlineMedium?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              // ── الجسم ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _VersionChip(
                          label: 'النسخة الحالية: {v1}'.tr({
                            'v1': currentVersion,
                          }),
                          icon: Icons.phonelink_rounded,
                          muted: true,
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: scheme.primary,
                        ),
                        _VersionChip(
                          label: version,
                          icon: Icons.auto_awesome_rounded,
                          accent: true,
                        ),
                      ],
                    ),
                    if (sizeText != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest.withValues(
                                alpha: 0.6,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.download_rounded,
                                  size: 15,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  sizeText!,
                                  style: textTheme.labelMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'الجديد في النسخة'.tr(),
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: SingleChildScrollView(
                        child: Text(
                          notes,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── الأزرار: قبول / إلغاء ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: scheme.outline.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text('لاحقًا'.tr()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: scheme.primary,
                        ),
                        icon: const Icon(Icons.download_rounded, size: 20),
                        label: Text(
                          'تحميل التحديث'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionChip extends StatelessWidget {
  const _VersionChip({
    required this.label,
    required this.icon,
    this.accent = false,
    this.muted = false,
  });

  final String label;
  final IconData icon;
  final bool accent;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background =
        accent
            ? scheme.primary.withValues(alpha: 0.14)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final foreground = accent ? scheme.primary : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border:
            accent
                ? Border.all(color: scheme.primary.withValues(alpha: 0.5))
                : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// حوار الرجوع لنسخة أقدم — قايمة نسخ قديمة تختار منها، مع تأكيد واضح.
Future<GithubRelease?> showRollbackPrompt({
  required BuildContext context,
  required String currentVersion,
  required List<GithubRelease> releases,
}) {
  return showGeneralDialog<GithubRelease>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'rollback',
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder:
        (dialogContext, _, __) =>
            _RollbackBody(currentVersion: currentVersion, releases: releases),
    transitionBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

class _RollbackBody extends StatefulWidget {
  const _RollbackBody({required this.currentVersion, required this.releases});

  final String currentVersion;
  final List<GithubRelease> releases;

  @override
  State<_RollbackBody> createState() => _RollbackBodyState();
}

class _RollbackBodyState extends State<_RollbackBody> {
  GithubRelease? _selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 440,
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.history_rounded, size: 30, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      'الرجوع لنسخة أقدم'.tr(),
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'النسخة الحالية: {v1}'.tr({'v1': widget.currentVersion}),
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اختار النسخة اللي عايز ترجعلها'.tr(),
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'البيانات بتفضل زي ما هي — بيرجع ملفات التطبيق بس.'.tr(),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final release in widget.releases)
                              _rollbackTile(
                                release,
                                dateFormat,
                                release == _selected,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('إلغاء'.tr()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed:
                            _selected == null
                                ? null
                                : () => Navigator.pop(context, _selected),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFFF59E0B),
                          disabledBackgroundColor:
                              scheme.surfaceContainerHighest,
                        ),
                        icon: const Icon(Icons.undo_rounded, size: 20),
                        label: Text(
                          _selected == null
                              ? 'اختار نسخة'.tr()
                              : 'الرجوع للنسخة {v1}'.tr({
                                'v1': _selected!.versionFromTag,
                              }),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rollbackTile(
    GithubRelease release,
    DateFormat dateFormat,
    bool selected,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sizeText =
        release.zipAsset != null ? _humanSize(release.zipAsset!.size) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selected = release),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:
                selected
                    ? scheme.primary.withValues(alpha: 0.10)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  selected
                      ? scheme.primary.withValues(alpha: 0.65)
                      : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? scheme.primary : scheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      release.versionFromTag,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (release.publishedAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'تاريخ النشر: {v1}'.tr({
                          'v1': dateFormat.format(
                            release.publishedAt!.toLocal(),
                          ),
                        }),
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (sizeText != null)
                Text(
                  sizeText,
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// حوار التقدم أثناء تنزيل التحديث — بيقفل نفسه لما التقدم يوصل 100%.
Future<void> showDownloadProgress(
  BuildContext context,
  ValueListenable<double> progress,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _DownloadDialog(progress: progress),
  );
}

class _DownloadDialog extends StatefulWidget {
  const _DownloadDialog({required this.progress});

  final ValueListenable<double> progress;

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  @override
  void initState() {
    super.initState();
    widget.progress.addListener(_onProgress);
  }

  @override
  void dispose() {
    widget.progress.removeListener(_onProgress);
    super.dispose();
  }

  void _onProgress() {
    if (!mounted) return;
    if (widget.progress.value >= 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = (widget.progress.value.clamp(0.0, 1.0) * 100).round();
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_download_rounded, size: 34, color: scheme.primary),
          const SizedBox(height: 12),
          Text(
            'بينزل التحديث…'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value:
                  widget.progress.value > 0
                      ? widget.progress.value.clamp(0.0, 1.0)
                      : null,
            ),
          ),
          const SizedBox(height: 8),
          Text('$percent%'),
        ],
      ),
    );
  }
}

/// رسالة سريعة — للتشخيص أو لو التحديث راح لرابط خارجي.
Future<void> showUpdaterMessage(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('تمام'.tr()),
          ),
        ],
      );
    },
  );
}
