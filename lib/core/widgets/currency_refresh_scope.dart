import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'package:saytarly/core/utils/money.dart';

/// Keeps every screen in sync with the business currency.
///
/// Changing the currency from settings or the setup wizard updates [Money]
/// immediately, but already-built routes/overlays keep their old text until
/// they rebuild. This scope listens to [Money.changes] and marks the whole
/// widget subtree dirty once per change, so open invoices, reports, dialogs
/// and printed previews all switch to the new symbol without a restart.
class CurrencyRefreshScope extends StatefulWidget {
  const CurrencyRefreshScope({super.key, required this.child});

  final Widget child;

  @override
  State<CurrencyRefreshScope> createState() => _CurrencyRefreshScopeState();
}

class _CurrencyRefreshScopeState extends State<CurrencyRefreshScope> {
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    Money.changes.addListener(_scheduleRefresh);
  }

  @override
  void dispose() {
    Money.changes.removeListener(_scheduleRefresh);
    super.dispose();
  }

  void _scheduleRefresh() {
    if (_pending) return;
    _pending = true;
    // scheduleFrameCallback requests a frame itself; a plain post-frame
    // callback would wait forever when the app is idle.
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _pending = false;
      if (!mounted) return;
      final root = WidgetsBinding.instance.rootElement;
      if (root == null) return;
      _markSubtree(root);
    });
  }

  /// Marks every active element dirty so its build method runs again and
  /// re-reads [Money.symbol]. Currency changes are rare, so the one full
  /// rebuild is cheaper than wiring a listener into every money widget.
  void _markSubtree(Element element) {
    if (!element.mounted) return;
    element.markNeedsBuild();
    element.visitChildren(_markSubtree);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
