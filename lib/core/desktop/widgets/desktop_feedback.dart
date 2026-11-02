import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:saytarly/core/desktop/desktop.dart';

/// 🔔 طقم إشعارات ولاحظات الويندوز — مركز للتطبيق كله.
///
/// - على سطح المكتب: Toast منمق (نمط ويندوز 11) بيركب فوق الشاشة
///   من غير ما يحتاج Scaffold — بيدعم التراص وزر الإغلاق والأيقونات،
///   وبيدوب بعد وقت ثابت (4 ثواني) دايمًا.
/// - على الموبايل: نفس SnackBar الأصلي زي ما هو (من غير أي تغيير).
/// - `AppDialog`: بديل جاهز لـ AlertDialog بمظهر ويندوز أنيق على سطح
///   المكتب (حدود ناعمة، هيدر أيقونة، أزرارت بارزة تلبي معايير Fluent)،
///   وعلى الموبايل بيرجع AlertDialog العادي زي الأول.

enum FeedbackKind { success, error, warning, info }

extension FeedbackKindX on FeedbackKind {
  /// الاستنتاج من بداية النص (الإيموجي) — للمواضع المهاجرة مكتوبة بالنص.
  static FeedbackKind fromText(String message) {
    final t = message.trim();
    if (t.startsWith('✅') || t.startsWith('✔')) return FeedbackKind.success;
    if (t.startsWith('❌') || t.startsWith('🚫')) return FeedbackKind.error;
    if (t.startsWith('⚠')) return FeedbackKind.warning;
    return FeedbackKind.info;
  }

  /// إزالة الإيموجي القديمة من أول النص — الأيقونة الجديدة بتاخد السايت.
  static String stripEmoji(String message) {
    var t = message.trim();
    const emojis = ['✅', '✔', '❌', '🚫', '⚠️', '⚠', 'ℹ️'];
    for (final e in emojis) {
      if (t.startsWith(e)) {
        t = t.substring(e.length).trim();
        // شيل أي علامة ترقيم متبقية بعد الاستخراج
        if (t.startsWith('—') || t.startsWith('-') || t.startsWith(':')) {
          t = t.substring(1).trim();
        }
        break;
      }
    }
    return t;
  }
}

// ---------------------------------------------------------------------------
// Toast — خدمة عامة شغالة من أي مكان حتى من ما بعد await (بدون BuildContext)
// ---------------------------------------------------------------------------

class _ToastItem {
  _ToastItem(this.message, this.kind, this.duration);

  final String message;
  final FeedbackKind kind;
  final Duration duration;
  bool exiting = false;
  Timer? tick;
}

class AppToast {
  AppToast._();

  /// المفتاح الجذري — محتاج يتعلق بـ MaterialApp فوق (navigatorKey).
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const Duration _defaultDuration = Duration(seconds: 4);
  static const int _maxVisible = 4;

  static final List<_ToastItem> _items = <_ToastItem>[];
  static OverlayEntry? _hostEntry;
  static ValueNotifier<int> revision = ValueNotifier<int>(0);

