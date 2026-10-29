part of '../license_generator_screen.dart';

/// جسم شاشة مولد أكواد التفعيل — نسخة الويندوز (Windows UI).
///
/// فورم أنيق في كارت واحد: كود جهاز العميل + مدة الترخيص، والنتيجة في
/// كارت مميز بلون accentSoft مع زر نسخ بنفس منطق الموبايل.
extension _LicenseGeneratorScreenWindowsBody on _LicenseGeneratorScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopPageScaffold(
      title: 'مولّد أكواد التفعيل'.tr(),
      subtitle: 'توليد كود ترخيص لجهاز العميل'.tr(),
      maxWidth: 760,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: _generatorCard(context, palette),
        ),
      ),
    );
  }

  /// الكارت الرئيسي: خانة الكود + اختيار المدة + النتيجة.
  Widget _generatorCard(BuildContext context, DesktopPalette palette) {
    final theme = Theme.of(context);

    return DesktopCard(
      padding:  EdgeInsets.all(26),
      radius: DesktopTokens.radiusXl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── رأس الكارت ──
          Row(
            children: [
               DesktopIconBadge(
                icon: Icons.admin_panel_settings_outlined,
                size: 52,
                radius: DesktopTokens.radiusLg,
              ),
               SizedBox(width: DesktopTokens.gapMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مولد كود التفعيل'.tr(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: palette.textPrimary,
                        fontSize: 20,
                      ),
                    ),
                     SizedBox(height: 3),
                    Text(
                      'اختر مدة الترخيص والكود يطلع جاهز للإرسال للعميل'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
           SizedBox(height: DesktopTokens.gapLg),

          // ── كود جهاز العميل ──
          Text('كود جهاز العميل'.tr(), style: _labelStyle(palette)),
           SizedBox(height: DesktopTokens.gapSm),
          TextField(
            controller: _deviceController,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13.5,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'أدخل Device ID'.tr(),
              hintStyle: TextStyle(
                fontFamily: 'monospace',
                letterSpacing: 1,
                color: palette.textMuted,
              ),
              prefixIcon: Icon(
                Icons.computer_outlined,
                size: 19,
                color: palette.textMuted,
              ),
              filled: true,
              fillColor: palette.surfaceSoft,
              isDense: true,
              contentPadding:  EdgeInsets.symmetric(
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
          ),
           SizedBox(height: DesktopTokens.gapLg),

          // ── مدة الترخيص ──
          Text('مدة الترخيص'.tr(), style: _labelStyle(palette)),
          const SizedBox(height: DesktopTokens.gapSm),
          Wrap(
            spacing: DesktopTokens.gapSm,
            runSpacing: DesktopTokens.gapSm,
            children: [
              for (final item in _durations)
                ChoiceChip(
                  label: Text(item['label'] as String),
                  selected: _days == item['days'],
                  onSelected: (sel) {
                    if (sel) {
                      _refresh(() => _days = item['days'] as int);
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: DesktopTokens.gapLg),

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
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              icon: const Icon(Icons.key_rounded, size: 20),
              label:  Text('توليد كود التفعيل'.tr()),
            ),
          ),

          // ── النتيجة ──
          if (_generatedCode.isNotEmpty) ...[
            const SizedBox(height: DesktopTokens.gapLg),
            DesktopCard(
              padding: const EdgeInsets.all(24),
              radius: DesktopTokens.radiusXl,
              color: palette.accentSoft,
              borderColor: palette.accent.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'كود التفعيل للعميل'.tr(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: DesktopTokens.gapMd),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(
                        DesktopTokens.radiusMd,
                      ),
                      border: Border.all(
                        color: palette.accent.withValues(alpha: 0.4),
                        width: 1.4,
                      ),
                    ),
                    child: SelectableText(
                      _generatedCode,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        fontFamily: 'monospace',
                        color: palette.accentText,
                      ),
                    ),
                  ),
                  const SizedBox(height: DesktopTokens.gapMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 14,
                        color: palette.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _durationLabel(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
                        backgroundColor: palette.accent,
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
                      icon: const Icon(Icons.copy_rounded, size: 19),
                      label:  Text('نسخ كود التفعيل'.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// عنوان صغير فوق أي خانة في الفورم.
  TextStyle _labelStyle(DesktopPalette palette) => TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w800,
    color: palette.textPrimary,
  );

  /// نص مدة الترخيص المختارة — بنفس منطق الموبايل.
  String _durationLabel() {
    final match = _durations.firstWhere(
      (item) => item['days'] == _days,
      orElse: () => {'label': '$_days يوم'},
    );
    return match['label'] as String;
  }
}
