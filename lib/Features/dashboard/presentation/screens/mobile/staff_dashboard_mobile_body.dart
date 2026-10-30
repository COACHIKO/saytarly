part of '../staff_dashboard.dart';

/// جسم لوحة الكاشير — نسخة الموبايل (زي ما كانت بالظبط).
extension _StaffDashboardMobileBody on _StaffDashboardState {
  Widget _buildMobileBody(BuildContext context) {
    final List<Map<String, dynamic>> cards = [
      {
        'svgPath': 'assets/images/game-console-svgrepo-com.svg',
        'label': 'البلايستيشن',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => PsScreen(
                    staffName: widget.staffName,
                    shiftId: widget.shiftId,
                  ),
            ),
          );
        },
      },
      {
        'svgPath': 'assets/images/takeaway-coffee-svgrepo-com.svg',
        'label': 'تيك أواي',
        'onTap': _startTakeaway,
      },
      {
        'svgPath': 'assets/images/table-svgrepo-com2.svg',
        'label': 'الترابيزات',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => DrinksscreenDashboard(
                    staffName: widget.staffName,
                    shiftId: widget.shiftId,
                  ),
            ),
          );
        },
      },
      /* {
        'svgPath': 'assets/images/mobile-phone-signal-svgrepo-com.svg',
        'label': 'شحن رصيد',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => chargetop(
                shiftId: widget.shiftId,
              ),
            ),
          );
        },
      },*/
      {
        'svgPath': 'assets/images/money-svgrepo-com.svg',
        'label': 'إضافة مصروف',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => CashierExpensesScreen(
                    shiftId: widget.shiftId,
                    cashierName: widget.staffName,
                  ),
            ),
          );
        },
      },
      {
        'svgPath': 'assets/images/employees-svgrepo-com.svg',
        'label': 'شيفتات موظفين',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => SubStaffPage(
                    staffId: widget.staffId,
                    shiftId: widget.shiftId,
                    cashierName: widget.staffName,
                  ),
            ),
          );
        },
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('الكاشير - {v1}'.tr({'v1': widget.staffName})),
        actions: [
          const CardQueueIconButton(),
          /*  IconButton(
            tooltip: 'شيفتات موظفين',
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubStaffPage(
                    staffId: widget.staffId,
                    shiftId: widget.shiftId,
                    cashierName: widget.staffName,
                  ),
                ),
              );
            },
          ),*/
          IconButton(
            tooltip: 'عرض الفواتير الاجله'.tr(),
            icon: SvgPicture.asset(
              'assets/images/empty-wallet-add-svgrepo-com.svg',
              width: 40,
              height: 40,

              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.tertiaryContainer,

              // لو عايز تغير اللون
            ),
            onPressed: _showDebtorsSheet,
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/images/lock-protect-security-20-svgrepo-com.svg',
              width: 40,
              height: 40,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.tertiaryContainer,
              // لو عايز تغير اللون
            ),
            tooltip: 'قفل الشيفت'.tr(),
            onPressed: _confirmCloseShift,
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/images/sales-performance-svgrepo-com.svg',
              width: 40,
              height: 40,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.tertiaryContainer,
              // لو عايز تغير اللون
            ),
            splashRadius: 24,
            padding: EdgeInsets.all(12),
            color:
                Colors
                    .red, // ده بيأثر على Icon مش Svg، فممكن تستخدم Container بدل
            tooltip: 'عرض كل مبيعات'.tr(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => ShiftDetailsPage(
                        shiftId: widget.shiftId,
                        staffName: widget.staffName,
                        staffId: widget.staffId,
                      ),
                ),
              );
            },
          ),

          /*  IconButton(
            icon: Stack(
              children: [
                Icon(Icons.receipt_long),
                // بادج عدد الطلبات
                FutureBuilder<int>(
                  future: DBHelper.getPendingOrdersCount(),
                  builder: (_, snap) {
                    final count = snap.data ?? 0;
                    if (count == 0) return SizedBox();
                    return Positioned(
                      right: 0, top: 0,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text('$count',
                            style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    );
                  },
                ),
              ],
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CashierOrdersScreen(
                staffName: widget.staffName,
                shiftId: widget.shiftId,
                isAdmin: false,
              ),
            )),
          )
        */
          /*     IconButton(
            icon: SvgPicture.asset(
              'assets/images/sales-performance-svgrepo-com.svg',
              width: 40,
              height: 40,
              color: Theme.of(context).dividerColor,
              // لو عايز تغير اللون
            ),
            splashRadius: 24,
            padding: EdgeInsets.all(12),
            color: Colors
                .red, // ده بيأثر على Icon مش Svg، فممكن تستخدم Container بدل
            tooltip: 'عرض كل مبيعات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CashierOrdersScreen(
                          staffName: 'waled',
                          shiftId: 1,
                        )),
              );
            },
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/images/sales-performance-svgrepo-com.svg',
              width: 40,
              height: 40,
              color: Theme.of(context).dividerColor,
              // لو عايز تغير اللون
            ),
            splashRadius: 24,
            padding: EdgeInsets.all(12),
            color: Colors
                .red, // ده بيأثر على Icon مش Svg، فممكن تستخدم Container بدل
            tooltip: 'عرض كل مبيعات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => MenuScreen(
                          tableId: 1,
                          tableName: '1',
                        )),
              );
            },
          ),*/
          /*          IconButton(
            icon: const Icon(Icons.money),
            tooltip: 'إضافة مصروف',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CashierExpensesScreen(
                    shiftId: widget.shiftId,
                    cashierName: widget.staffName,
                  ),
                ),
              );
            },
          ), */
          /*   IconButton(
            icon: const Icon(Icons.money),
            tooltip: 'شحن',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => chargetop(),
                ),
              );
            },
          ),*/
        ],
      ),
      body: Stack(
        children: [
          BlurryBackgroundPage(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double width = constraints.maxWidth;
                int crossAxisCount;

                if (width < 400) {
                  crossAxisCount = 1;
                } else if (width < 800) {
                  crossAxisCount = 2;
                } else {
                  crossAxisCount = 3;
                }

                return GridView.builder(
                  shrinkWrap: true,
                  itemCount: cards.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 3,
                  ),
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return _buildCard(
                      svgPath: card['svgPath'] as String,
                      label: card['label'] as String,
                      onTap: card['onTap'] as VoidCallback,
                      width:
                          constraints.maxWidth /
                          crossAxisCount, // توزيع حسب عدد الأعمدة
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String svgPath,
    required String label,
    required VoidCallback onTap,
    required double width, // تمرير عرض الشاشة
  }) {
    // تحديد حجم الأيقونة والنص بناءً على عرض الشاشة
    double iconWidth = width * 0.3; // 30% من العرض
    double iconHeight = width * 0.07; // 7% من العرض
    double fontSize = width * 0.05; // 5% من العرض

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade300.withOpacity(0.5),
              Colors.green.shade600.withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              svgPath,
              width: iconWidth + 18,
              height: iconHeight + 14,
            ),
            SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