  static bool get _isDesktop {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  /// إظهار إشعارة — بتعمل routing تلقائي: ويندوز → Toast، موبايل → SnackBar.
  static void show(String message, {FeedbackKind? kind}) {
    final k = kind ?? FeedbackKindX.fromText(message);
    if (_isDesktop) {
      _pushDesktop(message, k);
    } else {
      _pushMobile(message);
    }
  }

  static void _pushMobile(String message) {
    final ctx = navigatorKey.currentContext;
    final messenger = ctx != null ? ScaffoldMessenger.maybeOf(ctx) : null;
    if (messenger == null) return; // الشاشة قفلت — مفيش غير الاكتفاء
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void _pushDesktop(String message, FeedbackKind kind) {
    // 👉 الأداء: شيل التكرار السريع لنفس النص لو لسه ظاهر.
    final same =
        _items.where((e) => e.message == message && !e.exiting).toList();
    if (same.length >= 2) return;

    final item = _ToastItem(message, kind, _defaultDuration);
    _items.add(item);
    while (_items.where((e) => !e.exiting).length > _maxVisible) {
      final oldest = _items.firstWhere((e) => !e.exiting, orElse: () => item);
      _dismiss(oldest);
    }

    _ensureHost();
    // ⏱️ مؤقت ثابت — من غير توقف عند الهوفر (كان ممكن الماوس يجلس فوق
    // مكان ظهور الإشعرة فيفضلها معلقة للأبد) — القرار: وقت محدد دايمًا.
    item.tick = Timer(item.duration, () => _dismiss(item));
    revision.value++;
  }

  static void _dismiss(_ToastItem item) {
    if (item.exiting) return;
    item.exiting = true;
    item.tick?.cancel();
    revision.value++; // الكارت بيبدأ حركة الخروج — بعدها بينشال من الليستة
    // 🛡️ ضمان نهائي مستقل عن الأنيميشن: لو الكارت عالق لأي سبب
    // (vsync مكتوم/ستاتوس مش بيتحرك) العنصر هيتشال من الليستة بعد
    // مدة حركة الخروج بقليل — الإشعار عمره ما يفضل معلق للأبد.
    Timer(const Duration(milliseconds: 300), () => _finalize(item));
  }

  static void _finalize(_ToastItem item) {
    if (_items.remove(item)) {
      revision.value++;
    }
  }

  static void _ensureHost() {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return; // لسه الماتيريال مبنى — المحاولة الجاية
    if (_hostEntry != null) {
      // ⚠️ أي route بيفتح بعد الـ host بيرندر فوقه في الـ overlay
      // (الشاشات المكدسة بترسمل فوقه) — فبنرفع الـ host فوق الكل
      // مع كل إشعار جديد. (نفس الـ entry = نفس State، مفيش رفرفة).
      _hostEntry!.remove();
    } else {
      _hostEntry = OverlayEntry(
        builder: (_) => const Positioned.fill(
          child: Align(
            alignment: AlignmentDirectional.bottomStart,
            child: _ToastStack(),
          ),
        ),
      );
    }
    overlay.insert(_hostEntry!); // append = فوق كل الـ entries الحالية
  }
}

// ---------------------------------------------------------------------------
// التراص + الكارت
// ---------------------------------------------------------------------------

class _ToastStack extends StatelessWidget {
  const _ToastStack();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppToast.revision,
      builder: (context, _, __) {
        final visible = List<_ToastItem>.of(AppToast._items);
        if (visible.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final it in visible)
                _ToastCard(key: ObjectKey(it), item: it, exiting: it.exiting),
            ],
          ),
        );
      },
    );
  }
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({super.key, required this.item, required this.exiting});

  final _ToastItem item;

  /// ⚠️ نسخة من [item.exiting] وقت البناء — عشان [didUpdateWidget] تشوف
  /// التغيير صح: لو مررنا العنصر المشترك بس، `oldWidget.item.exiting`
  /// بيكون اتحوّل لنفس القيمة (نفس الـ object الميتغيّر) والشرط بيفشل
  /// دايمًا — وده كان سبب إشعار بيفضل معلق للأبد بعد أول تشغيل.
  final bool exiting;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 240))
      ..addStatusListener(_onStatus);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    // الأمان: لو الكارت اتولد وهو أصلاً في حالة خروج (مثلاً تراكSignUp
    // شال عنصر قديم فورًا) — بنطير للنهاية ونرجّع من هنا مباشرة.
    if (widget.exiting) {
      _controller.value = 1.0;
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  void _onStatus(AnimationStatus s) {
    // مسار الإزالة النهائي في [AppToast._finalize] (تايمر مؤكد) —
    // الليستنر ده بس مسرّع اخير كطريق سريع بينما الأنيميشن شغال عادي.
    if (widget.item.exiting && s == AnimationStatus.dismissed) {
      AppToast._finalize(widget.item);
    }
  }

  @override
  void didUpdateWidget(covariant _ToastCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.exiting && !oldWidget.exiting) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _card(context),
      ),
    );
  }

  Widget _card(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final (icon, color) = switch (widget.item.kind) {
      FeedbackKind.success => (Icons.check_circle_outline, palette.success),
      FeedbackKind.error => (Icons.error_outline, palette.danger),
      FeedbackKind.warning => (Icons.warning_amber_outlined, palette.warning),
      FeedbackKind.info => (Icons.info_outline, palette.info),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: palette.isDark
                ? palette.surface.withValues(alpha: 0.98)
                : Colors.white.withValues(alpha: 0.99),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: palette.shadow.withValues(alpha: palette.isDark ? .5 : .22),
                blurRadius: 26,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: palette.soft(color), shape: BoxShape.circle),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  FeedbackKindX.stripEmoji(widget.item.message),
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ToastCloseButton(item: widget.item, palette: palette),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToastCloseButton extends StatefulWidget {
  const _ToastCloseButton({required this.item, required this.palette});

  final _ToastItem item;
  final DesktopPalette palette;

  @override
  State<_ToastCloseButton> createState() => _ToastCloseButtonState();
}

class _ToastCloseButtonState extends State<_ToastCloseButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppToast._dismiss(widget.item),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Icon(
          Icons.close,
          size: 17,
          color: _hover ? widget.palette.textPrimary : widget.palette.textMuted,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppDialog — بديل AlertDialog بمظهر ويندوز
// ---------------------------------------------------------------------------

/// بنفس باراميترات AlertDialog الشائعة — عشان مواضع النداء تحول بسهولة.
/// على سطح المكتب: كروم ويندوز أنيق (هيدر، حدود، أزرارت مُعيد تنسيق).
/// على الموبايل: AlertDialog نفسه.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const <Widget>[],
    this.shape,
    this.backgroundColor,
    this.elevation,
    this.surfaceTintColor,
    this.titlePadding,
    this.titleTextStyle,
    this.titleSpacing,
    this.actionsPadding,
    this.actionsAlignment,
    this.actionsOverflowAlignment,
    this.actionsOverflowButtonAlignment,
    this.actionsOverflowDialogPadding,
    this.buttonPadding,
    this.shadowColor,
    this.alignment,
    this.insetPadding,
    this.clipBehavior = Clip.none,
    this.scrollable = false,
    this.icon,
    this.maxWidth = 560,
    this.minWidth = 380,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget> actions;
  final ShapeBorder? shape;
  final Color? backgroundColor;
  final double? elevation;
  final Color? surfaceTintColor;
  final EdgeInsetsGeometry? titlePadding;
  final TextStyle? titleTextStyle;
  final double? titleSpacing;
  final EdgeInsetsGeometry? actionsPadding;
  final MainAxisAlignment? actionsAlignment;
  final OverflowBarAlignment? actionsOverflowAlignment;
  final OverflowBarAlignment? actionsOverflowButtonAlignment;
  final EdgeInsetsGeometry? actionsOverflowDialogPadding;
  final EdgeInsetsGeometry? buttonPadding;
  final Color? shadowColor;
  final AlignmentGeometry? alignment;
  final EdgeInsets? insetPadding;
  final Clip clipBehavior;
  final bool scrollable;
  final IconData? icon;
  final double maxWidth;
  final double minWidth;

  bool get _isDesktop {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDesktop) {
      return AlertDialog(
        title: title,
        content: content,
        actions: actions.isEmpty ? null : actions,
        shape: shape,
        backgroundColor: backgroundColor,
        elevation: elevation,
        surfaceTintColor: surfaceTintColor,
        scrollable: scrollable,
        clipBehavior: clipBehavior,
      );
    }

    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    // 🧱 الماتيريال هو اللي بيشيل لون الخلفية والحدود — مش Container ملوّن.
    // السبب: أي ListTile جوه الدايلوج بيرسم خلفيته و ink splashes على أقرب
    // Material؛ لو بينه وبينه DecoratedBox/ColoredBox بلون، فلاتر بيطلع
    // خطأ «ListTile background color or ink splashes may be invisible»
    // والضغطات ما بتظهرش. الحل: Material حقيقي + الظل برّاه (بدون لون).
    final body = Material(
      color: backgroundColor ?? palette.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.border, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==================== الهيدر ====================
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: palette.soft(palette.accent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 20, color: palette.accent),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: DefaultTextStyle(
                      style: titleTextStyle ??
                          TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      child: title!,
                    ),
                  ),
                ],
              ),
            ),
          Divider(height: 1, thickness: 1, color: palette.border),

          // ==================== المحتوى ====================
          if (content != null)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                child: scrollable
                    ? SingleChildScrollView(child: content)
                    : content,
              ),
            ),

          // ==================== الأزرار ====================
          if (actions.isNotEmpty) ...[
            Divider(height: 1, thickness: 1, color: palette.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: OverflowBar(
                alignment: actionsAlignment ?? MainAxisAlignment.end,
                overflowAlignment: actionsOverflowAlignment ?? OverflowBarAlignment.end,
                spacing: 10,
                children: actions,
              ),
            ),
          ],
        ],
      ),
    );

    // الظل برّه الماتيريال — DecoratedBox من غير لون خلفية، فمش بيتدخل
    // بين الـ ListTile والماتيريال (يعني الـ ink بيترسم عادي).
    final shadowedBody = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: palette.isDark ? .55 : .28),
            blurRadius: 36,
            offset: const Offset(0, 20),
            spreadRadius: 2,
          ),
        ],
      ),
      child: body,
    );

    // أزرار تنسيق ويندوز: سفلية الارتفاع، انحناء 6، عرض مناسب
    return Theme(
      data: theme.copyWith(
        visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
        filledButtonTheme: FilledButtonThemeData(
          style: _winButton(
            theme.filledButtonTheme.style,
            foreground: theme.colorScheme.onPrimary,
            background: theme.colorScheme.primary,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: _winButton(
            theme.elevatedButtonTheme.style,
            foreground: theme.colorScheme.onPrimary,
            background: theme.colorScheme.primary,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: _winText(theme.textButtonTheme.style, palette: palette),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: _winOutlined(theme.outlinedButtonTheme.style, palette: palette),
        ),
      ),
      child: Dialog(
        backgroundColor: Colors.transparent,
        shape:
            const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        insetPadding: insetPadding ??
            const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
          child: shadowedBody,
        ),
      ),
    );
  }

  ButtonStyle _winButton(ButtonStyle? base,
      {required Color foreground, required Color background}) {
    return (base ?? const ButtonStyle()).copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(96, 38)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18)),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(7))),
      ),
      foregroundColor: WidgetStatePropertyAll(foreground),
      backgroundColor: WidgetStatePropertyAll(background),
      elevation: const WidgetStatePropertyAll(0),
    );
  }

  ButtonStyle _winText(ButtonStyle? base, {required DesktopPalette palette}) {
    return (base ?? const ButtonStyle()).copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(88, 38)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(7))),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: palette.accent,
        ),
      ),
      foregroundColor: WidgetStatePropertyAll(palette.accent),
      overlayColor: WidgetStatePropertyAll(palette.soft(palette.accent)),
    );
  }

  ButtonStyle _winOutlined(ButtonStyle? base, {required DesktopPalette palette}) {
    return (base ?? const ButtonStyle()).copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(96, 38)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(7)),
          side: BorderSide(color: palette.border, width: 1),
        ),
      ),
      foregroundColor: WidgetStatePropertyAll(palette.textPrimary),
    );
  }
}
