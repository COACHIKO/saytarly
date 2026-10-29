import 'package:flutter/material.dart';

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

class _HoverBuilderState extends State<HoverBuilder> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: widget.builder(context, _hovering),
    );
  }
}
