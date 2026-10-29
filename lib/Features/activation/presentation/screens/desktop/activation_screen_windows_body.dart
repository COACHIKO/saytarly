part of '../activation_screen.dart';

/// جسم شاشة التفعيل — نسخة الويندوز (Windows UI).
///
/// معالج تفعيل أنيق في منتصف الشاشة: كود الجهاز في صندوق mono قابل
/// للتحديد مع زر نسخ، وحقل كود التفعيل، ونفس حالات التحميل والرسائل.
extension _ActivationScreenWindowsBody on _ActivationScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final isExpired = widget.isExpired;

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          // لمسات ضوء ناعمة في الخلفية
          Positioned(
            top: -160,
            right: -130,
            child: _glowCircle(palette.accent, 460),
          ),
          Positioned(
            bottom: -200,
            left: -150,
            child: _glowCircle(
              isExpired ? palette.warning : palette.info,
              440,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── أيقونة + عنوان ──
                    DesktopIconBadge(
                      icon: isExpired
                          ? Icons.timer_off_rounded
                          : Icons.lock_open_rounded,
                      color: isExpired ? palette.warning : palette.accent,
                      size: 64,
                      radius: DesktopTokens.radiusXl,
                    ),
                    const SizedBox(height: DesktopTokens.gapMd),
                    Text(
                      isExpired ? 'انتهت مدة الترخيص'.tr() : 'تفعيل البرنامج',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: palette.textPrimary,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: DesktopTokens.gapXs),
                    Text(
                      isExpired
                          ? 'تواصل مع المهندس للتجديد وأرسل له كود الجهاز بالأسفل'.tr()
                          : 'أرسل كود الجهاز للمهندس وادخل كود التفعيل الذي سيرسله لك',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.textMuted,
                        fontSize: 13.5,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: DesktopTokens.gapMd),
                    DesktopInfoChip(
                      label: isExpired ? 'الرخصة منتهية'.tr() : 'الجهاز غير مفعّل',
                      icon: isExpired
                          ? Icons.hourglass_disabled_outlined
                          : Icons.devices_other_outlined,
                      color: isExpired ? palette.warning : palette.info,
                    ),
                    const SizedBox(height: DesktopTokens.gapLg),

                    // ── الكارت الرئيسي ──
                    DesktopCard(
                      padding: const EdgeInsets.all(26),
                      radius: DesktopTokens.radiusXl,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'كود هذا الجهاز:'.tr(),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: DesktopTokens.gapSm),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surfaceSoft,
                              borderRadius: BorderRadius.circular(
                                DesktopTokens.radiusMd,
                              ),
                              border: Border.all(color: palette.border),
                            ),
                            alignment: Alignment.center,
                            child: _loadingId
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: palette.accent,
                                    ),
                                  )
                                : SelectableText(
                                    _deviceId,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 13.5,
                                      letterSpacing: 1.4,
                                      fontWeight: FontWeight.w600,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: DesktopTokens.gapSm),
                          DesktopButton.ghost(
                            label: 'نسخ كود الجهاز'.tr(),
                            icon: Icons.copy_rounded,
                            onPressed: () => Clipboard.setData(
                              ClipboardData(text: _deviceId),
                            ),
                          ),
                          const SizedBox(height: DesktopTokens.gapLg),
                          Text(
                            'كود التفعيل (من المهندس):'.tr(),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: DesktopTokens.gapSm),
                          TextField(
                            controller: _codeCtrl,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.done,
                            // دوسة Enter هنا بتنفذ نفس منطق زرار "تفعيل البرنامج".
                            onSubmitted: (_) {
                              if (!_activating) _activate();
                            },
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'XXXX-XXXX-XXXX-XXXX-XXXX',
                              hintStyle: TextStyle(
                                color: palette.textMuted,
                                fontFamily: 'monospace',
                                letterSpacing: 2,
                              ),
                              filled: true,
                              fillColor: palette.surfaceSoft,
                              errorText: _errorMsg,
                              errorStyle: TextStyle(
                                color: palette.danger,
                                fontSize: 12,
                              ),
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
                                borderSide: BorderSide(
                                  color: palette.accent,
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DesktopTokens.radiusMd,
                                ),
                                borderSide: BorderSide(color: palette.danger),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DesktopTokens.radiusMd,
                                ),
                                borderSide: BorderSide(
                                  color: palette.danger,
                                  width: 1.5,
                                ),
                              ),
                              suffixIcon: IconButton(
                                tooltip: 'لصق'.tr(),
                                icon: Icon(
                                  Icons.paste_rounded,
                                  size: 20,
                                  color: palette.textMuted,
                                ),
                                onPressed: () async {
                                  final data = await Clipboard.getData(
                                    Clipboard.kTextPlain,
                                  );
                                  if (data?.text != null) {
                                    _codeCtrl.text = data!.text!.trim();
                                  }
                                },
                              ),
                            ),
                          ),

                          // ── رسالة نجاح ──
                          if (_successMsg != null) ...[
                            const SizedBox(height: DesktopTokens.gapMd),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: palette.soft(palette.success),
                                borderRadius: BorderRadius.circular(
                                  DesktopTokens.radiusSm,
                                ),
                                border: Border.all(
                                  color: palette.success.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 17,
                                    color: palette.success,
                                  ),
                                  const SizedBox(
                                    width: DesktopTokens.gapSm,
                                  ),
                                  Expanded(
                                    child: Text(
                                      _successMsg!,
                                      style: TextStyle(
                                        color: palette.success,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: DesktopTokens.gapLg),

                          // ── زرار التفعيل ──
                          SizedBox(
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: _activating ? null : _activate,
                              style: FilledButton.styleFrom(
                                backgroundColor: palette.accent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: palette.accent
                                    .withValues(alpha: 0.5),
                                disabledForegroundColor: Colors.white
                                    .withValues(alpha: 0.85),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    DesktopTokens.radiusMd,
                                  ),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              icon: _activating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.verified_rounded,
                                      size: 19,
                                    ),
                              label: Text(
                                _activating
                                    ? 'جاري التفعيل...'.tr()
                                    : 'تفعيل البرنامج',
                              ),
                            ),
                          ),
                          const SizedBox(height: DesktopTokens.gapLg),

                          // ── معلومات الاتصال ──
                          Divider(color: palette.border, height: 1),
                          const SizedBox(height: DesktopTokens.gapMd),
                          Text(
                            'Eng: Waled Mabrok',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone,
                                size: 15,
                                color: palette.success,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '01032548232',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// دائرة ضوء ناعمة تُستخدم كخلفية جرافيكية.
  Widget _glowCircle(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.14),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
