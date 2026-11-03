import 'package:flutter/material.dart';

/// 🖱️ منسّق الهوفر — فيه ماوس واحد بس، يعني عنصر واحد بس المفروض ياخد
/// تأثير الهوفر في أي لحظة. الاعتماد على `onExit` لوحده ممكن يفوّت حدث
/// الخروج (نافذة فقدت الفوكس / تبديل سريع) فيفضل العنصر متظلل، ومع كذا
/// عنصر بيتحسب إن كلهم hovered. النوتيفاير ده بيخلي آخر عنصر دخل هو
/// الوحيد المتظلل، وأي عنصر تاني بيتصفّر تلقائيًا.
class HoverCoordinator {
  HoverCoordinator._();

  static final ValueNotifier<Object?> active = ValueNotifier<Object?>(null);

  /// تصفير الهوفر بالكامل — بيتنادى لما النافذة تفقد الفوكس.
  static void clear() {
    if (active.value != null) active.value = null;
  }
}

/// بيلف أي Widget وبيقولك الماوس فوقه ولا لأ — الأساس لكل التفاعلات
/// البريميوم في واجهة الويندوز (رفع الكارت، تغيير الحدود، المؤشر...).
class HoverBuilder extends StatefulWidget {
  const HoverBuilder({
    super.key,
    required this.builder,
    this.cursor = SystemMouseCursors.click,
  });

  /// الابن بيتبني مع حالة الـ hover.
  final Widget Function(BuildContext context, bool hovering) builder;

  /// شكل مؤشر الماوس وقت الوقوف على العنصر.
  final MouseCursor cursor;

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder>
    with WidgetsBindingObserver {
  final Object _token = Object();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 🪟 ويندوز مش بيبعت onExit للنافذة اللي فقدت الفوكس — نصفّر بنفسنا.
    if (state != AppLifecycleState.resumed) HoverCoordinator.clear();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => HoverCoordinator.active.value = _token,
      onExit: (_) {
        if (HoverCoordinator.active.value == _token) {
          HoverCoordinator.clear();
        }
      },
      child: ValueListenableBuilder<Object?>(
        valueListenable: HoverCoordinator.active,
        builder:
            (context, active, _) =>
                widget.builder(context, identical(active, _token)),
      ),
    );
  }
}
