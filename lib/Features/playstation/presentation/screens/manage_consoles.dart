import 'package:flutter/material.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/models/models.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/manage_consoles_mobile_body.dart';
part 'desktop/manage_consoles_windows_body.dart';

class ManageConsolesScreen extends StatefulWidget {
  @override
  State<ManageConsolesScreen> createState() => _ManageConsolesScreenState();
}

class _ManageConsolesScreenState extends State<ManageConsolesScreen> {
  List<ConsoleModel> consoles = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DBHelper.getAllConsoles();
    if (!mounted) return;
    setState(
      () => consoles = rows.map((r) => ConsoleModel.fromMap(r)).toList(),
    );
  }

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

  /*
  void _showForm({ConsoleModel? edit}) {
    final nameCtl = TextEditingController(text: edit?.name ?? '');
    final priceCtl = TextEditingController(
        text: edit != null ? edit.pricePerHour.toString() : '');

    showDialog(
      context: context,
      builder: (_) => AppDialog(
        title: Text(edit == null ? 'إضافة جهاز' : 'تعديل جهاز'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: nameCtl,
              decoration: InputDecoration(labelText: 'اسم الجهاز')),
          TextField(
              controller: priceCtl,
              decoration: InputDecoration(labelText: 'سعر الساعة'),
              keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('إلغاء')),
          ElevatedButton(
              onPressed: () async {
                final n = nameCtl.text.trim();
                final p = double.tryParse(priceCtl.text.trim()) ?? 0;
                if (edit == null) {
                  await DBHelper.insertConsole(
                      ConsoleModel(name: n, pricePerHour: p));
                } else {
                  edit.name = n;
                  edit.pricePerHour = p;
                  await DBHelper.updateConsole(edit);
                }
                Navigator.pop(context);
                _load();
              },
              child: Text('حفظ'))
        ],
      ),
    );
  }
*/
  void _showForm({ConsoleModel? edit}) {
    final nameCtl = TextEditingController(text: edit?.name ?? '');
    final priceCtl = TextEditingController(
      text: edit != null ? edit.pricePerHour.toString() : '',
    );
    bool isFixedPrice = edit?.isFixedPrice ?? false;
    final fixedPriceCtl = TextEditingController(
      text: edit != null ? edit.fixedPrice.toString() : '',
    );

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => AppDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  titlePadding: EdgeInsets.zero,
                  title: Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          edit == null ? Icons.sports_esports : Icons.edit,
                          color: Colors.white,
                        ),
                        SizedBox(width: 10),
                        Text(
                          edit == null ? 'إضافة جهاز'.tr() : "تعديل جهاز".tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  content: SizedBox(
                    width: 500,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: nameCtl,
                            decoration: InputDecoration(
                              labelText: 'اسم الجهاز'.tr(),
                              prefixIcon: Icon(Icons.videogame_asset),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Card(
                            elevation: 0,
                            color: Theme.of(context).colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: priceCtl,
                                      keyboardType: TextInputType.number,
                                      enabled: !isFixedPrice,
                                      decoration: InputDecoration(
                                        labelText: 'سعر الساعة'.tr(),
                                        prefixIcon: Icon(Icons.timer),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Checkbox(
                                    value: isFixedPrice,
                                    onChanged: (v) {
                                      setState(() {
                                        isFixedPrice = v!;

                                        if (isFixedPrice) {
                                          priceCtl.text = '0';
                                        } else {
                                          priceCtl.clear();
                                        }
                                      });
                                    },
                                  ),
                                  Text(
                                    'سعر ثابت'.tr(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child:
                                isFixedPrice
                                    ? Padding(
                                      padding: const EdgeInsets.only(top: 15),
                                      child: TextField(
                                        controller: fixedPriceCtl,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'السعر الثابت'.tr(),
                                          prefixIcon: Icon(Icons.attach_money),
                                        ),
                                      ),
                                    )
                                    : const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actionsPadding: const EdgeInsets.all(15),
                  actions: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: Text('إلغاء'.tr()),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: Text('حفظ'.tr()),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 45),
                      ),
                      onPressed: () async {
                        final n = nameCtl.text.trim();
                        final p = double.tryParse(priceCtl.text.trim()) ?? 0;
                        final fixedP =
                            double.tryParse(fixedPriceCtl.text.trim()) ?? 0;

                        if (edit == null) {
                          await DBHelper.insertConsole(
                            ConsoleModel(
                              name: n,
                              pricePerHour: p,
                              isFixedPrice: isFixedPrice,
                              fixedPrice: fixedP,
                            ),
                          );
                        } else {
                          edit.name = n;
                          edit.pricePerHour = p;
                          edit.isFixedPrice = isFixedPrice;
                          edit.fixedPrice = fixedP;

                          await DBHelper.updateConsole(edit);
                        }

                        Navigator.pop(context);
                        _load();
                      },
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  // 1️⃣ متغير حالة في الـ StatefulWidget
  int? selectedConsoleId;

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}
