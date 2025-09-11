import 'package:auto_route/auto_route.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        //Authenticated Routes
        AutoRoute(
          path: '/main',
          page: MainRoute.page,
          children: [
            AutoRoute(path: 'explore', page: ExploreMainRoute.page),
            AutoRoute(path: 'stylists', page: StylistsMainRoute.page),
            AutoRoute(path: 'appointments', page: AppointementsMainRoute.page),
            AutoRoute(path: 'account', page: AccountMainRoute.page),
          ],
        ),

        //Unauthenticated Routes
        AutoRoute(path: '/', page: LandingRoute.page),
        AutoRoute(path: '/signup', page: SignupRoute.page),
        AutoRoute(path: '/login', page: LoginRoute.page),
        // AutoRoute(path: '/forgot-password', page: ForgotPasswordRoute.page),
        // AutoRoute(path: '/create-password', page: CreatePasswordRoute.page),
      ];

  @override
  List<AutoRouteGuard> get guards => [];
}
