part of '../manage_users.dart';

/// جسم شاشة إدارة المستخدمين — نسخة الموبايل 🌿 (شجرة قابلة للفتح والقفل)
extension _ManageUsersScreenMobileBody on _ManageUsersScreenState {
  Widget _buildMobileBody(BuildContext context) {
    final theme = Theme.of(context);
    final roots = users
        .where((u) => _isBranchRole(u['role']))
        .toList();
    final independents = _independentStaff;

    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة المستخدمين'.tr()),
      ),
      body:
          users.isEmpty
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_tree_rounded,
                        size: 48,
                        color: theme.colorScheme.primary.withValues(alpha: .4)),
                    const SizedBox(height: 12),
                    Text('شجرة الفريق لسه فاضية'.tr(),
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'ابدأ بأول كاشير — وبعده اسحب أي موظف وأفلته على أي جذر يلحّقه تحته مباشرة 🤏'
                          .tr(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              )
              : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                children: [
                  // 🔑 لوحة مفتاح — الشجرة بتتقري من غير كلام كتير
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_tree_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'شجرة الفريق • موظف الطلبات يقدر يشتغل تحت أكتر من كاشير في نفس الوقت'
                                    .tr(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'اسحب الموظف وأفلته على أي جذر 🤏'.tr(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ==================== الجذور ====================
                  for (final root in roots) _muMobileBranch(context, root),
                  // ==================== المستقلين ====================
                  if (independents.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      'فريق مستقل — موظفين شغالين بلا مشرف'.tr(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final w in independents) _muMobileLeaf(context, w, null),
                  ],
                ],
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text('إضافة مستخدم'.tr()),
      ),
    );
  }

  /// جذر الموبايل — كاشير أو أدمن قابل للفتح مع أوراقه.
  Widget _muMobileBranch(BuildContext context, Map<String, dynamic> root) {
    final theme = Theme.of(context);
    final role = root['role'] as String? ?? '';
    final isExpanded = _expandedSupervisors.contains(_userId(root));
    final children = _childrenOfUser(root);

    final roleColor = role == 'admin'
        ? Colors.indigo
        : Colors.teal;
    final roleIcon = role == 'admin'
        ? Icons.admin_panel_settings_outlined
        : Icons.point_of_sale_outlined;
    final roleLabel = _roleLabel(role);

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails:
          (d) =>
              (d.data['role'] as String? ?? '') == 'waiter' &&
              _userId(d.data) != _userId(root),
      onAcceptWithDetails: (d) => _attachWaiterToSupervisor(d.data, root),
      builder: (context, candidateData, rejectedData) {
        final dragging = candidateData.isNotEmpty;
        return Stack(
          children: [
            Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: roleColor.withValues(alpha: dragging ? 0.85 : 0.45),
          width: 1.1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _refresh(() {
              isExpanded
                  ? _expandedSupervisors.remove(_userId(root))
                  : _expandedSupervisors.add(_userId(root));
            }),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(roleIcon, color: roleColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          root['username'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '{roleLabel} • {v2}'.tr({'roleLabel': roleLabel, 'v2': 'موظفين تحته: {v1}'.tr({'v1': '${children.length}'})}),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                    ),
                    onPressed: () => _refresh(() {
                      isExpanded
                          ? _expandedSupervisors.remove(_userId(root))
                          : _expandedSupervisors.add(_userId(root));
                    }),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOutCubic,
            crossFadeState:
                isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild:
                children.isEmpty
                    ? Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 24,
                        bottom: 12,
                      ),
                      child: Text(
                        'لسه مفيش موظفين متفرّعين هنا — اسحب أي موظف وأفلته على الجذر 🤏'
                            .tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                    : Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 18,
                        end: 12,
                        bottom: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Divider(
                            height: 1,
                            color: theme.dividerColor.withValues(alpha: .5),
                          ),
                          const SizedBox(height: 8),
                          for (final leaf in children)
                            _muMobileLeaf(
                              context,
                              leaf,
                              root,
                            ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
      ),
            if (dragging) ...[
              // ✔ هالة إسقاط نيون حول الكارت وقت المرور
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    foregroundDecoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.9),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              // ✔ شريط الدعوة للإسقاط — يطير تجاه قاع الكارت
              IgnorePointer(
                child: Align(
                  alignment: AlignmentDirectional.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.secondary.withValues(
                              alpha: 0.4,
                            ),
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

  /// ورقة الموبايل — موظف طلبات قابل للسحب بمخالطة لفترة قصيرة 🌿
  Widget _muMobileLeaf(
    BuildContext context,
    Map<String, dynamic> leaf,
    Map<String, dynamic>? parent,
  ) {
    return LongPressDraggable<Map<String, dynamic>>(
      data: leaf,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _muMobileFeedbackCard(context, leaf),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _muMobileLeafCore(context, leaf, parent),
      ),
      child: _muMobileLeafCore(context, leaf, parent),
    );
  }

  /// 🎯 الكارت الطاير في الموبايل — نسخة مصغّرة عجّالة من الورقة.
  Widget _muMobileFeedbackCard(
    BuildContext context,
    Map<String, dynamic> leaf,
  ) {
    final theme = Theme.of(context);
    final leafColor = theme.colorScheme.secondary;
    final under = _underLabel(leaf);
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
            color: leafColor.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: leafColor.withValues(alpha: 0.45),
                blurRadius: 24,
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
              const SizedBox(width: 6),
              Text(
                under,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ورقة الموبايل — موظف طلبات مع ملخص المشرفين وأزرار الفصل/التعديل.
  Widget _muMobileLeafCore(
    BuildContext context,
    Map<String, dynamic> leaf,
    Map<String, dynamic>? parent,
  ) {
    final theme = Theme.of(context);
    final waiterColor = theme.colorScheme.secondary;
    final under = _underLabel(leaf);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: waiterColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: waiterColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          // 🤏 مقبض السحب — علامة بصرية إن المخالطة الطويلة بتسحب الورقة
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 3),
            child: Icon(
              Icons.drag_indicator_rounded,
              size: 15,
              color: waiterColor.withValues(alpha: 0.7),
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: waiterColor.withValues(alpha: 0.18),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.room_service_outlined,
              size: 17,
              color: waiterColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leaf['username'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  parent == null
                      ? under
                      : 'الراتب بالساعة: {v1}'.tr({
                        'v1': leaf['salary_per_hour'] ?? 'غير محدد'.tr(),
                      }),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (parent != null)
            IconButton(
              tooltip: 'فصله من عند {u}'.tr({'u': parent['username'] ?? ''}),
              icon: Icon(
                Icons.link_off_rounded,
                size: 20,
                color: theme.colorScheme.error.withValues(alpha: .8),
              ),
              onPressed: () => _detachFromSupervisor(leaf, parent),
            ),
          IconButton(
            tooltip: 'تعديل المستخدم'.tr(),
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _showForm(edit: leaf),
          ),
          IconButton(
            tooltip: 'حذف المستخدم'.tr(),
            icon: Icon(
              Icons.delete_outline,
              size: 20,
              color: theme.colorScheme.error,
            ),
            onPressed: () => _confirmDeleteUser(leaf['id'], leaf['username']),
          ),
        ],
      ),
    );
  }
}
