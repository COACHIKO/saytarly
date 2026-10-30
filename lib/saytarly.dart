import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/design/saytarly_theme.dart';
import 'core/desktop/widgets/desktop_feedback.dart';
import 'core/localization/cubit/locale_cubit.dart';
import 'core/localization/messages.dart';
import 'core/routing/app_router.dart';
import 'core/utils/theme/cubit/theme_cubit.dart';

/// Root application widget for every app built on the core template.
///
/// SAYTARLY uses a permanent navy + electric-blue identity. Users can switch
/// between light and dark mode and between Arabic and English; they cannot
/// re-tint the product with an arbitrary accent colour.
class SaytarlyApp extends StatelessWidget {
  const SaytarlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => LocaleCubit()..getSavedLanguage()),
        BlocProvider(create: (context) => ThemeCubit()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (BuildContext context, Widget? child) {
          return BlocBuilder<LocaleCubit, ChangeLocaleState>(
            builder: (context, localeState) {
              return BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeState) {
                  final isArabic = localeState.locale.languageCode == 'ar';
                  final fontFamily =
                      isArabic
                          ? SaytarlyTheme.arabicFont
                          : SaytarlyTheme.latinFont;

                  // Keep navigation and the desktop toast overlay on the same
                  // navigator so AppToast can find the overlay everywhere.
                  NavigationService.instance.navigationKey =
                      AppToast.navigatorKey;

                  return MaterialApp(
                    navigatorKey: NavigationService.instance.navigationKey,
                    navigatorObservers: [
                      NavigationService.instance.routeObserver,
                    ],
                    locale: localeState.locale,
                    supportedLocales: Str.supportedLocales,
                    localizationsDelegates: const [
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    localeResolutionCallback: Str.localeResolutionCallback,
                    themeMode: themeState,
                    theme: SaytarlyTheme.light(fontFamily: fontFamily),
                    darkTheme: SaytarlyTheme.dark(fontFamily: fontFamily),
                    themeAnimationDuration: const Duration(milliseconds: 220),
                    themeAnimationCurve: Curves.easeOutCubic,
                    debugShowCheckedModeBanner: false,
                    onGenerateRoute: AppRouter.generateRoute,
                    onGenerateInitialRoutes: (initialRoute) {
                      return [
                        AppRouter.generateRoute(const RouteSettings(name: '/')),
                      ];
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
