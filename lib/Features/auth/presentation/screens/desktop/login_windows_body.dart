part of '../login.dart';

/// جسم شاشة تسجيل الدخول — نسخة الويندوز (Windows UI).
///
/// تقسيم الشاشة: فورم الدخول على اليمين، ولوحة البراند الجرافيكية على
/// الشمال — تجربة سطح مكتب كاملة بالكيبورد والهوفر.
extension _LoginWindowsBody on _LoginViewState {
  Widget _buildWindowsBody(BuildContext context) {
    final viewModel = context.watch<LoginCubit>().state;
    final palette = DesktopPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // على الشاشات الضيقة بنخفي لوحة البراند ونسيب الفورم لوحده.
          final showBrand = constraints.maxWidth >= 980;

          final formSide = Stack(
            children: [
              // لمسة ضوء ناعمة في الخلفية
              Positioned(
                top: -140,
                left: -100,
                child: _glowCircle(palette.accent, 380),
              ),
              Positioned(
                top: 14,
                left: 18,
                child: Row(
                  children: [
                    const DesktopThemeToggle(),
                    DrinksScreenModeButton(),
                  ],
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 40,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          viewModel.placeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: palette.textPrimary,
                                    fontSize: 30,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'تسجيل الدخول'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: palette.textMuted,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: DesktopTokens.gapLg),
                        DesktopCard(
                          padding: const EdgeInsets.all(26),
                          radius: DesktopTokens.radiusXl,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _desktopTextField(
                                controller: _userCtl,
                                focusNode: _userFocus,
                                label: 'اسم المستخدم'.tr(),
                                icon: Icons.person_outline,
                                action: TextInputAction.next,
                                onSubmitted: (_) => FocusScope.of(context)
                                    .requestFocus(_passFocus),
                              ),
                              const SizedBox(height: DesktopTokens.gapMd),
                              _desktopTextField(
                                controller: _passCtl,
                                focusNode: _passFocus,
                                label: 'كلمة المرور'.tr(),
                                icon: Icons.lock_outline,
                                action: TextInputAction.done,
                                onSubmitted: (_) => _login(),
                                obscure: _obscurePassword,
                                suffix: IconButton(
                                  splashRadius: 20,
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                    color: palette.textMuted,
                                  ),
                                  onPressed: () => _refresh(
                                    () =>
                                        _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                               SizedBox(height: DesktopTokens.gapLg),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: FilledButton(
                                  onPressed:
                                      viewModel.loading ? null : _login,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: palette.accent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        DesktopTokens.radiusMd,
                                      ),
                                    ),
                                    textStyle:  TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  child: viewModel.loading
                                      ?  SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Colors.white,
                                          ),
                                        )
                                      :  Text('دخول'.tr()),
                                ),
                              ),
                              if (viewModel.error != null) ...[
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
                                      color: palette.danger
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 17,
                                        color: palette.danger,
                                      ),
                                      const SizedBox(
                                        width: DesktopTokens.gapSm,
                                      ),
                                      Expanded(
                                        child: Text(
                                          viewModel.error!,
                                          style: TextStyle(
                                            color: palette.danger,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );

          if (!showBrand) return formSide;

          return Row(
            children: [
              Expanded(flex: 5, child: formSide),
              const Expanded(flex: 6, child: _LoginBrandPanel()),
            ],
          );
        },
      ),
    );
  }

  /// خانة إدخال بشكل سطح المكتب — ناعمة ومتسقة مع باقي الصفحات.
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
      textDirection: TextDirection.rtl,
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
              color.withValues(alpha: 0.16),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// لوحة البراند الجرافيكية — النص التجاري + المزايا + بيانات المطوّر.
class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel();

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    final deep = Color.lerp(palette.accent, const Color(0xFF060D1C), 0.82)!;
    final mid = Color.lerp(palette.accent, const Color(0xFF0B1426), 0.55)!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [deep, mid],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _glow(Colors.white, 400, 0.09),
          ),
          Positioned(
            bottom: -130,
            left: -60,
            child: _glow(palette.accent, 420, 0.22),
          ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          DesktopTokens.radiusMd,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.local_cafe_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: DesktopTokens.gapMd),
                    Expanded(
                      child: Text(
                        'نظام إدارة الكافيه'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'كل حاجة في الكافيه\nمن شاشة واحدة'.tr(),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 34,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: DesktopTokens.gapMd),
                Text(
                  ('كاشير، أقسام ومنتجات، مخزون وخامات، بلايستيشن، وتقارير — '.tr() + 'كلها مظبوطة ومن غير ورق.'.tr()),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 14.5,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: DesktopTokens.gapXl),
                _feature(context, Icons.point_of_sale_outlined,
                    'كاشير ومبيعات لحظية'.tr()),
                _feature(context, Icons.category_outlined,
                    'أقسام ومنتجات قابلة للتخصيص'.tr()),
                _feature(context, Icons.inventory_2_outlined,
                    'خامات ومخزون مشترك بين الأقسام'.tr()),
                _feature(context, Icons.sports_esports_outlined,
                    'إدارة بلايستيشن وترابيزات'.tr()),
                _feature(context, Icons.insights_outlined,
                    'تقارير ورديات مفصّلة'.tr()),
                const Spacer(),
                Divider(color: Colors.white.withValues(alpha: 0.14)),
                const SizedBox(height: DesktopTokens.gapSm),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Eng: Waled Mabrok',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.phone,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '01032548232',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feature(BuildContext context, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesktopTokens.gapMd),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: DesktopTokens.gapMd),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
            ),
          ),
        ],
      ),
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
