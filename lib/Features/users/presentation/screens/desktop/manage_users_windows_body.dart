part of '../manage_users.dart';

/// جسم شاشة إدارة المستخدمين — نسخة الويندوز 🌿
///
/// بدل قائمة مستخدمين صلبة، الشاشة بترجع شجرة حقيقية: الكاشير (والأدمن)
/// جذور، وموظف الطلبات ورقة متفرعة من الجذر اللي بيشتغل تحته بخط اتصال
/// مرسوم فعلًا. نفس الموظف يقدر يشتغل تحت كاشيرين في نفس الوقت — فيظهر
/// كورقة تحت كل واحد، وشارة صغيرة توضح إن له فروع تانية عند كاشير تاني.
extension _ManageUsersScreenWindowsBody on _ManageUsersScreenState {
  /// الجذور بعد فلترة البحث — لو الجذر مش مطابق، بندخل أوراقه المطابقة.
  List<Map<String, dynamic>> get _branchRoots {
    final query = _searchQuery.trim().toLowerCase();
    final roots = users.where((u) => _isBranchRole(u['role'])).toList();
    if (query.isEmpty) return roots;

    final out = <Map<String, dynamic>>[];
    for (final root in roots) {
      final name = (root['username'] as String? ?? '').toLowerCase();
      if (name.contains(query)) {
        out.add(root);
        continue;
      }
      final matched = _childrenOfUser(root).where(
        (c) => (c['username'] as String? ?? '').toLowerCase().contains(query),
      );
      if (matched.isNotEmpty) out.add(root);
    }
    return out;
  }

  /// أطفال جذر بعد فلترة البحث.
  List<Map<String, dynamic>> _childrenForBranch(Map<String, dynamic> root) {
    final query = _searchQuery.trim().toLowerCase();
    final children = _childrenOfUser(root);
    if (query.isEmpty) return children;
    final rootMatches = (root['username'] as String? ?? '')
        .toLowerCase()
        .contains(query);
    if (rootMatches) return children;
    return children
        .where(
          (c) => (c['username'] as String? ?? '').toLowerCase().contains(query),
        )
        .toList();
  }

  /// الويترات المستقلة بعد فلترة البحث.
  List<Map<String, dynamic>> get _independentForSearch {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _independentStaff;
    return _independentStaff
        .where(
          (c) => (c['username'] as String? ?? '').toLowerCase().contains(query),
        )
        .toList();
  }

  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final roots = _branchRoots;
    final independents = _independentForSearch;
    final searched = _searchQuery.trim().isNotEmpty;
    final isEmpty =
        users.isEmpty || (searched && roots.isEmpty && independents.isEmpty);

