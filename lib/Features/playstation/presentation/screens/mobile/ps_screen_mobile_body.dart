part of '../PS_Screen.dart';

/// جسم شاشة أجهزة البلايستيشن — نسخة الموبايل (زي ما كانت بالظبط).
extension _PsScreenMobileBody on _StaffDashboardState {

  Widget _buildMobileBody(BuildContext context) {
    final activeMap = _activeMap();
    return Scaffold(
      appBar: AppBar(title: Text('اجهزه'.tr())),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Stack(
          children: [
            BlurryBackgroundPage(),
            ListView.builder(
              itemCount: consoles.length,
              itemBuilder: (_, i) {
                final c = consoles[i];
                final active = activeMap[c.id];
                final isPaused = active != null && active['paused_at'] != null;

                return Card(
                  color: Colors.transparent,
                  elevation: 12,
                  shadowColor: Colors.black38,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  margin: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent.withOpacity(0.5),
                          Color(0xFF6FCF97).withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 30,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ░░ اسم الجهاز والسعر ░░
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.sports_esports,
                                    size: 32,
                                    color: Color(0xFF6FCF97),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  c.name,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              c.isFixedPrice
                                  ? '{v1} / سعر ماتش'.tr({'v1': c.fixedPrice.toStringAsFixed(2)})
                                  : '${c.pricePerHour.toStringAsFixed(2)} / ساعة',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        // ░░ شارة "متوقف مؤقتًا" — عشان محدش ينسى ويقفل الجلسة وهي واقفة ░░
                        if (isPaused) ...[
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.pause_circle_filled,
                                  size: 16,
                                  color: Colors.orange.shade800,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'الجلسة متوقفة مؤقتًا'.tr(),
                                  style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        SizedBox(height: 24),

                        // ░░ الحالة والأزرار ░░
                        active == null
                            ? Center(
                                child: ElevatedButton.icon(
                                  onPressed: () => _startSession(c),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 50,
                                    ),
                                    backgroundColor: Color(0xFF6FCF97),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 6,
                                  ),
                                  icon: Icon(
                                    Icons.play_arrow,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'ابدأ'.tr(),
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _consoleBtn(
                                    icon: Icons.local_drink,
                                    label: 'مشروبات'.tr(),
                                    color: Colors.blue,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddDrinksScreen(
                                            invoiceId: active['id'],
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // ⏸️ / ▶️ إيقاف واستئناف الوقت — غير متاح للجلسات
                                  // ذات السعر الثابت لأن وقتها مش بيتحسب أصلًا
                                  if (!c.isFixedPrice)
                                    (!isPaused
                                        ? _consoleBtn(
                                            icon: Icons.pause_circle_filled,
                                            label: 'إيقاف'.tr(),
                                            color: Colors.orange,
                                            onTap: () async {
                                              await DBHelper.pauseInvoice(
                                                active['id'],
                                              );
                                              await _load();
                                            },
                                          )
                                        : _consoleBtn(
                                            icon: Icons.play_circle_fill,
                                            label: 'استئناف'.tr(),
                                            color: Colors.green,
                                            onTap: () async {
                                              await DBHelper.resumeInvoice(
                                                active['id'],
                                              );
                                              await _load();
                                            },
                                          )),

                                  _consoleBtn(
                                    icon: Icons.stop_circle_outlined,
                                    label: 'إنهاء'.tr(),
                                    color: Colors.red,
                                    onTap: () => _endSession(active, c),
                                  ),
                                  _consoleBtn(
                                    icon: Icons.receipt_long,
                                    label: 'فاتورة'.tr(),
                                    color: Colors.deepPurple,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => InvoiceScreen(
                                            invoiceId: active['id'],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _consoleBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 80, // ارتفاع أكبر
            width: 80, // عرض متساوي للارتفاع → شكل مربع
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.6), color.withOpacity(0.3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 40, // أيقونة أكبر
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

