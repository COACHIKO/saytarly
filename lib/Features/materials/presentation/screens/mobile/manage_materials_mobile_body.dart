part of '../manage_materials.dart';

/// جسم إدارة الخامات — نسخة الموبايل (زي ما كانت بالظبط).
extension _ManageMaterialsScreenMobileBody on _ManageMaterialsScreenState {

  Widget _buildMobileBody(BuildContext context) {
    final totalMaterials = materials.length;

    final lowStockCount = materials.where((e) {
      return (e['qty'] as num) <= (e['min_qty'] as num);
    }).length;

    return Scaffold(
      appBar: AppBar(
        title:  Text('إدارة الخامات'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث'.tr(),
            onPressed: () async {
              await load(); // ✅ التنظيف بقى جواها تلقائيًا
              if (mounted) {
                AppToast.show('✅ تم تحديث البيانات'.tr());
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'طباعة جرد الخامات'.tr(),
            onPressed: _printMaterialsInventory,
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'نسخة احتياطية'.tr(),
            onPressed: () => exportMaterials(context),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'استعادة نسخة'.tr(),
            onPressed: showImportMaterialsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.coffee_maker),
            tooltip: 'الاستهلاك'.tr(),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MaterialsInventoryScreen()),
              );
              load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'إضافة خامة'.tr(),
            onPressed: () => addOrEditMaterial(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      "$totalMaterials",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                     Text('إجمالي الخامات'.tr()),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "$lowStockCount",
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                     Text('خامات ناقصة'.tr()),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: materials.length,
              itemBuilder: (_, i) {
                final m = materials[i];

                final qty = (m['qty'] as num).toDouble();

                final minQty = (m['min_qty'] as num).toDouble();

                final lowStock = qty <= minQty;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: lowStock ? Colors.red : Colors.green,
                      child: Icon(
                        lowStock ? Icons.warning : Icons.check,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      m['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('المتاح : {v1} {v2}'.tr({'v1': m['qty'], 'v2': m['unit']})),
                        Text('الحد الأدنى : {v1}'.tr({'v1': m['min_qty']})),
                      ],
                    ),
                    trailing: SizedBox(
                      width: 110,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              addOrEditMaterial(material: m);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AppDialog(
                                  title:  Text('تأكيد الحذف'.tr()),
                                  content:  Text(
                                    'سيتم حذف الخامة من المخزون ومن جميع الوصفات المرتبطة بها'.tr(),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child:  Text('إلغاء'.tr()),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child:  Text('حذف'.tr()),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await deleteMaterial(m['id']);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

