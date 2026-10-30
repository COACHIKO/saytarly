import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/models/app_modules.dart';
import 'package:saytarly/Features/sections/data/repositories/sections_repository.dart';
import 'package:saytarly/Features/sections/logic/cubit/modules_manager_cubit.dart';
import 'package:saytarly/Features/sections/presentation/screens/module_categories_screen.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/modules_manager_screen_mobile_body.dart';
part 'desktop/modules_manager_screen_windows_body.dart';

/// إدارة أقسام منتجات المطبخ (مشروبات، ماكولات، حلويات...)
/// كل قسم بيظهر له تلقائي في لوحة الأدمن: إدارة + تقرير
/// والخامات مخزون مشترك — كارت واحد لكل الأقسام
///
/// الشاشة عرض بس — كل المنطق في [ModulesManagerCubit].
class ModulesManagerScreen extends StatelessWidget {
  const ModulesManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ModulesManagerCubit()..load(),
      child: const _ModulesManagerView(),
    );
  }
}

class _ModulesManagerView extends StatelessWidget {
  const _ModulesManagerView();

  void _snack(BuildContext context, String msg, {bool error = false}) {
    AppToast.show(msg, kind: error ? FeedbackKind.error : FeedbackKind.info);
  }

  Future<void> _openForm(BuildContext context, {SectionModuleRow? edit}) async {
    final viewModel = context.read<ModulesManagerCubit>();
    final nameArCtl = TextEditingController(text: edit?.module.name ?? '');
    final nameEnCtl = TextEditingController(text: edit?.module.nameEn ?? '');
    String icon = edit?.module.icon ?? 'category';
    int color = edit?.module.color ?? ModuleColors.presets.first;
    String? validationError;

    final saved = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setDialogState) => AppDialog(
                  title: Text(
                    edit == null ? 'قسم جديد'.tr() : 'تعديل القسم'.tr(),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: nameArCtl,
                          autofocus: true,
                          textDirection: TextDirection.rtl,
                          onChanged: (_) {
                            if (validationError != null) {
                              setDialogState(() => validationError = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'الاسم بالعربي'.tr(),
                            hintText: 'مثال: مشروبات'.tr(),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: nameEnCtl,
                          textDirection: TextDirection.ltr,
                          onChanged: (_) {
                            if (validationError != null) {
                              setDialogState(() => validationError = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'الاسم بالإنجليزي'.tr(),
                            hintText: 'e.g. Drinks',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'اسم واحد على الأقل مطلوب — العربي أو الإنجليزي.'
                              .tr(),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        if (validationError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            validationError!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          'الأيقونة'.tr(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              ModuleIcons.presets.entries.map((e) {
                                final selected = icon == e.key;
                                return InkWell(
                                  onTap:
                                      () => setDialogState(() => icon = e.key),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          selected
                                              ? Color(
                                                color,
                                              ).withValues(alpha: 0.25)
                                              : Colors.black12,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color:
                                            selected
                                                ? Color(color)
                                                : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(e.value, size: 22),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'اللون'.tr(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              ModuleColors.presets.map((c) {
                                final selected = color == c;
                                return InkWell(
                                  onTap: () => setDialogState(() => color = c),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Color(c),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            selected
                                                ? Colors.white
                                                : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text('إلغاء'.tr()),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final ar = nameArCtl.text.trim();
                        final en = nameEnCtl.text.trim();
                        if (ar.isEmpty && en.isEmpty) {
                          setDialogState(
                            () =>
                                validationError =
                                    'اكتب اسم القسم بالعربي أو الإنجليزي'.tr(),
                          );
                          return;
                        }
                        Navigator.pop(dialogContext, true);
                      },
                      child: Text('حفظ'.tr()),
                    ),
                  ],
                ),
          ),
    );

    if (saved != true) return;
    final nameAr = nameArCtl.text.trim();
    final nameEn = nameEnCtl.text.trim();
    if (nameAr.isEmpty && nameEn.isEmpty) {
      _snack(context, 'اكتب اسم القسم بالعربي أو الإنجليزي'.tr(), error: true);
      return;
    }

    if (edit == null) {
      await viewModel.addModule(
        nameAr: nameAr,
        nameEn: nameEn,
        icon: icon,
        color: color,
      );
      _snack(context, 'تم إضافة القسم ✅'.tr());
    } else {
      await viewModel.editModule(
        id: edit.module.id!,
        nameAr: nameAr,
        nameEn: nameEn,
        icon: icon,
        color: color,
      );
      _snack(context, 'تم تعديل القسم ✅'.tr());
    }
  }

  Future<void> _delete(BuildContext context, SectionModuleRow row) async {
    final viewModel = context.read<ModulesManagerCubit>();

    if (!viewModel.canDelete(row)) {
      _snack(
        context,
        ('مش هينفع تحذف «{v1}» — فيه {v2} منتج. '.tr({
              'v1': row.module.displayName,
              'v2': row.drinks,
            }) +
            'انقلهم أو امسحهم الأول، أو اقفل القسم من الزرار.'.tr()),
        error: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AppDialog(
            title: Text('حذف القسم؟'.tr()),
            content: Text(
              'هيتحذف قسم «{v1}» وكل القوائم الفرعية اللي جواه.'.tr({
                'v1': row.module.displayName,
              }),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('إلغاء'.tr()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text('حذف'.tr()),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    await viewModel.deleteModule(row);
    _snack(context, 'تم حذف القسم'.tr());
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}
