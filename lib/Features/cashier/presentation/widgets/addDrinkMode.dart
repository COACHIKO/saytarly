import 'package:flutter/material.dart';
import 'package:saytarly/core/services/app_settings.dart';
import 'package:saytarly/core/desktop/widgets/desktop_feedback.dart';
import 'package:saytarly/core/localization/messages.dart';

class DrinksScreenModeButton extends StatefulWidget {
  const DrinksScreenModeButton({super.key});

  @override
  State<DrinksScreenModeButton> createState() => _DrinksScreenModeButtonState();
}

class _DrinksScreenModeButtonState extends State<DrinksScreenModeButton> {
  bool _selectedPosMode = false;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    _selectedPosMode = await AppSettings.getDrinksScreenPosMode();
    if (mounted) setState(() {});
  }

  Future<void> _changeMode(bool value) async {
    setState(() {
      _selectedPosMode = value;
    });

    await AppSettings.setDrinksScreenPosMode(value);

    if (!mounted) return;

    AppToast.show(
      value ? '✅ تم اختيار وضع الكاشير'.tr() : '✅ تم اختيار وضع القائمة'.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<bool>(
      tooltip: 'شكل شاشة إضافة المشروبات'.tr(),
      icon: Icon(
        _selectedPosMode ? Icons.grid_view_rounded : Icons.view_list_rounded,
      ),
      onSelected: _changeMode,
      itemBuilder:
          (_) => [
            PopupMenuItem(
              value: false,
              child: Row(
                children: [
                  if (!_selectedPosMode)
                    const Icon(Icons.check, color: Colors.green),
                  if (!_selectedPosMode) const SizedBox(width: 8),
                  const Icon(Icons.view_list_rounded),
                  const SizedBox(width: 10),
                  Text('قائمة'.tr()),
                ],
              ),
            ),
            PopupMenuItem(
              value: true,
              child: Row(
                children: [
                  if (_selectedPosMode)
                    const Icon(Icons.check, color: Colors.green),
                  if (_selectedPosMode) const SizedBox(width: 8),
                  const Icon(Icons.grid_view_rounded),
                  const SizedBox(width: 10),
                  Text('كاشير'.tr()),
                ],
              ),
            ),
          ],
    );
  }
}
