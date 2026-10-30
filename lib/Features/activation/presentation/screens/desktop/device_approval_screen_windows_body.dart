part of '../device_approval_screen.dart';

/// جسم شاشة موافقة الأجهزة — نسخة الويندوز (Windows UI).
///
/// لوحة إدارة كاملة: حظر جهاز بالكود مباشرة، وقائمة الطلبات في كروت
/// أنيقة بحالة ملونة وأزرار إجراء بنفس كل منطق الموبايل بالظبط.
extension _DeviceApprovalScreenWindowsBody on _DeviceApprovalScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    // ── لسه بنفحص الجهاز ──
    if (_checkingDevice) {
      return Scaffold(
        backgroundColor: palette.background,
        body: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: palette.accent,
            ),
          ),
        ),
      );
    }

    // ── جهاز غير مصرّح له ──
    if (!_isMasterDevice) {
      return DesktopPageScaffold(
        title: 'طلبات تفعيل الأجهزة'.tr(),
        subtitle: 'إدارة تراخيص العملاء'.tr(),
        child: DesktopEmptyState(
          icon: Icons.devices_other_outlined,
          title: 'غير مسموح'.tr(),
          message: 'هذه الصفحة متاحة فقط من جهاز المهندس المعتمد'.tr(),
        ),
      );
    }

    // ── تسجيل دخول المهندس ──
    if (!_loggedIn) {
      return DesktopPageScaffold(
        title: 'تسجيل دخول المهندس'.tr(),
        subtitle: 'مطلوب للوصول إلى طلبات التفعيل'.tr(),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: DesktopCard(
              padding: const EdgeInsets.all(26),
              radius: DesktopTokens.radiusXl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: DesktopIconBadge(
                      icon: Icons.engineering_outlined,
                      size: 56,
                      radius: DesktopTokens.radiusLg,
                    ),
                  ),
                  const SizedBox(height: DesktopTokens.gapMd),
                  Text(
                    'دخول المهندس'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: palette.textPrimary,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: DesktopTokens.gapXs),
                  Text(
                    'سجّل دخولك بحساب Supabase للوصول إلى طلبات التفعيل'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.textMuted,
                      fontSize: 12.5,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: DesktopTokens.gapLg),
                  _desktopField(
                    controller: _emailCtrl,
                    label: 'الإيميل'.tr(),
                    icon: Icons.alternate_email,
                    ltr: true,
                    action: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: DesktopTokens.gapMd),
                  _desktopField(
                    controller: _passCtrl,
                    label: 'كلمة السر'.tr(),
                    icon: Icons.lock_outline,
                    obscure: true,
                    action: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                  ),
                  if (_loginError != null) ...[
                    const SizedBox(height: DesktopTokens.gapMd),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: palette.soft(palette.danger),
                        borderRadius: BorderRadius.circular(
                          DesktopTokens.radiusSm,
                        ),
                        border: Border.all(
                          color: palette.danger.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 17,
                            color: palette.danger,
                          ),
                          const SizedBox(width: DesktopTokens.gapSm),
                          Expanded(
                            child: Text(
                              _loginError!,
                              style: TextStyle(
                                color: palette.danger,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: DesktopTokens.gapLg),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _loginLoading ? null : _login,
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: palette.accent.withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            DesktopTokens.radiusMd,
                          ),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child:
                          _loginLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                              : Text('دخول'.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── الطلبات ──
    return DesktopPageScaffold(
      title: 'طلبات تفعيل الأجهزة'.tr(),
      subtitle: 'إدارة تراخيص العملاء • {v1} طلب'.tr({'v1': _requests.length}),
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث الطلبات'.tr(),
          onPressed: _loadRequests,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── حظر جهاز بالكود مباشرة ──
          DesktopCard(
            padding: EdgeInsets.all(DesktopTokens.gapMd),
            child: Row(
              children: [
                Expanded(
                  child: _desktopField(
                    controller: _blockHashCtrl,
                    label: 'كود جهاز تحب تحظره'.tr(),
                    icon: Icons.block,
                    dense: true,
                  ),
                ),
                SizedBox(width: DesktopTokens.gapSm),
                if (_blocking)
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  DesktopButton.primary(
                    label: 'حظر'.tr(),
                    icon: Icons.block,
                    color: palette.danger,
                    onPressed: _blockManually,
                  ),
              ],
            ),
          ),
          SizedBox(height: DesktopTokens.gapLg),

          if (_loadingRequests)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: palette.accent,
                  ),
                ),
              ),
            )
          else if (_loadError != null)
            DesktopCard(
              padding: const EdgeInsets.all(DesktopTokens.gapMd),
              color: palette.soft(palette.danger),
              borderColor: palette.danger.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: palette.danger),
                  const SizedBox(width: DesktopTokens.gapSm),
                  Expanded(
                    child: Text(
                      _loadError!,
                      style: TextStyle(
                        color: palette.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesktopTokens.gapSm),
                  DesktopButton.ghost(
                    label: 'إعادة المحاولة'.tr(),
                    icon: Icons.refresh,
                    color: palette.danger,
                    onPressed: _loadRequests,
                  ),
                ],
              ),
            )
          else if (_requests.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: DesktopEmptyState(
                icon: Icons.inbox_outlined,
                title: 'لا توجد طلبات حاليًا'.tr(),
                message: 'أي جهاز جديد هيظهر هنا أول ما يطلب تفعيل'.tr(),
              ),
            )
          else ...[
            DesktopSectionTitle(title: 'الطلبات'.tr(), count: _requests.length),
            for (final row in _requests) _requestCard(context, palette, row),
          ],
        ],
      ),
    );
  }

  /// كارت طلب واحد — نفس بيانات الموبايل وبنفس الإجراءات بالظبط.
  Widget _requestCard(
    BuildContext context,
    DesktopPalette palette,
    Map<String, dynamic> row,
  ) {
    final hash = row['device_hash'] as String;
    final status = row['status'] as String;
    final isDemo = row['license_type'] == 'demo';
    final statusColor = _desktopStatusColor(palette, status);
    final requestedAt = row['requested_at']?.toString() ?? '';

    return DesktopCard(
      margin: EdgeInsets.only(bottom: DesktopTokens.gapSm + 2),
      padding: EdgeInsets.all(DesktopTokens.gapMd + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  hash,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    letterSpacing: 0.6,
                    color: palette.textSecondary,
                  ),
                ),
              ),
              SizedBox(width: DesktopTokens.gapSm),
              DesktopInfoChip(
                label: _statusLabel(status),
                icon: _desktopStatusIcon(status),
                color: statusColor,
              ),
            ],
          ),
          if (requestedAt.isNotEmpty || status == 'approved') ...[
            SizedBox(height: DesktopTokens.gapSm),
            Wrap(
              spacing: DesktopTokens.gapSm,
              runSpacing: DesktopTokens.gapXs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (requestedAt.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 13,
                        color: palette.textMuted,
                      ),
                      SizedBox(width: 4),
                      Text(
                        requestedAt,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                if (status == 'approved')
                  DesktopInfoChip(
                    label:
                        isDemo
                            ? 'تجريبي (ديمو)'.tr()
                            : 'دائم (مدى الحياة)'.tr(),
                    icon: isDemo ? Icons.hourglass_bottom : Icons.all_inclusive,
                    color: isDemo ? palette.warning : palette.info,
                    dense: true,
                  ),
              ],
            ),
          ],
          SizedBox(height: DesktopTokens.gapMd),
          Wrap(
            spacing: DesktopTokens.gapSm,
            runSpacing: DesktopTokens.gapSm,
            children: [
              if (status != 'approved') ...[
                DesktopButton.primary(
                  label: 'تفعيل دائم (شراء)'.tr(),
                  icon: Icons.check,
                  color: palette.success,
                  onPressed: () => _approve(hash, licenseType: 'lifetime'),
                ),
                DesktopButton.primary(
                  label: 'تفعيل تجريبي (ديمو)'.tr(),
                  icon: Icons.access_time,
                  color: palette.warning,
                  onPressed: () => _showDemoApprovalDialog(hash),
                ),
              ] else ...[
                if (isDemo)
                  DesktopButton.primary(
                    label: 'تحويل لدائم (شراء)'.tr(),
                    icon: Icons.verified,
                    color: palette.success,
                    onPressed: () => _approve(hash, licenseType: 'lifetime'),
                  ),
                DesktopButton.ghost(
                  label: 'تعديل مدة التجربة'.tr(),
                  icon: Icons.update,
                  onPressed: () => _showDemoApprovalDialog(hash),
                ),
                DesktopButton.ghost(
                  label: 'إلغاء التفعيل'.tr(),
                  icon: Icons.block,
                  color: palette.danger,
                  onPressed: () => _revoke(hash),
                ),
              ],
              if (status != 'rejected' && status != 'approved')
                DesktopButton.ghost(
                  label: 'رفض'.tr(),
                  icon: Icons.close,
                  color: palette.danger,
                  onPressed: () => _reject(hash),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// لون الحالة من ألوان لوحة سطح المكتب.
  Color _desktopStatusColor(DesktopPalette palette, String status) {
    switch (status) {
      case 'approved':
        return palette.success;
      case 'pending':
        return palette.warning;
      default:
        return palette.danger;
    }
  }

  /// أيقونة الحالة المناسبة لكل حالة طلب.
  IconData _desktopStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.hourglass_top;
      case 'rejected':
        return Icons.close;
      case 'revoked':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  /// خانة إدخال بشكل سطح المكتب — نفس ستايل باقي الصفحات.
  Widget _desktopField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool obscure = false,
    bool ltr = false,
    bool dense = false,
    TextInputAction? action,
    TextInputType? keyboardType,
    ValueChanged<String>? onSubmitted,
  }) {
    final palette = DesktopPalette.of(context);

    return TextField(
      controller: controller,
      obscureText: obscure,
      textDirection: ltr ? TextDirection.ltr : null,
      textInputAction: action,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      style: TextStyle(
        color: palette.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: palette.textMuted, fontSize: 13),
        floatingLabelStyle: TextStyle(color: palette.accentText),
        prefixIcon:
            icon != null
                ? Icon(icon, size: 19, color: palette.textMuted)
                : null,
        filled: true,
        fillColor: palette.surfaceSoft,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: dense ? 14 : 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
          borderSide: BorderSide(color: palette.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
          borderSide: BorderSide(color: palette.danger, width: 1.5),
        ),
      ),
    );
  }
}
