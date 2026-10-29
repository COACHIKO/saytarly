part of '../setup_wizard.dart';

/// جسم معالج التهيئة — نسخة الويندوز (Windows UI).
///
/// ويزارد سطح مكتب كامل: هيدر فيه ستيبر أفقي بأربع خطوات، ومحتوى كل خطوة
/// في كارت متمركز، وشريط تنقل سفلي (السابق / تخطي / التالي).
extension _SetupWizardWindowsBody on _SetupWizardScreenState {
  static List<String> get _winSteps => [
    'بيانات المكان'.tr(),
    'حساب الأدمن'.tr(),
    'حساب الستاف'.tr(),
    'أقسام المنتجات'.tr(),
  ];

  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopPageScaffold(
      title: 'تهيئة النظام'.tr(),
      subtitle: 'خطوة {v1} من {v2} — {v3}'.tr({'v1': _step + 1, 'v2': _winSteps.length, 'v3': _winSteps[_step]}),
      showBackButton: widget.fromDashboard,
      maxWidth: 1000,
      headerBottom: _winStepper(context, palette),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _winStepContent(context, palette),
              const SizedBox(height: DesktopTokens.gapLg + 4),
              _winBottomBar(context, palette),
            ],
          ),
        ),
      ),
    );
  }

  /// ستيبر أفقي أنيق بأربع خطوات.
  Widget _winStepper(BuildContext context, DesktopPalette palette) {
    final theme = Theme.of(context);

    return Row(
      children: [
        for (var i = 0; i < _winSteps.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: DesktopTokens.fast,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i < _step
                          ? palette.success
                          : (i == _step ? palette.accent : palette.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (i < _step) ...[
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: palette.success,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          _winSteps[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11.5,
                            fontWeight:
                                i == _step ? FontWeight.w800 : FontWeight.w600,
                            color: i < _step
                                ? palette.success
                                : (i == _step
                                    ? palette.textPrimary
                                    : palette.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _winStepContent(BuildContext context, DesktopPalette palette) {
    switch (_step) {
      case 0:
        return _winBusinessStep(context, palette);
      case 1:
        return _winAccountStep(
          context,
          palette,
          isAdmin: true,
          userCtl: _adminUserCtl,
          passCtl: _adminPassCtl,
        );
      case 2:
        return _winAccountStep(
          context,
          palette,
          isAdmin: false,
          userCtl: _staffUserCtl,
          passCtl: _staffPassCtl,
        );
      default:
        return _winModulesStep(context, palette);
    }
  }

  Widget _winSectionTitle(
    BuildContext context,
    DesktopPalette palette,
    String text, {
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: palette.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 23,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textMuted,
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
        ],
        const SizedBox(height: DesktopTokens.gapLg),
      ],
    );
  }

  /// خانة إدخال بشكل سطح المكتب.
  Widget _winTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputAction? action,
    ValueChanged<String>? onSubmitted,
    bool obscure = false,
  }) {
    final palette = DesktopPalette.of(context);

    return TextField(
      controller: controller,
      textInputAction: action,
      onSubmitted: onSubmitted,
      obscureText: obscure,
      style: TextStyle(
        color: palette.textPrimary,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: palette.textMuted, fontSize: 13.5),
        floatingLabelStyle: TextStyle(color: palette.accentText),
        prefixIcon: Icon(icon, size: 20, color: palette.textMuted),
        filled: true,
        fillColor: palette.surfaceSoft,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _winBusinessStep(BuildContext context, DesktopPalette palette) {
    final theme = Theme.of(context);

    return DesktopCard(
      padding: const EdgeInsets.all(DesktopTokens.gapLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _winSectionTitle(
            context,
            palette,
            'أهلًا بيك في تهيئة النظام 👋'.tr(),
            subtitle: ('من هنا بتظبط النظام يناسب مكانك: الاسم، النوع، '.tr() + 'وبعدها بتنشئ الحسابات والأقسام.'.tr()),
          ),
          _winTextField(
            controller: _nameCtl,
            label: 'اسم المكان (زي: كافيه الجراند)'.tr(),
            icon: Icons.storefront_outlined,
          ),
          const SizedBox(height: DesktopTokens.gapLg),
          Text(
            'نوع النشاط'.tr(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: DesktopTokens.gapSm),
          Wrap(
            spacing: DesktopTokens.gapSm,
            runSpacing: DesktopTokens.gapSm,
            children: BusinessProfile.typeLabels.entries.map((e) {
              return _winTypeChip(context, palette, e.key, e.value);
            }).toList(),
          ),
          const SizedBox(height: DesktopTokens.gapLg),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesktopTokens.gapMd,
              vertical: DesktopTokens.gapSm + 2,
            ),
            decoration: BoxDecoration(
              color: palette.surfaceSoft,
              borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                DesktopIconBadge(
                  icon: Icons.sports_esports_outlined,
                  color: palette.accent,
                  size: 40,
                ),
                const SizedBox(width: DesktopTokens.gapMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'النظام فيه بلايستيشن (أجهزة/شاشات)؟'.tr(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ('لو مفعّل هيظهر كروت إدارة الأجهزة وتقرير '.tr() + 'البلايستيشن في لوحة الأدمن'.tr()),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _playstation,
                  onChanged: (v) => _refresh(() => _playstation = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _winAccountStep(
    BuildContext context,
    DesktopPalette palette, {
    required bool isAdmin,
    required TextEditingController userCtl,
    required TextEditingController passCtl,
  }) {
    return DesktopCard(
      padding: const EdgeInsets.all(DesktopTokens.gapLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _winSectionTitle(
            context,
            palette,
            isAdmin ? 'حساب الأدمن'.tr() : 'حساب الكاشير (اختياري)',
            subtitle: isAdmin
                ? 'الأدمن هو اللي هيدير المكان يوميًا: المشروبات، التقارير، المستخدمين.'.tr()
                : 'الكاشير هو مدير الصالة اللي بياخد الطلبات ويفتح الشيفت ويبدأ شغل موظفي الطلبات. '
                    'تقدر تسيبه دلوقتي وتضيفه بعدين.',
          ),
          _winTextField(
            controller: userCtl,
            label: 'اسم المستخدم'.tr(),
            icon: Icons.person_outline,
            action: TextInputAction.next,
          ),
          const SizedBox(height: DesktopTokens.gapMd),
          _winTextField(
            controller: passCtl,
            label: 'كلمة المرور'.tr(),
            icon: Icons.lock_outline,
            action: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  Widget _winModulesStep(BuildContext context, DesktopPalette palette) {
    final theme = Theme.of(context);

    return DesktopCard(
      padding: const EdgeInsets.all(DesktopTokens.gapLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _winSectionTitle(
            context,
            palette,
            'أقسام منتجات المطبخ'.tr(),
            subtitle: ('زي: مشروبات، ماكولات، حلويات... كل قسم هيطلع له تلقائي: '.tr() + 'إدارة + تقرير في لوحة الأدمن، وتقدر تضيف جواه قوائم فرعية. '.tr() + 'الخامات مخزون مشترك لكل الأقسام.'.tr()),
          ),
          Row(
            children: [
              Expanded(
                child: _winTextField(
                  controller: _moduleCtl,
                  label: 'اسم القسم (زي: مشروبات)'.tr(),
                  icon: Icons.category_outlined,
                  action: TextInputAction.done,
                  onSubmitted: (_) => _addModuleFromField(),
                ),
              ),
              const SizedBox(width: DesktopTokens.gapSm),
              DesktopButton.primary(
                label: 'إضافة'.tr(),
                icon: Icons.add,
                onPressed: _addModuleFromField,
              ),
            ],
          ),
          const SizedBox(height: DesktopTokens.gapMd),
          if (_addedModules.isEmpty)
            Text(
              ('لسه مفيش أقسام — تقدر تكمّل من غيرها وتضيفها بعدين '.tr() + 'من لوحة السوبر ادمن'.tr()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textMuted,
                fontSize: 13,
              ),
            )
          else
            for (final m in _addedModules)
              Padding(
                padding: const EdgeInsets.only(bottom: DesktopTokens.gapSm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesktopTokens.gapMd,
                    vertical: DesktopTokens.gapSm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: palette.soft(palette.success),
                    borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
                    border: Border.all(
                      color: palette.success.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: palette.success),
                      const SizedBox(width: DesktopTokens.gapSm),
                      Expanded(
                        child: Text(
                          m,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _winBottomBar(BuildContext context, DesktopPalette palette) {
    final isLast = _step == 3;

    return Row(
      children: [
        if (_step > 0)
          DesktopButton.ghost(
            label: 'السابق'.tr(),
            icon: Icons.chevron_right,
            onPressed: _saving ? null : () => _refresh(() => _step--),
          ),
         Spacer(),
        if (_step == 1)
          DesktopButton.ghost(
            label: 'مش دلوقتي'.tr(),
            onPressed: _saving ? null : () => _refresh(() => _step = 2),
          ),
        if (_step == 2)
          DesktopButton.ghost(
            label: 'تخطي'.tr(),
            onPressed: _saving ? null : () => _refresh(() => _step = 3),
          ),
        const SizedBox(width: DesktopTokens.gapSm),
        SizedBox(
          height: 44,
          child: FilledButton(
            onPressed: _saving ? null : _goNext,
            style: FilledButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(isLast ? 'ابدأ العمل 🚀'.tr() : 'التالي'),
          ),
        ),
      ],
    );
  }

  /// شريحة اختيار نوع النشاط — نسخة سطح المكتب.
  Widget _winTypeChip(
    BuildContext context,
    DesktopPalette palette,
    String key,
    String label,
  ) {
    final theme = Theme.of(context);
    final selected = _businessType == key;

    return HoverBuilder(
      builder: (context, hovering) => GestureDetector(
        onTap: () => _refresh(() {
          _businessType = key;
          if (key == 'playstation_cafe') _playstation = true;
        }),
        child: AnimatedContainer(
          duration: DesktopTokens.fast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? palette.accentSoft
                : (hovering ? palette.surfaceSoft : palette.surface),
            borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
            border: Border.all(
              color: selected
                  ? palette.accent.withValues(alpha: 0.6)
                  : (hovering ? palette.borderStrong : palette.border),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_circle, size: 16, color: palette.accentText),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color:
                      selected ? palette.accentText : palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
