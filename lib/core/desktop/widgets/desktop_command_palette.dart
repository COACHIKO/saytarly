import 'package:flutter/material.dart';

import 'package:saytarly/core/desktop/desktop_tokens.dart';
import 'package:saytarly/core/desktop/widgets/desktop_sidebar.dart';
import 'package:saytarly/core/localization/messages.dart';

/// Quick navigation palette (Ctrl / Cmd + K).
///
/// Gives the desktop shell a proper command surface without adding a
/// dependency: type to filter every sidebar destination, Enter opens the first
/// match, Esc closes.
class DesktopCommandPalette extends StatefulWidget {
  const DesktopCommandPalette({super.key, required this.groups});

  final List<DesktopNavGroup> groups;

  static Future<DesktopNavItem?> show(
    BuildContext context, {
    required List<DesktopNavGroup> groups,
  }) {
    return showDialog<DesktopNavItem>(
      context: context,
      barrierColor: SaytarlyColorsOverlay.palette(context),
      builder: (_) => DesktopCommandPalette(groups: groups),
    );
  }

  @override
  State<DesktopCommandPalette> createState() => _DesktopCommandPaletteState();
}

class _DesktopCommandPaletteState extends State<DesktopCommandPalette> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  List<_CommandEntry> get _entries {
    final list = <_CommandEntry>[];
    for (final group in widget.groups) {
      for (final item in group.items) {
        list.add(_CommandEntry(item: item, group: group.title));
      }
    }
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return list;
    return list
        .where(
          (entry) =>
              entry.item.label.toLowerCase().contains(query) ||
              (entry.group?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(DesktopNavItem item) {
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final entries = _entries;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 540),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(DesktopTokens.radiusLg + 2),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: palette.shadow.withValues(
                  alpha: palette.isDark ? 0.65 : 0.22,
                ),
                blurRadius: 48,
                offset: const Offset(0, 24),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 21, color: palette.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        onChanged: (value) => setState(() => _query = value),
                        onSubmitted: (_) {
                          if (entries.isNotEmpty) _select(entries.first.item);
                        },
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن صفحة أو أداة...'.tr(),
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: palette.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceSoft,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: palette.border),
                      ),
                      child: Text(
                        'ESC',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.textMuted,
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: palette.border),
              Expanded(
                child:
                    entries.isEmpty
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 34,
                                  color: palette.textMuted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'مفيش نتائج مطابقة'.tr(),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: palette.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'جرّب كلمة أقصر أو مختلفة.'.tr(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: entries.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 1),
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return _CommandRow(
                              entry: entry,
                              onTap: () => _select(entry.item),
                            );
                          },
                        ),
              ),
              Divider(height: 1, thickness: 1, color: palette.border),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    _KeyHint(label: '↑↓', text: 'تنقّل'.tr()),
                    const SizedBox(width: 14),
                    _KeyHint(label: '↵', text: 'فتح'.tr()),
                    const Spacer(),
                    Text(
                      'SAYTARLY Command',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.textMuted,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
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

class _CommandEntry {
  const _CommandEntry({required this.item, this.group});

  final DesktopNavItem item;
  final String? group;
}

class _CommandRow extends StatefulWidget {
  const _CommandRow({required this.entry, required this.onTap});

  final _CommandEntry entry;
  final VoidCallback onTap;

  @override
  State<_CommandRow> createState() => _CommandRowState();
}

class _CommandRowState extends State<_CommandRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DesktopTokens.fast,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _hover ? palette.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(DesktopTokens.radiusSm + 2),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color:
                      _hover
                          ? palette.accent.withValues(alpha: 0.12)
                          : palette.surfaceSoft,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color:
                        _hover
                            ? palette.accent.withValues(alpha: 0.18)
                            : palette.border,
                  ),
                ),
                child: Icon(
                  widget.entry.item.icon,
                  size: 17,
                  color: _hover ? palette.accentText : palette.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.entry.item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
              if (widget.entry.group != null) ...[
                const SizedBox(width: 12),
                Text(
                  widget.entry.group!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: _hover ? palette.accent : palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyHint extends StatelessWidget {
  const _KeyHint({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: palette.surfaceSoft,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: palette.border),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 9.5,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: palette.textMuted,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

/// Small helper so the barrier colour follows the active theme without
/// importing brand constants at every callsite.
abstract final class SaytarlyColorsOverlay {
  static Color palette(BuildContext context) {
    final palette = DesktopPalette.of(context);
    return palette.isDark
        ? Colors.black.withValues(alpha: 0.55)
        : palette.textPrimary.withValues(alpha: 0.32);
  }
}
