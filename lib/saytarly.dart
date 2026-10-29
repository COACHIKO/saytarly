import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/localization/cubit/locale_cubit.dart';
import 'core/localization/messages.dart';
import 'core/routing/app_router.dart';
import 'core/utils/theme/cubit/accent_color_cubit.dart';
import 'core/utils/theme/cubit/theme_cubit.dart';
import 'core/utils/theme/theme.dart';

/// Root application widget for every app built on the core template.
///
/// Wires the core subsystems: localization ([LocaleCubit]), theming
/// ([ThemeCubit]) and accent color ([AccentColorCubit]) with the
/// central [AppRouter].
class SaytarlyApp extends StatelessWidget {
  const SaytarlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => LocaleCubit()..getSavedLanguage()),
        BlocProvider(create: (context) => ThemeCubit()),
        BlocProvider(create: (context) => AccentColorCubit()),
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
                  return BlocBuilder<AccentColorCubit, Color>(
                    builder: (context, accentColor) {
                      final isArabic =
                          localeState.locale.languageCode == 'ar';
                      final fontFamily = isArabic ? 'Alexandria' : null;

                      return MaterialApp(
                        navigatorKey: NavigationService.instance.navigationKey,
                        navigatorObservers: [
                          NavigationService.instance.routeObserver
                        ],
                        locale: localeState.locale,
                        supportedLocales: Str.supportedLocales,
                        localizationsDelegates: const [
                          GlobalMaterialLocalizations.delegate,
                          GlobalWidgetsLocalizations.delegate,
                          GlobalCupertinoLocalizations.delegate,
                        ],
                        localeResolutionCallback:
                            Str.localeResolutionCallback,
                        themeMode: themeState,
                        theme: TAppTheme.lightTheme.copyWith(
                          primaryColor: accentColor,
                          textTheme: TAppTheme.lightTheme.textTheme.apply(
                            fontFamily: fontFamily,
                          ),
                          colorScheme: TAppTheme.lightTheme.colorScheme
                              .copyWith(
                            primary: accentColor,
                            secondary: accentColor,
                          ),
                        ),
                        darkTheme: TAppTheme.darkTheme.copyWith(
                          primaryColor: accentColor,
                          textTheme: TAppTheme.darkTheme.textTheme.apply(
                            fontFamily: fontFamily,
                          ),
                          colorScheme: TAppTheme.darkTheme.colorScheme
                              .copyWith(
                            primary: accentColor,
                            secondary: accentColor,
                          ),
                        ),
                        debugShowCheckedModeBanner: false,
                        onGenerateRoute: AppRouter.generateRoute,
                        onGenerateInitialRoutes: (initialRoute) {
                          return [
                            AppRouter.generateRoute(
                              const RouteSettings(name: '/'),
                            ),
                          ];
                        },
                      );
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
