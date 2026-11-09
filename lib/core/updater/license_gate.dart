import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:saytarly/core/design/saytarly_brand.dart';
import 'package:saytarly/core/design/saytarly_theme.dart';
import 'package:saytarly/core/design/widgets/saytarly_brand_mark.dart';
import 'package:saytarly/core/localization/messages.dart';
import 'package:saytarly/core/updater/device_registry.dart';
import 'package:saytarly/core/updater/update_service.dart';
import 'package:saytarly/core/utils/theme/cubit/theme_cubit.dart';
import 'package:saytarly/saytarly.dart';

/// رابط صفحة "تواصل معنا" — عدّله لو الدومين اتغير.
const String kSaytarlyContactUrl = 'https://saytarly.com/contact';

/// بوابة الترخيص — في الوضع الأونلاين مش بتوصل للوجين غير لما
/// الترخيص يكون مفعّل (active/unlimited). بيعيد الفحص لو الترخيص
/// pending/expired، وبيفتح التطبيق أول ما يتفعّل.
///
/// الهوية البصرية بتتبع نظام البراند نفسه (نافي غامق + أزرق كهربائي):
/// خلفية loginPanel، الشبكة الرقيقة، ظل الـ S الشبح، ولمسة واحدة من
/// اللون الأزرق — الألوان التانية بتظهر بس لما يكون ليها معنى (حالة
/// الترخيص: تفعيل / انتهاء / انتظار).
class LicenseGateApp extends StatelessWidget {
  const LicenseGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    // لو المراقب الدوري قفل التطبيق — نرجع للبوابة من جديد.
    LicenseWatcher.onLock = () => runApp(const LicenseGateApp());

    return BlocProvider<ThemeCubit>(
      create: (_) => ThemeCubit(),
      child: Builder(
        builder: (context) {
          return BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                themeMode: mode,
                theme: SaytarlyTheme.light(
                  fontFamily: SaytarlyTheme.arabicFont,
                ),
                darkTheme: SaytarlyTheme.dark(
                  fontFamily: SaytarlyTheme.arabicFont,
                ),
                home: Directionality(
                  textDirection: TextDirection.rtl,
                  child: LicenseGateScreen(
                    onUnlocked: () {
                      LicenseWatcher.instance.start();
                      runApp(const SaytarlyApp());
                      // فحص التحديثات يبدأ بعد ما التطبيق يفتح فعلاً.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        unawaited(UpdateService.instance.checkOnStartup());
                      });
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class LicenseGateScreen extends StatefulWidget {
  const LicenseGateScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<LicenseGateScreen> createState() => _LicenseGateScreenState();
}

class _LicenseGateScreenState extends State<LicenseGateScreen> {
  LicenseResult? _result;
  bool _checking = true;
  bool _unlocking = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final result = await DeviceRegistry.instance.checkLicense();
    if (!mounted) return;
    setState(() {
      _result = result;
      _checking = false;
    });
    if (result.isAllowed) {
      _scheduleUnlock();
    } else {
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(seconds: 30), _check);
    }
  }

  void _scheduleUnlock() {
    if (_unlocking) return;
    _unlocking = true;
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) widget.onUnlocked();
    });
  }

  Future<void> _copyCode() async {
    final code = _result?.deviceCode ?? '';
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ كود الجهاز'.tr()),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openContact() async {
    final uri = Uri.parse(kSaytarlyContactUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(uri);
    }
  }

