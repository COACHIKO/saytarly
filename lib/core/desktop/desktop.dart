/// مجموعة واجهة سطح المكتب (Windows UI) — استيراد واحد لكل المكونات.
///
/// القاعدة الذهبية لكل شاشة:
/// ```dart
/// Widget build(BuildContext context) {
///   return AppPlatform.isDesktop(context)
///       ? _buildWindowsBody(context)
///       : _buildMobileBody(context);
/// }
/// ```
library;

export 'package:saytarly/core/desktop/desktop_tokens.dart';
export 'package:saytarly/core/desktop/widgets/desktop_card.dart';
export 'package:saytarly/core/desktop/widgets/desktop_controls.dart';
export 'package:saytarly/core/desktop/widgets/desktop_grid.dart';
export 'package:saytarly/core/desktop/widgets/desktop_scaffold.dart';
export 'package:saytarly/core/desktop/widgets/desktop_shell.dart';
export 'package:saytarly/core/desktop/widgets/desktop_sidebar.dart';
export 'package:saytarly/core/desktop/widgets/brand_logo.dart';
export 'package:saytarly/core/desktop/widgets/desktop_stat_card.dart';
export 'package:saytarly/core/desktop/widgets/desktop_theme_toggle.dart';
export 'package:saytarly/core/desktop/widgets/hover_builder.dart';
export 'package:saytarly/core/desktop/widgets/desktop_feedback.dart';
export 'package:saytarly/core/platform/app_platform.dart';
