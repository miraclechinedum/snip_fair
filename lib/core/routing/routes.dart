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
            AutoRoute(path: 'dashboard', page: SellerDashboardMainRoute.page),
            AutoRoute(path: 'search', page: SearchMainRoute.page),
            AutoRoute(path: 'appointments', page: AppointementsMainRoute.page),
            AutoRoute(
              path: 'stylist-appointments',
              page: SellerAppointmentsMainRoute.page,
            ),
            AutoRoute(path: 'account', page: AccountMainRoute.page),
          ],
        ),
        AutoRoute(
            path: '/seller-profile', page: StylistSellerDetailsRoute.page),
        AutoRoute(path: '/stylist-more-info', page: StylistMoreInfoRoute.page),

        //Shared
        AutoRoute(
          path: '/change-password',
          page: ChangePasswordRoute.page,
        ),
        AutoRoute(
          path: '/conversation-list',
          page: ConversationListRoute.page,
        ),
        AutoRoute(
          path: '/conversation-chat',
          page: ConvesationChatRoute.page,
        ),
        AutoRoute(
          path: '/disputes',
          page: DisputesRoute.page,
        ),
        AutoRoute(
          path: '/notifications',
          page: NotificationsRoute.page,
        ),

        /// Customer Specific Routes
        ///
        AutoRoute(
          path: '/customer-profile-details',
          page: CustomerPersonalDetailsRoute.page,
        ),

        AutoRoute(
          path: '/customer-wallet',
          page: CustomerWalletRoute.page,
        ),
        AutoRoute(
          path: '/customer-favorites',
          page: CustomerFavoritesRoute.page,
        ),
        AutoRoute(
          path: '/update-create-appointment',
          page: UpdateCreateAppointmentRoute.page,
        ),
        AutoRoute(
          path: '/customer-appointment-calendar',
          page: CustomerAppointmentsCalendarRoute.page,
        ),

        /// Seller Specific Routes
        ///
        AutoRoute(
          path: '/seller-personal-details',
          page: SellerPersonalDetailsRoute.page,
        ),
        AutoRoute(
          path: '/seller-profile-management',
          page: SellerProfileManagementRoute.page,
        ),
        AutoRoute(
          path: '/seller-profile-verification',
          page: SellerProfileVerificationRoute.page,
        ),
        AutoRoute(
          path: '/seller-works',
          page: SellerWorkRoute.page,
        ),
        AutoRoute(
          path: '/seller-payment-methods',
          page: SellerPaymentMethodsRoute.page,
        ),
        AutoRoute(
          path: '/seller-portfolio',
          page: SellerPortfolioRoute.page,
        ),
        AutoRoute(
          path: '/seller-earnings',
          page: SellerEarningRoute.page,
        ),
        AutoRoute(
          path: '/seller-availability-schedue',
          page: SellerAvailabilityScheduleRoute.page,
        ),
        AutoRoute(
          path: '/seller-appointment-details',
          page: SellerAppointmentDetailsRoute.page,
        ),
        AutoRoute(
          path: '/seller-appointment-calendar',
          page: SellerAppointmentsCalendarRoute.page,
        ),

        // Become Seller
        AutoRoute(
          path: '/stylist-business-create',
          page: SellerBusinessCreateRoute.page,
        ),
        AutoRoute(
          path: '/stylist-business-id-verify',
          page: StylistBusinessIdVerifyRoute.page,
        ),

        //Unauthenticated Routes
        AutoRoute(path: '/', page: LandingRoute.page),
        AutoRoute(path: '/signup', page: SignupRoute.page),
        AutoRoute(path: '/login', page: LoginRoute.page),
        AutoRoute(path: '/verify-email', page: VerifyEmailRoute.page),
        AutoRoute(path: '/forgot-password', page: ForgotPasswordRoute.page),
        // AutoRoute(path: '/create-password', page: CreatePasswordRoute.page),
      ];

  @override
  List<AutoRouteGuard> get guards => [];
}
