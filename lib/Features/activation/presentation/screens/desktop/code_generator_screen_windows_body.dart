part of '../code_generator_screen.dart';

/// جسم شاشة مولّد أكواد التفعيل — نسخة الويندوز (Windows UI).
///
/// أداة المهندس بشكل سطح مكتب: بوابة كلمة سر في كارت أنيق، وبعدها خطوات
/// التوليد (كود الجهاز + المدة) والنتيجة في كارت مميز مع زر النسخ.
extension _CodeGeneratorScreenWindowsBody on _CodeGeneratorScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopPageScaffold(
      title: 'مولّد أكواد التفعيل'.tr(),
      subtitle: 'أداة المهندس — توليد كود تفعيل لأي جهاز'.tr(),
      maxWidth: 900,
      child: _unlocked
          ? _generatorForm(context, palette)
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _passwordGate(context, palette),
              ),
            ),
    );
  }

  // ── بوابة كلمة سر المهندس ──
  Widget _passwordGate(BuildContext context, DesktopPalette palette) {
    final theme = Theme.of(context);

    return DesktopCard(
      padding: const EdgeInsets.all(28),
      radius: DesktopTokens.radiusXl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: DesktopIconBadge(
              icon: Icons.admin_panel_settings_outlined,
              size: 58,
              radius: DesktopTokens.radiusLg,
            ),
          ),
          const SizedBox(height: DesktopTokens.gapMd),
          Text(
            'هذه الصفحة للمهندس فقط'.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: palette.textPrimary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: DesktopTokens.gapXs),
          Text(
            'أدخل كلمة سر المهندس للوصول إلى مولّد الأكواد'.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textMuted,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: DesktopTokens.gapLg),
          _desktopField(
            controller: _passCtrl,
            label: 'كلمة سر المهندس'.tr(),
            icon: Icons.key_outlined,
            obscure: true,
            ltr: true,
            errorText: _passError ? 'كلمة السر غير صحيحة'.tr() : null,
            onSubmitted: (_) => _unlock(),
          ),
          const SizedBox(height: DesktopTokens.gapLg),
          SizedBox(
            height: 46,
            child: FilledButton.icon(
              onPressed: _unlock,
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
                ),
                textStyle: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              icon: const Icon(Icons.lock_open_rounded, size: 19),
              label:  Text('دخول'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  // ── فورم التوليد ──
  Widget _generatorForm(BuildContext context, DesktopPalette palette) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── كود جهازك الحالي (للمرجعية) ──
        if (_currentDeviceId.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesktopTokens.gapMd,
              vertical: DesktopTokens.gapSm,
            ),
            decoration: BoxDecoration(
              color: palette.surfaceSoft,
              borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.computer_outlined,
                  size: 18,
                  color: palette.textMuted,
                ),
                const SizedBox(width: DesktopTokens.gapSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'كود جهازك الحالي (مرجعية):'.tr(),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: palette.textMuted,
                        ),
                      ),
                      Text(
                        _currentDeviceId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DesktopTokens.gapSm),
                DesktopButton.ghost(
                  label: 'نسخ'.tr(),
                  icon: Icons.copy_rounded,
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: _currentDeviceId),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesktopTokens.gapMd),
        ],

        // ── الخطوة 1: كود الجهاز ──
        DesktopCard(
          padding: const EdgeInsets.all(22),
          radius: DesktopTokens.radiusXl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               DesktopSectionTitle(
                title: 'الخطوة 1 — كود الجهاز (من العميل)'.tr(),
              ),
              _desktopField(
                controller: _deviceIdCtrl,
                label: 'كود الجهاز'.tr(),
                hint: 'الصق كود الجهاز هنا...'.tr(),
                icon: Icons.fingerprint,
                ltr: true,
                center: true,
                mono: true,
                suffix: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'لصق'.tr(),
                      icon: Icon(
                        Icons.paste_rounded,
                        size: 19,
                        color: palette.textMuted,
                      ),
                      onPressed: () async {
                        final d = await Clipboard.getData(
                          Clipboard.kTextPlain,
                        );
                        if (d?.text != null) {
                          _deviceIdCtrl.text = d!.text!.trim();
                        }
                      },
                    ),
                    IconButton(
                      tooltip: 'مسح'.tr(),
                      icon: Icon(
                        Icons.clear,
                        size: 19,
                        color: palette.textMuted,
                      ),
                      onPressed: () => _deviceIdCtrl.clear(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesktopTokens.gapMd),

        // ── الخطوة 2: مدة الترخيص ──
        DesktopCard(
          padding: const EdgeInsets.all(22),
          radius: DesktopTokens.radiusXl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               DesktopSectionTitle(title: 'الخطوة 2 — مدة الترخيص'.tr()),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'دائم — مدى الحياة'.tr(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'العميل اشترى السيستم نهائياً'.tr(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isLifetime,
                    onChanged: (val) => _refresh(() => _isLifetime = val),
                  ),
                ],
              ),
              if (!_isLifetime) ...[
                const SizedBox(height: DesktopTokens.gapSm),
                Divider(color: palette.border, height: 1),
                const SizedBox(height: DesktopTokens.gapMd),
                Text(
                  'أو اختر مدة التجربة:'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: DesktopTokens.gapSm),
                Wrap(
                  spacing: DesktopTokens.gapSm,
                  runSpacing: DesktopTokens.gapSm,
                  children: [
                    for (final d in [3, 7, 14, 30, 60, 90, 180, 365])
                      _durationChip(d),
                  ],
                ),
                const SizedBox(height: DesktopTokens.gapMd),
                _desktopField(
                  controller: _customDaysCtrl,
                  label: 'أو أدخل عدد الأيام يدوياً'.tr(),
                  suffixText: 'يوم'.tr(),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final parsed = int.tryParse(val);
                    if (parsed != null && parsed > 0) {
                      _refresh(() => _selectedDays = parsed);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
         SizedBox(height: DesktopTokens.gapLg),

        // ── زرار التوليد ──
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: _generate,
            style: FilledButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
              ),
              textStyle:  TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            icon:  Icon(Icons.key_rounded, size: 20),
            label:  Text('توليد كود التفعيل'.tr()),
          ),
        ),

        // ── عرض الكود المولَّد ──
        if (_generatedCode != null) ...[
          const SizedBox(height: DesktopTokens.gapLg),
          DesktopCard(
            padding: const EdgeInsets.all(24),
            radius: DesktopTokens.radiusXl,
            color: palette.accentSoft,
            borderColor: palette.accent.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: DesktopInfoChip(
                    label: 'تم توليد الكود'.tr(),
                    icon: Icons.verified_outlined,
                    color: palette.success,
                  ),
                ),
                const SizedBox(height: DesktopTokens.gapMd),
                Text(
                  'كود التفعيل:'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: DesktopTokens.gapSm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(DesktopTokens.gapMd),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(
                      DesktopTokens.radiusMd,
                    ),
                    border: Border.all(
                      color: palette.accent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: SelectableText(
                    _generatedCode!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 24,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w900,
                      color: palette.accentText,
                    ),
                  ),
                ),
                const SizedBox(height: DesktopTokens.gapSm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: palette.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isLifetime
                          ? 'ترخيص دائم مدى الحياة'.tr()
                          : 'صالح لمدة ${int.tryParse(_customDaysCtrl.text) ?? _selectedDays} يوم',
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesktopTokens.gapMd),
                SizedBox(
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: _copyCode,
                    style: FilledButton.styleFrom(
                      backgroundColor: _justCopied
                          ? palette.success
                          : palette.accent,
                      foregroundColor: Colors.white,
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
                    icon: Icon(
                      _justCopied ? Icons.check : Icons.copy_rounded,
                      size: 19,
                    ),
                    label: Text(_justCopied ? 'تم النسخ!'.tr() : 'نسخ الكود'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// شيب اختيار مدة — نفس منطق الـ chips في الموبايل.
  Widget _durationChip(int d) {
    final label = d >= 365 ? '{v1} سنة'.tr({'v1': d ~/ 365}) : '$d يوم';
    return ChoiceChip(
      label: Text(label),
      selected: _selectedDays == d,
      onSelected: (sel) {
        if (sel) {
          _refresh(() {
            _selectedDays = d;
            _customDaysCtrl.text = d.toString();
          });
        }
      },
    );
  }

  /// خانة إدخال بشكل سطح المكتب — ناعمة ومتسقة مع باقي الصفحات.
  Widget _desktopField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool obscure = false,
    bool ltr = false,
    bool center = false,
    bool mono = false,
    TextInputAction? action,
    TextInputType? keyboardType,
    ValueChanged<String>? onSubmitted,
    ValueChanged<String>? onChanged,
    String? suffixText,
    String? errorText,
    Widget? suffix,
  }) {
    final palette = DesktopPalette.of(context);

    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: action,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      textDirection: ltr ? TextDirection.ltr : null,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        color: palette.textPrimary,
        fontSize: mono ? 13.5 : 14,
        fontWeight: FontWeight.w600,
        fontFamily: mono ? 'monospace' : null,
        letterSpacing: mono ? 1 : null,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        suffixText: suffixText,
        labelStyle: TextStyle(color: palette.textMuted, fontSize: 13),
        floatingLabelStyle: TextStyle(color: palette.accentText),
        hintStyle: TextStyle(color: palette.textMuted),
        errorStyle: TextStyle(color: palette.danger, fontSize: 11.5),
        prefixIcon: icon != null
            ? Icon(icon, size: 19, color: palette.textMuted)
            : null,
        suffixIcon: suffix,
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
