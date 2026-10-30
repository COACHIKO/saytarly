part of '../admin.dart';

/// جسم لوحة الأدمن — نسخة الموبايل (بكل التصميمات الثلاثة زي ما كانت).
extension _AdminMobileBody on _AdminDashboardState {
  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _placeName,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip:
                _showStats ? 'إخفاء الإحصائيات'.tr() : 'إظهار الإحصائيات'.tr(),
            icon: Icon(
              _showStats
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () => _refresh(() => _showStats = !_showStats),
          ),
          PopupMenuButton<DashStyle>(
            tooltip: 'تغيير شكل اللوحة'.tr(),
            icon: const Icon(Icons.palette_outlined),
            initialValue: _style,
            onSelected: _changeStyle,
            itemBuilder:
                (context) => [
                  _styleMenuItem(
                    DashStyle.current,
                    'التصميم الحالي'.tr(),
                    Icons.dashboard_customize_outlined,
                  ),
                  _styleMenuItem(
                    DashStyle.warmCafe,
                    'كافيه دافئ'.tr(),
                    Icons.local_cafe_outlined,
                  ),
                  _styleMenuItem(
                    DashStyle.professional,
                    'لوحة احترافية'.tr(),
                    Icons.dashboard_outlined,
                  ),
                ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: FilledButton.tonalIcon(
              onPressed: _clearAllData,
              icon: Icon(Icons.delete_outline),
              label: Text('مسح'.tr()),
              style: FilledButton.styleFrom(
                foregroundColor: Colors.red,
                backgroundColor: Colors.red.withOpacity(.1),
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
      body:
          _style == DashStyle.current
              ? _buildCurrentBody()
              : _style == DashStyle.warmCafe
              ? _buildWarmCafeBody()
              : _buildProfessionalBody(),
    );
  }

  PopupMenuItem<DashStyle> _styleMenuItem(
    DashStyle value,
    String label,
    IconData icon,
  ) {
    final selected = _style == value;
    final primary = Theme.of(context).colorScheme.primary;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: selected ? primary : null),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? primary : null,
            ),
          ),
          if (selected) ...[
            const Spacer(),
            Icon(Icons.check, size: 16, color: primary),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // STYLE 1 — the existing look (dark blurred background,
  // purple-bordered glass cards). Unchanged behaviour.
  // =========================================================
  Widget _buildCurrentBody() {
    return Stack(
      children: [
        BlurryBackgroundPage(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2,
            ),
            itemCount: _actions.length,
            itemBuilder: (context, index) {
              final action = _actions[index];
              return _actionCardCurrent(
                (action['title'] as String).tr(),
                action['icon'] as IconData,
                action['color'] as Color,
                action['onTap'] as VoidCallback,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _actionCardCurrent(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: theme.surface.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.deepPurple.withOpacity(0.8),
              width: 1.3,
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: theme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // STYLE 2 — Warm Cafe (cream background, coffee tones)
  // =========================================================
  Widget _buildWarmCafeBody() {
    const bg = Color(0xFFF6EFE4);
    const card = Color(0xFFFFFAF0);
    const ink = Color(0xFF3F2C1A);
    const sub = Color(0xFFA3907A);
    const border = Color(0xFFE6D9C2);

    return Container(
      color: bg,
      child: SafeArea(
        child: Column(
          children: [
            if (_showStats)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _warmStat(
                        'عدد الفواتير'.tr(),
                        sessionsCount.toString(),
                        card,
                        ink,
                        sub,
                        border,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _warmStat(
                        'إجمالي الدخل'.tr(),
                        '${incomeToday.toStringAsFixed(2)} ${Money.txt}',
                        card,
                        ink,
                        sub,
                        border,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(20, _showStats ? 8 : 16, 20, 12),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                itemCount: _actions.length,
                itemBuilder: (context, index) {
                  final action = _actions[index];
                  return _warmCard(
                    (action['title'] as String).tr(),
                    action['icon'] as IconData,
                    action['color'] as Color,
                    action['onTap'] as VoidCallback,
                    card,
                    ink,
                    border,
                  );
                },
              ),
            ),
            _creditFooterLight(sub),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _warmStat(
    String title,
    String value,
    Color card,
    Color ink,
    Color sub,
    Color border,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: sub)),
        ],
      ),
    );
  }

  Widget _warmCard(
    String title,
    IconData icon,
    Color accent,
    VoidCallback onTap,
    Color card,
    Color ink,
    Color border,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withOpacity(.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // STYLE 3 — Professional (sidebar on wide screens, falls
  // back to a plain grid on phones)
  // =========================================================
  Widget _buildProfessionalBody() {
    const bgMain = Color(0xFFF4F6FB);
    const sidebarBg = Color(0xFF14162B);
    const accent = Color(0xFF4F5BD5);

    return Container(
      color: bgMain,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showSidebar = constraints.maxWidth > 820;

            final mainCol = Column(
              children: [
                if (_showStats)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _proStat(
                            'عدد الفواتير'.tr(),
                            sessionsCount.toString(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _proStat(
                            'إجمالي الدخل'.tr(),
                            '${incomeToday.toStringAsFixed(2)} ${Money.txt}',
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 260,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.6,
                    ),
                    itemCount: _actions.length,
                    itemBuilder: (context, index) {
                      final action = _actions[index];
                      return _proCard(
                        (action['title'] as String).tr(),
                        action['icon'] as IconData,
                        action['color'] as Color,
                        action['onTap'] as VoidCallback,
                      );
                    },
                  ),
                ),
                _creditFooterLight(const Color(0xFF8A90AB)),
                const SizedBox(height: 8),
              ],
            );

            if (!showSidebar) return mainCol;

            return Row(
              children: [
                Container(
                  width: 210,
                  color: sidebarBg,
                  padding: const EdgeInsets.symmetric(
                    vertical: 22,
                    horizontal: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                        child: Text(
                          '☕ $_placeName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      _sidebarItem('🏠 الرئيسية'.tr(), true, accent, null),
                      _sidebarItem(
                        '📊 التقارير'.tr(),
                        false,
                        accent,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ReportsScreen()),
                        ),
                      ),
                      _sidebarItem(
                        '🎮 الأجهزة'.tr(),
                        false,
                        accent,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ManageConsolesScreen(),
                          ),
                        ),
                      ),
                      _sidebarItem(
                        '👤 المستخدمين'.tr(),
                        false,
                        accent,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ManageUsersScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: mainCol),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sidebarItem(
    String label,
    bool active,
    Color accent,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFFB6BAD0),
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }

  Widget _proStat(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2033),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8A90AB)),
          ),
        ],
      ),
    );
  }

  Widget _proCard(
    String title,
    IconData icon,
    Color accent,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2033),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shared small brand line used by the two light styles.
  Widget _creditFooterLight(Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        'SAYTARLY',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
