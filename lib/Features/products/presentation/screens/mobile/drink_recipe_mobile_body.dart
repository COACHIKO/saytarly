part of '../drink_recipe.dart';

/// جسم وصفة المشروب — نسخة الموبايل (زي ما كانت بالظبط).
extension _DrinkRecipeScreenMobileBody on _DrinkRecipeScreenState {

  Widget buildRecipeSection() {
    if (recipeItems.isEmpty) {
      return  Card(
        margin: EdgeInsets.all(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'لا توجد خامات مضافة لهذا المشروب'.tr(),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child:  Text(
              'الوصفة الحالية'.tr(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const Divider(height: 1),
          ...recipeItems.map(
            (e) => ListTile(
              leading: const Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              title: Text(e['name']),
              subtitle: Text(
                "${e['qty']} ${e['unit']}",
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                onPressed: () => deleteRecipeItem(e['id']),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('وصفة المشروب'.tr()),
      ),
      body: Column(
        children: [
          buildRecipeSection(),
           Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'الخامات المتاحة'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: materials.length,
              itemBuilder: (_, i) {
                final m = materials[i];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.inventory_2),
                    ),
                    title: Text(m['name']),
                    subtitle: Text(
                      'المخزون: {v1} {v2}'.tr({'v1': m['qty'], 'v2': m['unit']}),
                    ),
                    trailing: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label:  Text('إضافة'.tr()),
                      onPressed: () => addRecipeMaterial(
                        m['id'],
                        m['name'],
                        m['unit'],
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

