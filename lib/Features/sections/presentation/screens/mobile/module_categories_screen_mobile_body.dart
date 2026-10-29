part of '../module_categories_screen.dart';

/// جسم شاشة القوائم الفرعية — نسخة الموبايل (زي ما كانت بالظبط).
extension _ModuleCategoriesMobileBody on _ModuleCategoriesScreenState {
  Widget _buildMobileBody(BuildContext context) {
    final m = widget.module;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(m.iconData, color: m.accentColor, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'قوائم قسم «{v1}»'.tr({'v1': m.name}),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label:  Text('قائمة جديدة'.tr()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ?  Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      ('لسه مفيش قوائم فرعية في القسم ده.\n'.tr() + 'ضيف قوائم زي «سخن / بارد / غازية» — وهتظهر كـ تابات جوه إدارة القسم وشاشة الكاشير.'.tr()),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                  itemCount: _rows.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return  Padding(
                        padding: EdgeInsets.fromLTRB(8, 4, 8, 12),
                        child: Text(
                          'القوائم دي بتظهر كـ تابات جوه إدارة القسم وفي شاشة الكاشير، وبترتب حسب اللي انت عايزه من الأزرار.'.tr(),
                          style: TextStyle(fontSize: 12.5, color: Colors.grey),
                        ),
                      );
                    }
                    final row = _rows[index - 1];
                    final i = index - 1;
                    final c = row.category;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: m.accentColor.withValues(alpha: 0.85),
                          child: Text(
                            c.name.characters.first,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          c.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '{v1} منتج'.tr({'v1': row.drinks}),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: c.isEnabled,
                              onChanged: (v) => _toggle(row, v),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                switch (v) {
                                  case 'edit':
                                    _openForm(edit: row);
                                    break;
                                  case 'up':
                                    _move(i, -1);
                                    break;
                                  case 'down':
                                    _move(i, 1);
                                    break;
                                  case 'delete':
                                    _delete(row);
                                    break;
                                }
                              },
                              itemBuilder: (_) =>  [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('تعديل الاسم'.tr()),
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
