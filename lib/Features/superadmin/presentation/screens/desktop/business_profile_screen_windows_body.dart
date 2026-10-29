part of '../business_profile_screen.dart';

/// جسم شاشة الملف التجاري — نسخة الويندوز (Windows UI).
///
/// فورم متمركز في كارت بحدود هادئة: اسم المكان + اختيار نوع النشاط بشرائح
/// تفاعلية + مفتاح البلايستيشن، وزرار الحفظ في هيدر الصفحة وتحت الفورم.
extension _BusinessProfileWindowsBody on _BusinessProfileScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return DesktopPageScaffold(
      title: 'الملف التجاري'.tr(),
      subtitle: 'اسم المكان • نوع النشاط • تشغيل أو إيقاف نظام البلايستيشن'.tr(),
      maxWidth: 860,
      actions: [
        DesktopButton.primary(
          label: _saving ? 'جاري الحفظ...'.tr() : 'حفظ',
          icon: Icons.save_outlined,
          onPressed: _saving ? null : _save,
        ),
      ],
      child: _loading
          ?  Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesktopSectionTitle(title: 'بيانات المكان'.tr()),
                DesktopCard(
                  padding:  EdgeInsets.all(DesktopTokens.gapLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==================== 🖼️ لوجو البراند ====================
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: palette.surfaceSoft,
                              borderRadius: BorderRadius.circular(
                                DesktopTokens.radiusMd,
                              ),
                              border: Border.all(color: palette.border),
                            ),
                            child: _logoPath != null
                                ? Image.file(
                                    File(_logoPath!),
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    BusinessProfile.defaultLogoAsset,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                           SizedBox(width: DesktopTokens.gapMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'لوجو البراند'.tr(),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: palette.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                 SizedBox(height: 2),
                                Text(
                                  _logoPath == null
                                      ? 'اللوجو الافتراضي مستخدم — بيظهر في الفواتير وسايدبار الوندوز'.tr()
                                      : 'اللوجو المخصوص مستخدم — بيظهر في الفواتير وسايدبار الوندوز',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: palette.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DesktopToolbarIconButton(
                            icon: Icons.image_outlined,
                            tooltip: 'اختيار صورة اللوجو'.tr(),
                            onPressed: _pickingLogo ? null : _pickLogo,
                          ),
                           SizedBox(width: DesktopTokens.gapSm),
                          DesktopToolbarIconButton(
                            icon: Icons.delete_outline,
                            tooltip: 'إزالة اللوجو المخصوص'.tr(),
                            onPressed: _logoPath == null ? null : _clearLogo,
                          ),
                        ],
                      ),
                      const SizedBox(height: DesktopTokens.gapLg),
                      TextField(
                        controller: _nameCtl,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          labelText: 'اسم المكان'.tr(),
                          labelStyle: TextStyle(
                            color: palette.textMuted,
                            fontSize: 13.5,
                          ),
                          floatingLabelStyle:
                              TextStyle(color: palette.accentText),
                          prefixIcon: Icon(
                            Icons.storefront_outlined,
                            size: 20,
                            color: palette.textMuted,
                          ),
                          filled: true,
                          fillColor: palette.surfaceSoft,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              DesktopTokens.radiusMd,
                            ),
                            borderSide: BorderSide(color: palette.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              DesktopTokens.radiusMd,
                            ),
                            borderSide:
                                BorderSide(color: palette.accent, width: 1.5),
                          ),
                        ),
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
                        children:
                            BusinessProfile.typeLabels.entries.map((e) {
                          return _windowsTypeChip(context, e.key, e.value);
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
                          borderRadius: BorderRadius.circular(
                            DesktopTokens.radiusMd,
                          ),
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
                                    'نظام البلايستيشن مفعّل'.tr(),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: palette.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ('بيتحكم في ظهور كروت إدارة الأجهزة وتقرير '.tr() + 'البلايستيشن في لوحة الأدمن'.tr()),
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
                              onChanged: (v) =>
                                  _refresh(() => _playstation = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesktopTokens.gapLg),
                Row(
                  children: [
                    DesktopButton.primary(
                      label: _saving ? 'جاري الحفظ...'.tr() : 'حفظ التعديلات',
                      icon: Icons.save_outlined,
                      onPressed: _saving ? null : _save,
                    ),
                    const SizedBox(width: DesktopTokens.gapSm),
                    DesktopButton.ghost(
                      label: 'إلغاء'.tr(),
                      icon: Icons.close,
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  /// شريحة اختيار نوع النشاط — نسخة سطح المكتب من الـ ChoiceChip.
  Widget _windowsTypeChip(BuildContext context, String key, String label) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final selected = _type == key;

    return HoverBuilder(
      builder: (context, hovering) => GestureDetector(
        onTap: () => _refresh(() {
          _type = key;
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
