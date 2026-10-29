import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/utils/theme/cubit/theme_cubit.dart';
import 'package:saytarly/core/widgets/BACKGROUND.dart';
import 'package:saytarly/Features/auth/logic/cubit/login_cubit.dart';
import 'package:saytarly/Features/auth/viewmodel/current_user.dart';
import 'package:saytarly/Features/cashier/presentation/widgets/addDrinkMode.dart';
import 'package:saytarly/Features/dashboard/presentation/screens/staff_dashboard.dart';
import 'package:saytarly/Features/superadmin/presentation/screens/super_admin_dashboard.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/login_mobile_body.dart';
part 'desktop/login_windows_body.dart';

/// شاشة تسجيل الدخول — عرض بس.
///
/// - الموبايل: [login_mobile_body.dart]
/// - الويندوز: [login_windows_body.dart]
///
/// كل منطق الدخول موجود في [LoginViewModel] والبيانات في AuthRepository.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit()..loadPlaceName(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _userCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();
  bool _obscurePassword = true;

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

  @override
  void dispose() {
    _userFocus.dispose();
    _passFocus.dispose();
    _userCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  /// بتنادي الـ Cubit، وبعد النجاح بس بتوجّه المستخدم حسب دوره.
  Future<void> _login() async {
    final viewModel = context.read<LoginCubit>();

    final outcome = await viewModel.login(
      username: _userCtl.text,
      password: _passCtl.text,
    );

    if (!mounted || outcome == null) return;

    switch (outcome.role) {
      case 'cashier':
      case 'staff': // دور قديم — الدور بيتحقق بعد الترحيل، عشان السلامة فقط
        // pushReplacement عشان شاشة اللوجين تخرج من الستاك — كده الشاشات
        // الرئيسية بتبقى جذر (root) والرجوع التلقائي في أجسام الويندوز
        // بيبان بس في الشاشات اللي متدخلة من شاشة تانية (زي من السوبر ادمن).
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StaffDashboard(
              staffName: outcome.username,
              shiftId: outcome.shiftId!,
              staffId: outcome.userId,
              supervisorShiftId: outcome.shiftId!,
            ),
          ),
        );
      case 'superadmin':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuperAdminDashboard()),
        );
      default:
        Navigator.pushReplacementNamed(context, '/admin');
    }
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}
