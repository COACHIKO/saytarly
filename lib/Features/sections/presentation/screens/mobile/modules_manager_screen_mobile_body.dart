part of '../modules_manager_screen.dart';

/// جسم شاشة أقسام المنتجات — نسخة الموبايل (زي ما كانت بالظبط).
extension _ModulesManagerMobileBody on _ModulesManagerView {
  Widget _buildMobileBody(BuildContext context) {
    final cubit = context.watch<ModulesManagerCubit>();
    final viewModel = cubit.state;
    final rows = viewModel.rows;

    return Scaffold(
      appBar: AppBar(title:  Text('أقسام المنتجات'.tr())),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label:  Text('قسم جديد'.tr()),
      ),
      body: viewModel.loading
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
              ?  Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      ('لسه مفيش أقسام.\nاضغط «قسم جديد» وابدأ اعمل قسم زي «مشروبات» أو «ماكولات» — '.tr() + 'وهيطلع له تلقائي في لوحة الأدمن: إدارة + تقرير.'.tr()),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                  itemCount: rows.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return  Padding(
                        padding: EdgeInsets.fromLTRB(8, 4, 8, 12),
                        child: Text(
                          ('كل قسم بيظهر له تلقائي في لوحة الأدمن: إدارة القسم + تقرير القسم. '.tr() + 'والخامات مخزون مشترك بيظهر كارت واحد لكل الأقسام. '.tr() + 'اضغط على القسم عشان تضيف جواه قوائم فرعية (سخن/بارد/إلخ).'.tr()),
                          style: TextStyle(fontSize: 12.5, color: Colors.grey),
                        ),
                      );
                    }
                    final row = rows[index - 1];
                    final i = index - 1;
                    final m = row.module;
                    return Card(
                      child: ListTile(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ModuleCategoriesScreen(module: m),
                            ),
                          );
                          cubit.load();
                        },
                        leading: CircleAvatar(
                          backgroundColor: m.accentColor,
                          child: Icon(m.iconData, color: Colors.white),
                        ),
                        title: Text(
                          m.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '{v1} منتج • {v2} قائمة فرعية'.tr({'v1': row.drinks, 'v2': row.categories}),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: m.isEnabled,
                              onChanged: (v) => cubit.toggleModule(row, v),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                switch (v) {
                                  case 'edit':
                                    _openForm(context, edit: row);
                                    break;
                                  case 'up':
                                    cubit.move(i, -1);
                                    break;
                                  case 'down':
                                    cubit.move(i, 1);
                                    break;
                                  case 'delete':
                                    _delete(context, row);
                                    break;
                                }
                              },
                              itemBuilder: (_) =>  [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('تعديل'.tr()),
                                ),
                                PopupMenuItem(
                                  value: 'up',
                                  child: Text('تحريك لفوق'.tr()),
                                ),
                                PopupMenuItem(
                                  value: 'down',
                                  child: Text('تحريك لتحت'.tr()),
                                ),
                                PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('حذف'.tr()),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