    return DesktopPageScaffold(
      title: 'إدارة المستخدمين'.tr(),
      subtitle:
          'شجرة الفريق — {v1} جذر • موظف الطلبات يقدر يشتغل تحت أكتر من كاشير'
              .tr({'v1': '${roots.length}'}),
      actions: [
        DesktopButton.primary(
          label: 'إضافة مستخدم'.tr(),
          icon: Icons.person_add_alt_1_outlined,
          onPressed: () => _showForm(),
        ),
      ],
      child:
          isEmpty
              ? DesktopEmptyState(
                icon: Icons.account_tree_rounded,
                title: 'شجرة الفريق لسه فاضية'.tr(),
                message:
                    'ابدأ بأول كاشير — وبعده اسحب أي موظف وأفلته على أي جذر يلحّقه تحته مباشرة 🤏'
                        .tr(),
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
                    title: 'شجرة الفريق'.tr(),
                    count: users.length,
                    trailing: DesktopSearchField(
                      hint: 'ابحث باسم المستخدم...'.tr(),
                      onChanged: (v) => _refresh(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(height: DesktopTokens.gapSm),
                  // 🔑 لوحة مفتاح صغيرة تشرح ألوان وأفرع الشجرة.
                  _muLegend(context, palette),
                  const SizedBox(height: DesktopTokens.gapMd),
                  if (roots.isEmpty)
                    // مفيش جذور (أو البحث) — نعرض المستقلين على طول
                    for (var i = 0; i < independents.length; i++)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(bottom: 8),
                        child: _muIndependentTile(
                          context,
                          palette,
                          independents[i],
                        ),
                      )
                  else
                    for (final root in roots) ...[
                      _muBranchNode(context, palette, root),
                      const SizedBox(height: DesktopTokens.gapMd),
                    ],
                  if (independents.isNotEmpty) ...[
                    _muIndependentSection(context, palette, independents),
                    const SizedBox(height: DesktopTokens.gapMd),
                  ],
                ],
              ),
    );
  }

  /// لوحة مفتاح صغيرة بتوضيح لغات الشجرة.
  Widget _muLegend(BuildContext context, DesktopPalette palette) {
    final theme = Theme.of(context);
    final legend = <(IconData, Color, String)>[
      (Icons.admin_panel_settings_outlined, palette.accent, 'جذر الإدارة'.tr()),
      (Icons.point_of_sale_outlined, palette.success, 'جذر الصالة'.tr()),
      (Icons.room_service_outlined, palette.warning, 'موظف طلبات متفرّع'.tr()),
      (
        Icons.swipe_down_alt_rounded,
        palette.info,
        'اسحب الموظف وأفلته على أي جذر 🤏'.tr(),
      ),
    ];
    return Wrap(
      spacing: DesktopTokens.gapSm,
      runSpacing: 6,
      children: [
        for (final (icon, color, label) in legend)
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// عقدة جذر قابلة لاستقبال السحب — إفلت الويتر عليها فيعتصق تحت الجذر 🌿
  Widget _muBranchNode(
    BuildContext context,
    DesktopPalette palette,
    Map<String, dynamic> root,
  ) {
    final rootId = _userId(root);
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails:
          (d) =>
              (d.data['role'] as String? ?? '') == 'waiter' &&
              _userId(d.data) != rootId,
      onAcceptWithDetails: (d) => _attachWaiterToSupervisor(d.data, root),
      builder: (context, candidateData, rejectedData) {
        final dragging = candidateData.isNotEmpty;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _muBranchCard(context, palette, root),
            if (dragging) ...[
              // ✔ هالة نيون تحوّل الجذر لهدف حي وقت المرور
              // الهالة بتتوسّع 2px برة حدود الكارت (Positioned سالب) —
              // negative margin مرفوض في Container وبيطلق assert.
              Positioned(
                top: -2,
                right: -2,
                bottom: -2,
                left: -2,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.warning.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: palette.warning.withValues(alpha: 0.9),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              // ✔ شريط الدعوة للإسقاط بيبان تجاه قاع الكارت
              IgnorePointer(
                child: Align(
                  alignment: AlignmentDirectional.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: palette.warning,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: palette.warning.withValues(alpha: 0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.south_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'أفلت للتفرّع تحت {u} 🌿'.tr({
                              'u': root['username'] ?? '',
                            }),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// كارت الجذر نفسه — كاشير أو أدمن مع أوراقه المتفرعة منه.
  Widget _muBranchCard(
    BuildContext context,
    DesktopPalette palette,
    Map<String, dynamic> root,
  ) {
    final theme = Theme.of(context);
    final role = root['role'] as String? ?? '';
    final rootId = _userId(root);
    final children = _childrenForBranch(root);

    final roleColor = role == 'admin' ? palette.accent : palette.success;
    final roleIcon =
        role == 'admin'
            ? Icons.admin_panel_settings_outlined
            : Icons.point_of_sale_outlined;
    final roleLabel =
        role == 'admin'
            ? 'أدمن — مدير النظام'.tr()
            : 'كاشير — مدير الصالة'.tr();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: roleColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: roleColor.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== رأس الجذر ====================
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  DesktopIconBadge(
                    icon: roleIcon,
                    color: roleColor,
                    size: 46,
                    radius: DesktopTokens.radiusMd,
                  ),
                  if (children.isNotEmpty)
                    Positioned(
                      top: -5,
                      left: -5,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: roleColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.surface, width: 2),
                        ),
                        child: Text(
                          '${children.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: DesktopTokens.gapMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      root['username'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 5),
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
                        if (_roleHasSalary(role))
                          DesktopInfoChip(
                            label: 'الراتب بالساعة: {v1}'.tr({
                              'v1': root['salary_per_hour'] ?? 'غير محدد'.tr(),
                            }),
                            icon: Icons.payments_outlined,
                            color: palette.info,
                            dense: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              DesktopToolbarIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'تعديل المستخدم'.tr(),
                onPressed: () => _showForm(edit: root),
              ),
              DesktopToolbarIconButton(
                icon: Icons.delete_outline,
                tooltip: 'حذف المستخدم'.tr(),
                onPressed:
                    () => _confirmDeleteUser(root['id'], root['username']),
              ),
            ],
          ),
          // ==================== أوراق الشجرة ====================
          if (children.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < children.length; i++)
              _muLeafRow(
                context,
                palette,
                children[i],
                root,
                first: i == 0,
                last: i == children.length - 1,
              ),
          ],
        ],
      ),
    );
  }

  /// ورقة شجرة قابلة للسحب — اسحبها واقفلها على أي جذر تاني 🌿
  Widget _muLeafRow(
    BuildContext context,
    DesktopPalette palette,
    Map<String, dynamic> leaf,
    Map<String, dynamic>? parent, {
    required bool first,
    required bool last,
  }) {
    return Draggable<Map<String, dynamic>>(
      data: leaf,
      maxSimultaneousDrags: 1,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _muLeafFeedbackCard(context, palette, leaf),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _muLeafRowCore(
          context,
          palette,
          leaf,
          parent,
          first: first,
          last: last,
        ),
      ),
      child: _muLeafRowCore(
        context,
        palette,
        leaf,
        parent,
        first: first,
        last: last,
      ),
    );
  }

  /// 🎯 الكارت الطاير اللي يطير مع إصبعك وقت السحب — نسخة مصغّرة من الورقة
  /// ببت دوران بسيط وشادّة ظل، بتخلي السحب حيّ من أول لحظة.
  Widget _muLeafFeedbackCard(
    BuildContext context,
    DesktopPalette palette,
    Map<String, dynamic> leaf,
  ) {
    final supervisors = _supervisorNamesOf(leaf);
    return Transform.rotate(
      angle: -0.035,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: palette.warning.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: palette.warning.withValues(alpha: 0.45),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.room_service_outlined,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                leaf['username'] as String? ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '×${supervisors.length + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ورقة شجرة — موظف طلبات تحت جذر مع خط اتصال جميل.
  Widget _muLeafRowCore(
    BuildContext context,
    DesktopPalette palette,
    Map<String, dynamic> leaf,
    Map<String, dynamic>? parent, {
    required bool first,
    required bool last,
  }) {
    final theme = Theme.of(context);
    final waiterColor = palette.warning;
    final supervisors = _supervisorNamesOf(leaf);
    final extraParents = supervisors.length - (parent == null ? 0 : 1);

    return IntrinsicHeight(
      child: Row(
        children: [
          // ╭ خط الاتصال الرأسي والأفقي بتاع الشجرة
          SizedBox(
            width: 26,
            child: CustomPaint(
              size: const Size(26, 46),
              painter: _TreeBranchPainter(
                color: waiterColor.withValues(alpha: 0.66),
                first: first,
                last: last,
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsetsDirectional.only(bottom: 6),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: waiterColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: waiterColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: waiterColor.withValues(alpha: 0.16),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.room_service_outlined,
                      size: 16,
                      color: waiterColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          leaf['username'] as String? ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        if (_roleHasSalary(leaf['role'])) ...[
                          const SizedBox(height: 2),
                          Text(
                            'الراتب بالساعة: {v1}'.tr({
                              'v1': leaf['salary_per_hour'] ?? 'غير محدد'.tr(),
                            }),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.textSecondary,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (extraParents > 0)
                    Tooltip(
                      message: 'مرتبط كمان عند: {v1}'.tr({
                        'v1': supervisors
                            .where((n) => n != (parent?['username'] ?? ''))
                            .join('، '.tr()),
                      }),
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: palette.info.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.call_split_rounded,
                              size: 12,
                              color: palette.info,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '+$extraParents',
                              style: TextStyle(
                                color: palette.textSecondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  if (parent != null)
                    DesktopToolbarIconButton(
                      icon: Icons.link_off_rounded,
                      tooltip: 'فصله من عند {u}'.tr({
                        'u': parent['username'] ?? '',
                      }),
                      onPressed: () => _detachFromSupervisor(leaf, parent),
                    ),
                  DesktopToolbarIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'تعديل المستخدم'.tr(),
                    onPressed: () => _showForm(edit: leaf),
                  ),
                  DesktopToolbarIconButton(
                    icon: Icons.delete_outline,
                    tooltip: 'حذف المستخدم'.tr(),
                    onPressed:
                        () => _confirmDeleteUser(leaf['id'], leaf['username']),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة مستقل قابلة للسحب — من "بلا جذر" لأي جذر بالإفلات 🌿
  Widget _muIndependentTile(
    BuildContext context,
    DesktopPalette palette,
    Map<String, dynamic> leaf,
  ) {
    return Draggable<Map<String, dynamic>>(
      data: leaf,
      maxSimultaneousDrags: 1,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _muLeafFeedbackCard(context, palette, leaf),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _muIndependentTileCore(context, palette, leaf),
      ),
      child: _muIndependentTileCore(context, palette, leaf),
    );
  }

  /// بطاقة مستقل — موظف طلبات من غير جذر (بيظهر لما يتحط جوّه قسم المستقلين).
  Widget _muIndependentTileCore(
    BuildContext context,
    DesktopPalette palette,
    Map<String, dynamic> leaf,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.airline_seat_recline_extra_rounded,
            size: 18,
            color: palette.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              leaf['username'] as String? ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 4),
          DesktopToolbarIconButton(
            icon: Icons.edit_outlined,
            tooltip: 'تعديل المستخدم'.tr(),
            onPressed: () => _showForm(edit: leaf),
          ),
          DesktopToolbarIconButton(
            icon: Icons.delete_outline,
            tooltip: 'حذف المستخدم'.tr(),
            onPressed: () => _confirmDeleteUser(leaf['id'], leaf['username']),
          ),
        ],
      ),
    );
  }

  /// قسم المستقلين — موظفي الطلبات اللي شغالين بلا جذر.
  Widget _muIndependentSection(
    BuildContext context,
    DesktopPalette palette,
    List<Map<String, dynamic>> independents,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: palette.textMuted.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.airline_seat_recline_extra_rounded,
                  size: 18,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'فريق مستقل — موظفين شغالين بلا مشرف'.tr(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'دول موظفين مستقلين — من شاشة تعديل أي واحد منهم تقدر ترجعه لجذر في أي وقت.'
                          .tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < independents.length; i++)
            _muIndependentTile(context, palette, independents[i]),
        ],
      ),
    );
  }
}

/// 🎨 رسّام فرع الشجرة — خط رأسي من الجذر مع خط أفقي قصير ناحية الورقة
/// ونقطة اتصال — مرسوم بواسطة كانفس حقيقي عشان يبان عرضه ( هن افتراض).
class _TreeBranchPainter extends CustomPainter {
  _TreeBranchPainter({
    required this.color,
    required this.first,
    required this.last,
  });

  final Color color;

  /// أول ورقة — الخط الرأسي مخفي فوقها.
  final bool first;

  /// آخر ورقة — الخط الرأسي بيتوقف عند نص فرعها.
  final bool last;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    const railX = 7.0;
    const branchEndX = 22.0;
    final midY = size.height / 2;

    if (!first) {
      canvas.drawLine(
        Offset(railX, 0),
        Offset(railX, last ? midY : size.height),
        paint,
      );
    }
    canvas.drawLine(Offset(railX, midY), Offset(branchEndX, midY), paint);
    final dot = Paint()..color = color;
    canvas.drawCircle(Offset(railX, midY), 3, dot);
  }

  @override
  bool shouldRepaint(covariant _TreeBranchPainter old) =>
      old.color != color || old.first != first || old.last != last;
}
