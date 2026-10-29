import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:saytarly/core/desktop/desktop_tokens.dart';
import 'package:saytarly/core/localization/messages.dart';

/// هيكل صفحة سطح المكتب — يُستخدم في كل الصفحات اللي بتتفتح كـ push
/// (التقارير، الإعدادات، الإدارة...).
///
/// بيدّي كل صفحة نفس الشكل: هيدر أنيق (رجوع + عنوان + وصف + أزرار)،
/// وخط فاصل، ومحتوى بعرض أقصى مريح للعين، مع دعم زر Escape للرجوع.
class DesktopPageScaffold extends StatefulWidget {
  const DesktopPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.headerBottom,
    this.leading,
    this.titleLeading,
    this.maxWidth = DesktopTokens.contentMaxWidth,
    this.padding = const EdgeInsets.all(DesktopTokens.pagePadding),
    this.scrollable = true,
    this.showBackButton = true,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  /// عنصر إضافي تحت صف العنوان (تابات، فلاتر...).
  final Widget? headerBottom;

  /// زر مخصص بدل زر الرجوع الافتراضي.
  final Widget? leading;

  /// عنصر بيتحط جنب العنوان (بعد زر الرجوع) — زي أيقونة القسم.
  final Widget? titleLeading;

  final double maxWidth;
  final EdgeInsetsGeometry padding;

  /// لو true المحتوى بيتلف في سكرول تلقائي.
  final bool scrollable;
  final bool showBackButton;

  @override
  State<DesktopPageScaffold> createState() => _DesktopPageScaffoldState();
}

class _DesktopPageScaffoldState extends State<DesktopPageScaffold> {
  /// ⚠️ سبب assertion «Scrollbar's ScrollController has no ScrollPosition
  /// attached»: Scrollbar من غير controller بيسمع إشعارات السكرول ويحاول
  /// يرسم بـ PrimaryScrollController — وده على ويندوز مش بيتورث للفيوهات
  /// من غير primary، فبيضرب assertion مع كل لفة عجلة الماوس. بنملاك
  /// الـ controller بنفسنا ونربطه بالاتنين (البار والفيو).
  final ScrollController _contentScroll = ScrollController();

  @override
  void dispose() {
    _contentScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();

    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: widget.child,
      ),
    );

    return Scaffold(
      backgroundColor: palette.background,
      body: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape &&
              canPop) {
            Navigator.of(context).maybePop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          children: [
            // ==================== الهيدر ====================
            Container(
              padding: const EdgeInsets.fromLTRB(
                DesktopTokens.pagePadding,
                12,
                DesktopTokens.pagePadding,
                12,
              ),
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border(
                  bottom: BorderSide(color: palette.border),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (widget.leading != null)
                        widget.leading!
                      else if (widget.showBackButton && canPop)
                        _HeaderBackButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      if (widget.leading != null ||
                          (widget.showBackButton && canPop))
                        const SizedBox(width: DesktopTokens.gapMd),
                      if (widget.titleLeading != null) ...[
                        widget.titleLeading!,
                        const SizedBox(width: DesktopTokens.gapMd),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: palette.textPrimary,
                                fontSize: 20,
                              ),
                            ),
                            if (widget.subtitle != null)
                              Text(
                                widget.subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: palette.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      for (final action in widget.actions) ...[
                        const SizedBox(width: DesktopTokens.gapSm),
                        action,
                      ],
                    ],
                  ),
                  if (widget.headerBottom != null) ...[
                    const SizedBox(height: DesktopTokens.gapSm + 2),
                    widget.headerBottom!,
                  ],
                ],
              ),
            ),

            // ==================== المحتوى ====================
            Expanded(
              child: widget.scrollable
                  ? DesktopScrollbar(
                      builder: (c) => SingleChildScrollView(
                        controller: c,
                        padding: widget.padding,
                        child: content,
                      ),
                    )
                  : Padding(
                      padding: widget.padding,
                      child: content,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🖱️ سكرول سطح المكتب المُصلح — Scrollbar بـ controller فعلي بيمتلكه
/// بنفسه وبيمرره للسكرول فيو اللي هتبنيه. (Scrollbar من غير controller
/// بيحاول يستخدم PrimaryScrollController — وهو على ويندوز مش بيتورث —
/// فبيضرب assertion «no ScrollPosition attached» مع كل عجلة ماوس).
///
/// الاستخدام:
/// ```dart
/// DesktopScrollbar(
///   builder: (c) => ListView(controller: c, children: [...]),
/// )
/// ```
class DesktopScrollbar extends StatefulWidget {
  const DesktopScrollbar({
    super.key,
    required this.builder,
    this.thumbVisibility,
    this.radius = const Radius.circular(5),
    this.thickness = 8,
  });

  /// بيبني السكرول فيو ياخد نفس الـ controller — اربطه فيه إلزامي.
  final Widget Function(ScrollController controller) builder;

  /// null = سلوك فلاتر الافتراضي (الإبهام يبان وقت السكرول/الهوفر).
  final bool? thumbVisibility;
  final Radius radius;
  final double thickness;

  @override
  State<DesktopScrollbar> createState() => _DesktopScrollbarState();
}

class _DesktopScrollbarState extends State<DesktopScrollbar> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollbarTheme(
      data: ScrollbarTheme.of(context).copyWith(
        thumbVisibility: WidgetStatePropertyAll(widget.thumbVisibility),
        radius: widget.radius,
        thickness: WidgetStatePropertyAll(widget.thickness),
      ),
      child: Scrollbar(
        controller: _controller,
        thumbVisibility: widget.thumbVisibility,
        child: widget.builder(_controller),
      ),
    );
  }
}

/// زر الرجوع في الهيدر — بشكل مميز مناسب لسطح المكتب.
class _HeaderBackButton extends StatefulWidget {
  const _HeaderBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_HeaderBackButton> createState() => _HeaderBackButtonState();
}

class _HeaderBackButtonState extends State<_HeaderBackButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return Tooltip(
      message: 'رجوع (Esc)'.tr(),
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: DesktopTokens.fast,
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _hovering ? palette.accentSoft : palette.surfaceSoft,
              borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
              border: Border.all(
                color: _hovering ? palette.accent : palette.border,
              ),
            ),
            child: Icon(
              Icons.chevron_right,
              size: 22,
              color: _hovering ? palette.accentText : palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
