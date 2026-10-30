part of '../login.dart';

/// Windows login screen.
///
/// Split layout: a focused sign-in card on the canvas, and a deep-navy brand
/// panel that sells the product without stealing attention from the form.
extension _LoginWindowsBody on _LoginViewState {
  Widget _buildWindowsBody(BuildContext context) {
    final viewModel = context.watch<LoginCubit>().state;
    final palette = DesktopPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showBrand = constraints.maxWidth >= 1000;

          final formSide = Stack(
            children: [
              Positioned(
                top: -180,
                left: -140,
                child: _glowCircle(palette.accent, 460),
              ),
              Positioned(
                bottom: -160,
                right: -120,
                child: _glowCircle(palette.info, 420),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(26, 20, 26, 0),
                    child: Row(
                      children: [
                        const SaytarlyLogo(markSize: 32, showTagline: false),
                        const Spacer(),
                        const _LanguageSwitch(),
                        const SizedBox(width: 6),
                        const DesktopThemeToggle(),
                        // const SizedBox(width: 2),
                        // DrinksScreenModeButton(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 30,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 412),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'مرحبًا بعودتك'.tr(),
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: palette.textPrimary,
                                  fontSize: 29,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                'سجّل الدخول لإدارة {v1}'.tr({
                                  'v1': viewModel.placeName,
                                }),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: palette.textMuted,
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: DesktopTokens.gapLg),
                              DesktopCard(
                                padding: const EdgeInsets.all(24),
                                radius: DesktopTokens.radiusXl,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _desktopTextField(
                                      controller: _userCtl,
                                      focusNode: _userFocus,
                                      label: 'اسم المستخدم'.tr(),
                                      icon: Icons.person_outline_rounded,
                                      action: TextInputAction.next,
                                      onSubmitted:
                                          (_) => FocusScope.of(
                                            context,
                                          ).requestFocus(_passFocus),
                                    ),
                                    const SizedBox(height: DesktopTokens.gapMd),
                                    _desktopTextField(
                                      controller: _passCtl,
                                      focusNode: _passFocus,
                                      label: 'كلمة المرور'.tr(),
                                      icon: Icons.lock_outline_rounded,
                                      action: TextInputAction.done,
                                      onSubmitted: (_) => _login(),
                                      obscure: _obscurePassword,
                                      suffix: IconButton(
                                        splashRadius: 20,
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 19,
                                          color: palette.textMuted,
                                        ),
                                        onPressed:
                                            () => _refresh(
                                              () =>
                                                  _obscurePassword =
                                                      !_obscurePassword,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: DesktopTokens.gapLg),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 46,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            DesktopTokens.radiusMd,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: palette.accent.withValues(
                                                alpha: 0.22,
                                              ),
                                              blurRadius: 18,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: FilledButton(
                                          onPressed:
                                              viewModel.loading ? null : _login,
                                          style: FilledButton.styleFrom(
                                            backgroundColor: palette.accent,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    DesktopTokens.radiusMd,
                                                  ),
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          child:
                                              viewModel.loading
                                                  ? const SizedBox(
                                                    width: 21,
                                                    height: 21,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2.3,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                  : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text('دخول'.tr()),
                                                      const SizedBox(width: 8),
                                                      const Icon(
                                                        Icons
                                                            .arrow_forward_rounded,
                                                        size: 18,
                                                      ),
                                                    ],
                                                  ),
                                        ),
                                      ),
                                    ),
                                    if (viewModel.error != null) ...[
                                      const SizedBox(
                                        height: DesktopTokens.gapMd,
                                      ),
                                      _LoginError(message: viewModel.error!),
                                    ],
                                    const SizedBox(height: DesktopTokens.gapMd),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.verified_user_outlined,
                                          size: 13,
                                          color: palette.textMuted,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'دخول آمن على هذا الجهاز'.tr(),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color: palette.textMuted,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: DesktopTokens.gapLg),
                              Center(
                                child: Text(
                                  'SAYTARLY • Restaurant & Café Management',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelSmall?.copyWith(
                                    color: palette.textMuted.withValues(
                                      alpha: 0.75,
                                    ),
                                    fontSize: 9.5,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );

          if (!showBrand) return formSide;

          return Row(
            children: [
              Expanded(flex: 44, child: formSide),
              const Expanded(flex: 56, child: _LoginBrandPanel()),
            ],
          );
        },
      ),
    );
  }

  Widget _desktopTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    TextInputAction? action,
    ValueChanged<String>? onSubmitted,
    bool obscure = false,
    Widget? suffix,
  }) {
    final palette = DesktopPalette.of(context);

    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: action,
      onSubmitted: onSubmitted,
      obscureText: obscure,
      style: TextStyle(
        color: palette.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: palette.textMuted, fontSize: 13),
        floatingLabelStyle: TextStyle(
          color: palette.accentText,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, size: 19, color: palette.textMuted),
        suffixIcon: suffix,
        filled: true,
        fillColor: palette.surfaceSoft,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
          borderSide: BorderSide(color: palette.accent, width: 1.4),
        ),
      ),
    );
  }

  Widget _glowCircle(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch();

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final isArabic = Str.isRtl;

    return Tooltip(
      message: isArabic ? 'English' : 'العربية',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap:
              () => context.read<LocaleCubit>().changeLanguage(
                isArabic ? 'en' : 'ar',
              ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(DesktopTokens.radiusSm + 2),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 14,
                  color: palette.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  isArabic ? 'EN' : 'عربي',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginError extends StatelessWidget {
  const _LoginError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.soft(palette.danger),
        borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
        border: Border.all(color: palette.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 17,
            color: palette.onSoft(palette.danger),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: palette.onSoft(palette.danger),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Marketing side of the login screen.
class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(gradient: SaytarlyGradients.loginPanel),
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _GridPatternPainter()),
            ),
          ),
          Positioned(
            top: -130,
            right: -100,
            child: _glow(Colors.white, 460, 0.07),
          ),
          Positioned(
            bottom: -170,
            left: -120,
            child: _glow(SaytarlyColors.controlBlue, 520, 0.20),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(48, 38, 48, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SaytarlyLogo(markSize: 42, onDark: true, showGlow: true),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: SaytarlyColors.darkAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'منصة إدارة المطاعم والكافيهات'.tr(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'أدر مطعمك\nبذكاء وهدوء.'.tr(),
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 42,
                    height: 1.28,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Text(
                    'من الكاشير والمخزون إلى الرواتب والتقارير — كل عملياتك في منصة واحدة، واضحة وسريعة ومصمّمة لسطح المكتب.'
                        .tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 14,
                      height: 1.8,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _feature(
                      context,
                      Icons.point_of_sale_rounded,
                      'كاشير ومبيعات لحظية'.tr(),
                    ),
                    _feature(
                      context,
                      Icons.inventory_2_outlined,
                      'مخزون وخامات'.tr(),
                    ),
                    _feature(
                      context,
                      Icons.insights_rounded,
                      'تقارير وربحية'.tr(),
                    ),
                    _feature(
                      context,
                      Icons.badge_outlined,
                      'موظفين ورواتب'.tr(),
                    ),
                    _feature(
                      context,
                      Icons.table_restaurant_outlined,
                      'ترابيزات وبلايستيشن'.tr(),
                    ),
                    _feature(
                      context,
                      Icons.print_outlined,
                      'فواتير وطباعة'.tr(),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.055),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      _trustItem(
                        context,
                        Icons.language_rounded,
                        'عربي / English'.tr(),
                      ),
                      _divider(),
                      _trustItem(
                        context,
                        Icons.wifi_off_rounded,
                        'يعمل محليًا'.tr(),
                      ),
                      _divider(),
                      _trustItem(
                        context,
                        Icons.shield_outlined,
                        'بياناتك على جهازك'.tr(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'SAYTARLY • Restaurant & Café Management',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    fontSize: 9.5,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feature(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      width: 236,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trustItem(BuildContext context, IconData icon, String label) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.64)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 9.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withValues(alpha: 0.10),
    );
  }

  Widget _glow(Color color, double size, double alpha) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  const _GridPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.035)
          ..strokeWidth = 1;
    const step = 52.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPatternPainter oldDelegate) => false;
}
