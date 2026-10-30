part of '../super_admin_dashboard.dart';

/// جسم لوحة السوبر ادمن — نسخة الموبايل (زي ما كانت بالظبط).
extension _SuperAdminMobileBody on _SuperAdminDashboardState {
  Widget _buildMobileBody(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لوحة السوبر ادمن'.tr(),
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            Text(
              _placeName,
              style: TextStyle(
                fontSize: 12,
                color: theme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          BlurryBackgroundPage(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.9,
              ),
              itemCount: _actions.length,
              itemBuilder: (context, index) {
                final action = _actions[index];
                return GestureDetector(
                  onTap: action['onTap'] as VoidCallback,
                  child: Card(
                    color: theme.surface.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.tealAccent.withOpacity(0.4),
                          width: 1.3,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            action['icon'] as IconData,
                            size: 40,
                            color: theme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (action['title'] as String).tr(),
                                  style: TextStyle(
                                    color: theme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (action['subtitle'] as String).tr(),
                                  style: TextStyle(
                                    color: theme.onSurface.withOpacity(0.6),
                                    fontSize: 11.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
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
