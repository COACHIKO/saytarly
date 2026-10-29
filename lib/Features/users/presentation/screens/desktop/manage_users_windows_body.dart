part of '../manage_users.dart';

/// جسم شاشة إدارة المستخدمين — نسخة الويندوز (Windows UI).
///
/// نفس الشاشة ونفس المنطق: صف لكل مستخدم بكارت عليه هوفر، وسم الدور
/// بجانب الاسم، وأزرار (الموظفين الفرعيين / تعديل / حذف) بنفس الـ callbacks
/// — وزرار "إضافة مستخدم" في هيدر الصفحة. مع بحث سريع في الأسماء.
extension _ManageUsersScreenWindowsBody on _ManageUsersScreenState {
  /// فلترة الأسماء حسب كلمة البحث (عرض بس — نفس مصدر بيانات الموبايل).
  List<Map<String, dynamic>> get _windowsFilteredUsers {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return users;
    return users
        .where(
          (u) => (u['username'] as String? ?? '')
              .toLowerCase()
              .contains(query),
        )
        .toList();
  }

  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final filtered = _windowsFilteredUsers;

    return DesktopPageScaffold(
      title: 'إدارة المستخدمين'.tr(),
      subtitle: '{v1} مستخدم — أدوار وإعدادات الرواتب'.tr({'v1': users.length}),
      actions: [
        DesktopButton.primary(
          label: 'إضافة مستخدم'.tr(),
          icon: Icons.person_add_alt_1_outlined,
          onPressed: () => _showForm(),
        ),
      ],
      child: users.isEmpty
          ? DesktopEmptyState(
              icon: Icons.group_off_outlined,
              title: 'مفيش مستخدمين'.tr(),
              message: 'ضيف أول مستخدم وحدّد دوره وإعدادات راتبه.'.tr(),
              action: DesktopButton.primary(
                label: 'إضافة مستخدم'.tr(),
                icon: Icons.person_add_alt_1_outlined,
                onPressed: () => _showForm(),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesktopSectionTitle(
                  title: 'المستخدمون'.tr(),
                  count: filtered.length,
                  trailing: DesktopSearchField(
                    hint: 'ابحث باسم المستخدم...'.tr(),
                    onChanged: (v) => _refresh(() => _searchQuery = v),
                  ),
                ),
                if (filtered.isEmpty)
                  DesktopEmptyState(
                    icon: Icons.search_off,
                    title: 'مفيش نتائج'.tr(),
                    message: 'جرّب اسم تاني — أو امسح كلمة البحث.'.tr(),
                  )
                else
                  for (final u in filtered) _muUserRow(context, palette, u),
              ],
            ),
    );
  }

  /// صف مستخدم — نفس بيانات صف الموبايل + وسوم الدور والراتب.
  Widget _muUserRow(
    BuildContext context,
    DesktopPalette palette,
    Map<String, dynamic> u,
  ) {
    final theme = Theme.of(context);
    final role = u['role'] as String? ?? '';

    final roleColor = switch (role) {
      'admin' => palette.accent,
      'cashier' => palette.success,
      'waiter' => palette.warning,
      _ => palette.textSecondary,
    };
    final roleIcon = switch (role) {
      'admin' => Icons.admin_panel_settings_outlined,
      'cashier' => Icons.point_of_sale_outlined,
      'waiter' => Icons.room_service_outlined,
      _ => Icons.person_outline,
    };
    final roleLabel = switch (role) {
      'admin' => 'أدمن'.tr(),
      'cashier' => 'كاشير — مدير الصالة'.tr(),
      'waiter' => 'موظف طلبات'.tr(),
      _ => role,
    };
    final supervisorNames = {
      for (final w in users)
        if (w['id'] != null) w['id']! as int: w['username'] as String? ?? '',
    };
    final supervisorName =
        u['supervisor_id'] == null ? null : supervisorNames[u['supervisor_id']];

    return DesktopCard(
      hover: true,
      margin:  EdgeInsets.only(bottom: DesktopTokens.gapSm + 2),
      child: Row(
        children: [
          DesktopIconBadge(
            icon: roleIcon,
            color: roleColor,
            size: 44,
            radius: DesktopTokens.radiusMd,
          ),
           SizedBox(width: DesktopTokens.gapMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u['username'] as String? ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
                 SizedBox(height: 5),
                Wrap(
                  spacing: DesktopTokens.gapXs,
                  runSpacing: DesktopTokens.gapXs,
                  children: [
                    DesktopInfoChip(
                      label: roleLabel,
                      icon: roleIcon,
                      color: roleColor,
                      dense: true,
                    ),
                    if (supervisorName != null)
                      DesktopInfoChip(
                        label: 'موظف فرعي عند {supervisorName}'.tr({'supervisorName': supervisorName}),
                        icon: Icons.link,
                        color: palette.info,
                        dense: true,
                      ),
                    if (_roleHasSalary(role))
                      DesktopInfoChip(
                        label:
                            'الراتب بالساعة: {v1}'.tr({'v1': u['salary_per_hour'] ?? 'غير محدد'.tr()}),
                        icon: Icons.payments_outlined,
                        color: palette.info,
                        dense: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (role == 'admin' || role == 'cashier')
            DesktopToolbarIconButton(
              icon: Icons.group_outlined,
              tooltip: 'تعيين الويترات كموظفين فرعيين'.tr(),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubStaffScreen(supervisorId: u['id']),
                  ),
                );
              },
            ),
          DesktopToolbarIconButton(
            icon: Icons.edit_outlined,
            tooltip: 'تعديل المستخدم'.tr(),
            onPressed: () => _showForm(edit: u),
          ),
          DesktopToolbarIconButton(
            icon: Icons.delete_outline,
            tooltip: 'حذف المستخدم'.tr(),
            onPressed: () => _confirmDeleteUser(u['id'], u['username']),
          ),
        ],
      ),
    );
  }
}