  // ── ألوان الحالة: لون براند واحد + ألوان دلالية بس لما يكون ليها معنى ──
  Color _statusColor(DeviceLicenseStatus? status) {
    switch (status) {
      case DeviceLicenseStatus.unlimited:
      case DeviceLicenseStatus.active:
        return const Color(0xFF22C55E);
      case DeviceLicenseStatus.expired:
      case DeviceLicenseStatus.blocked:
        return const Color(0xFFF87171);
      case DeviceLicenseStatus.pending:
        return const Color(0xFFFBBF24);
      case null:
        return SaytarlyColors.darkAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── خلفية البراند: نافي غامق + شبكة رقيقة + S الشبح + توهجات ──
          const Positioned.fill(child: _GateBackdrop()),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildCard(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final status = _result?.status;
    final accent = _statusColor(status);

    return Container(
      width: 480,
      padding: const EdgeInsets.fromLTRB(32, 34, 32, 26),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.14),
            blurRadius: 70,
            offset: const Offset(0, 26),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 40,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Entrance(delayMs: 0, child: _logoSection(accent)),
          const SizedBox(height: 24),
          _Entrance(delayMs: 130, child: _statusSection(accent)),
          const SizedBox(height: 22),
          _Entrance(delayMs: 260, child: _deviceSection()),
          const SizedBox(height: 20),
          _Entrance(delayMs: 390, child: _actionSection()),
          const SizedBox(height: 18),
          _Entrance(delayMs: 500, child: _footer()),
        ],
      ),
    );
  }

  // ── اللوجو الرسمي داخل هالة نابضة + حلقة مسح دوّارة وقت الفحص ──
  Widget _logoSection(Color accent) {
    return Column(
      children: [
        SizedBox(
          width: 112,
          height: 112,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _PulsingHalo(color: accent),
              if (_checking) const _SpinningRing(),
              const SaytarlyBrandMark(size: 58, onDark: true, showGlow: true),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            'SAYTARLY',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 7,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.9),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'بوابة الترخيص'.tr(),
                style: const TextStyle(
                  color: SaytarlyColors.darkTextSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusSection(Color accent) {
    if (_checking) {
      return Column(
        children: [
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: SaytarlyColors.darkAccent,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'التحقق من الترخيص…'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'بنشوف جهازك مسجل ولا لأ…'.tr(),
            style: const TextStyle(
              color: SaytarlyColors.darkTextMuted,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    final status = _result?.status ?? DeviceLicenseStatus.pending;
    final color = _statusColor(status);
    final IconData icon;
    final String title;
    final String subtitle;
    switch (status) {
      case DeviceLicenseStatus.unlimited:
        icon = Icons.workspace_premium_rounded;
        title = 'الترخيص مفعّل — مدى الحياة'.tr();
        subtitle = 'الترخيص مفعّل — جاري الفتح…'.tr();
      case DeviceLicenseStatus.active:
        icon = Icons.check_circle_rounded;
        title = 'الترخيص مفعّل'.tr();
        subtitle = 'الترخيص مفعّل — جاري الفتح…'.tr();
      case DeviceLicenseStatus.expired:
        icon = Icons.gpp_bad_rounded;
        title = 'الترخيص منتهي'.tr();
        subtitle = 'جدد الترخيص عشان تقدر تكمل استخدام التطبيق'.tr();
      case DeviceLicenseStatus.blocked:
        icon = Icons.block_rounded;
        title = 'تم حظر هذا الجهاز'.tr();
        subtitle = 'الجهاز ده محظور — تواصل مع الدعم عشان تعرف السبب'.tr();
      case DeviceLicenseStatus.pending:
        icon = Icons.hourglass_top_rounded;
        title = 'بانتظار تفعيل الترخيص'.tr();
        subtitle = 'جهازك متسجل — ابعت كود الجهاز للدعم عشان يتفعل'.tr();
    }

    return Column(
      children: [
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.10),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 26),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder:
                (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
            child: Icon(
              icon,
              key: ValueKey<DeviceLicenseStatus>(status),
              size: 32,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: SaytarlyColors.darkTextSecondary,
            fontSize: 12.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _deviceSection() {
    if (_checking) return const SizedBox.shrink();
    final code = _result?.deviceCode ?? '';
    final pc = _result?.pcName ?? '';
    if (code.isEmpty && pc.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.computer_rounded,
                size: 16,
                color: SaytarlyColors.darkAccent,
              ),
              const SizedBox(width: 8),
              Text(
                'اسم الجهاز: {v1}'.tr({'v1': pc}),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _copyCode,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: SaytarlyColors.darkSurfaceSunken,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: SaytarlyColors.darkBorder.withValues(alpha: 0.9),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.copy_rounded,
                        size: 13,
                        color: SaytarlyColors.darkTextMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'كود الجهاز — اضغط لنسخه'.tr(),
                        style: const TextStyle(
                          color: SaytarlyColors.darkTextMuted,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    code,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF93C5FD),
                      fontSize: 12.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
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

  Widget _actionSection() {
    if (_checking) return const SizedBox.shrink();
    if (_result?.isAllowed ?? false) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF22C55E),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'الترخيص مفعّل — جاري الفتح…'.tr(),
            style: const TextStyle(color: Color(0xFF22C55E), fontSize: 13),
          ),
        ],
      );
    }

    return Column(
      children: [
        _BrandButton(
          onPressed: _check,
          icon: Icons.refresh_rounded,
          label: 'إعادة المحاولة'.tr(),
        ),
        const SizedBox(height: 10),
        Text(
          'بيتعاد الفحص تلقائيًا كل 30 ثانية'.tr(),
          style: const TextStyle(
            color: SaytarlyColors.darkTextMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _footer() {
    return Column(
      children: [
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 40),
          color: Colors.white.withValues(alpha: 0.08),
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: _openContact,
          style: TextButton.styleFrom(
            foregroundColor: SaytarlyColors.darkTextSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          icon: const Icon(Icons.support_agent_rounded, size: 18),
          label: Text('تواصل معنا — saytarly.com/contact'.tr()),
        ),
      ],
    );
  }
}

// ============================ عناصر بصرية ============================

/// خلفية البراند: تدرج loginPanel + شبكة + S الشبح + توهجات ناعمة.
class _GateBackdrop extends StatelessWidget {
  const _GateBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: SaytarlyGradients.loginPanel),
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _GateGridPainter()),
            ),
          ),
          Positioned(
            top: -140,
            left: -100,
            child: _glow(Colors.white, 480, 0.05),
          ),
          Positioned(
            bottom: -170,
            right: -120,
            child: _glow(SaytarlyColors.controlBlue, 540, 0.16),
          ),
          // الـ S الشبح — عمق البراند من غير ما ينافس المحتوى.
          const Positioned(
            left: -120,
            bottom: -100,
            child: SaytarlyLogoWatermark(width: 640, rotation: -0.10),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: alpha), Colors.transparent],
        ),
      ),
    );
  }
}

/// شبكة رفيعة — نفس توقيع شاشة الدخول.
class _GateGridPainter extends CustomPainter {
  const _GateGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.03)
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
  bool shouldRepaint(covariant _GateGridPainter oldDelegate) => false;
}

/// زر البراند — تدرج أزرق كهربائي مع توهج ناعم.
class _BrandButton extends StatelessWidget {
  const _BrandButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: SaytarlyGradients.controlBlue,
          borderRadius: BorderRadius.circular(13),
          boxShadow: const [...SaytarlyShadows.blueGlow],
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: Colors.white),
                const SizedBox(width: 9),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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

/// هالة نابضة حوالين اللوجو — لونها بيتبع حالة الترخيص.
class _PulsingHalo extends StatefulWidget {
  const _PulsingHalo({required this.color});

  final Color color;

  @override
  State<_PulsingHalo> createState() => _PulsingHaloState();
}

class _PulsingHaloState extends State<_PulsingHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final scale = 0.94 + 0.06 * _controller.value;
        final opacity = 0.18 + 0.22 * _controller.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 106,
            height: 106,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.color.withValues(alpha: opacity),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: opacity * 0.7),
                  blurRadius: 34,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// حلقة مسح دوّارة وقت الفحص — زي إشارة الرادار حوالين اللوجو.
class _SpinningRing extends StatefulWidget {
  const _SpinningRing();

  @override
  State<_SpinningRing> createState() => _SpinningRingState();
}

class _SpinningRingState extends State<_SpinningRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: 106,
        height: 106,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              Colors.transparent,
              Colors.transparent,
              SaytarlyColors.darkAccent,
              Colors.transparent,
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

/// دخول متدرج — عناصر البطاقة بتظهر واحدة ورا واحدة بنعومة.
class _Entrance extends StatefulWidget {
  const _Entrance({required this.delayMs, required this.child});

  final int delayMs;
  final Widget child;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _controller,
    curve: Interval(widget.delayMs / 900, 1, curve: Curves.easeOutCubic),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, child) {
        return Opacity(
          opacity: _curved.value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - _curved.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
