import 'package:flutter/material.dart';
import 'package:saytarly/core/desktop/widgets/desktop_feedback.dart';

import 'package:saytarly/Features/cards/data/card_queue_service.dart';
import 'package:saytarly/core/localization/messages.dart';

/// زرار أيقونة جاهز تحطه في أي AppBar (زي شاشة الكاشير)، بيعرض
/// عدد الكروت المتبقية في المخزون كـ Badge، ولما تدوس عليه بيسألك
/// كام كارت عايز تطبع وبعدين يطبعهم فورًا من المخزون.
///
/// الاستخدام:
/// ```dart
/// appBar: AppBar(
///   actions: [
///     const CardQueueIconButton(),
///   ],
/// ),
/// ```
class CardQueueIconButton extends StatefulWidget {
  const CardQueueIconButton({super.key});

  @override
  State<CardQueueIconButton> createState() => _CardQueueIconButtonState();
}

class _CardQueueIconButtonState extends State<CardQueueIconButton> {
  int _count = 0;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final c = await CardQueueService.getCount();
    if (!mounted) return;
    setState(() => _count = c);
  }

  Future<void> _onTap() async {
    if (_printing) return;

    if (_count == 0) {
      AppToast.show('لا يوجد كروت متاحة في المخزون'.tr());
      return;
    }

    final qty = await _askQuantity();
    if (qty == null) return;

    setState(() => _printing = true);

    try {
      final printed = await CardQueueService.printFromQueue(qty);
      await _refresh();

      if (!mounted) return;
      AppToast.show('تم طباعة {printed} كارت'.tr({'printed': printed}));
    } catch (e) {
      if (!mounted) return;
      AppToast.show('خطأ أثناء الطباعة: {e}'.tr({'e': e}));
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<int?> _askQuantity() async {
    final ctrl = TextEditingController(text: '1');
    return showDialog<int>(
      context: context,
      builder: (_) => AppDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:  Text('كام كارت؟'.tr()),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            hintText: '1',
          ),
          onSubmitted: (_) {
            final n = int.tryParse(ctrl.text.trim()) ?? 1;
            Navigator.pop(context, n.clamp(1, _count));
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child:  Text('إلغاء'.tr()),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print, size: 18),
            label:  Text('طباعة'.tr()),
            onPressed: () {
              final n = int.tryParse(ctrl.text.trim()) ?? 1;
              Navigator.pop(context, n.clamp(1, _count));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'طباعة كارت إنترنت ({_count} متاح)'.tr({'_count': _count}),
      onPressed: _onTap,
      icon: Badge(
        label: Text('$_count'),
        isLabelVisible: _count > 0,
        backgroundColor: Colors.redAccent,
        child: _printing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.confirmation_number_outlined,
                size: 35,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.tertiaryContainer,
              ),
      ),
    );
  }
}
