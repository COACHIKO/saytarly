import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:saytarly/core/desktop/widgets/desktop_controls.dart';
import 'package:saytarly/core/utils/theme/cubit/theme_cubit.dart';
import 'package:saytarly/core/localization/messages.dart';
/// زرار تبديل الوضع الليلي/النهاري — بنفس ستايل أدوات سطح المكتب.
class DesktopThemeToggle extends StatelessWidget {
  const DesktopThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DesktopToolbarIconButton(
      icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      tooltip: isDark ? 'الوضع النهاري'.tr() : 'الوضع الليلي',
      onPressed: () => context.read<ThemeCubit>().toggle(),
    );
  }
}
