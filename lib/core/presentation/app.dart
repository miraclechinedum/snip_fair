import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snip_fair/core/cubit/app_cubit.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/routing/routes.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/features/onboarding/views/splash_screen.dart';
import 'package:snip_fair/l10n/l10n.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final appRouter = AppRouter();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AppCubit>()..onAppStarted(),
      child: ScreenUtilInit(
        designSize: const Size(402, 874),
        minTextAdapt: true,
        builder: (__, _) {
          return MaterialApp.router(
            routeInformationParser: appRouter.defaultRouteParser(),
            routerDelegate: appRouter.delegate(),
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) {
              return BlocConsumer<AppCubit, AppState>(
                listenWhen: (previous, current) =>
                    previous.status != current.status,
                listener: (context, state) {
                  switch (state.status) {
                    case AuthStatus.initial:
                      break;
                    case AuthStatus.unAuthenticated:
                      appRouter.pushAndPopUntil(
                        LandingRoute(),
                        predicate: (route) => false,
                      );
                    case AuthStatus.authenticated:
                      appRouter.pushAndPopUntil(
                        const MainRoute(),
                        predicate: (route) => false,
                      );
                  }
                },
                builder: (context, state) {
                  if (state.status == AuthStatus.initial) {
                    return const SplashScreen();
                  }
                  return child!;
                },
              );
            },
          );
        },
      ),
    );
  }
}
