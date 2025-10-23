import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/presentation/widgets/support_webview_widget.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/core/utils/environment/environment.dart';
import 'package:snip_fair/core/utils/preferences/app_preferences.dart';
import 'package:snip_fair/core/utils/utils.dart';
import 'package:snip_fair/features/notifications/cubit/notifications_cubit.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

@RoutePage()
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isStylist =
        context.select<AppCubit, bool>((AppCubit bloc) => bloc.state.isStylist);
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Notifications',
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context
                .read<NotificationsCubit>()
                .fetchNotifications(isInitial: true);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height -
                    AppBar().preferredSize.height -
                    MediaQuery.of(context).padding.top, // E
              ),
              child: BlocBuilder<NotificationsCubit, NotificationsState>(
                builder: (context, state) {
                  if (state.notificationsListState.isLoading) {
                    return const SizedBox(
                      height: 400,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final notifications = state.notificationsListState.data ?? [];
                  if (notifications.isEmpty) {
                    return const Center(child: Text('No Notifications Items'));
                  }

                  return InfiniteList(
                    physics: const AlwaysScrollableScrollPhysics(),
                    onFetchData: () async {
                      await context
                          .read<NotificationsCubit>()
                          .fetchNotifications();
                    },
                    isLoading: state.paginationData.isLoadingMore,
                    shrinkWrap: true,
                    hasReachedMax: state.paginationData.hasReachedMax,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return ListTile(
                        tileColor: Colors.white,
                        onTap: () {
                          // Handle notification tap
                          switch (notification.type) {
                            case 'appointment':
                              // Navigate to order details
                              final appointmentId = notification.typeIdentifier;
                              if (isStylist) {
                                // Navigate to stylist order details

                                if (appointmentId != null) {
                                  context.router.push(
                                    SellerAppointmentDetailsRoute(
                                      appointmentId: appointmentId.toString(),
                                    ),
                                  );
                                } else {
                                  context.pop();
                                  // Navigate to Orders tab
                                }
                              } else {
                                // Navigate to customer order details
                                if (appointmentId != null) {
                                  context.router.push(
                                    UpdateCreateAppointmentRoute(
                                      appointmentId: appointmentId.toString(),
                                    ),
                                  );
                                } else {
                                  context.pop();
                                }
                              }
                            case 'wallet':

                              // Navigate to wallet
                              context.router.push(
                                isStylist
                                    ? const SellerEarningRoute()
                                    : const CustomerWalletRoute(),
                              );
                            case 'conversation':
                              context.router.push(
                                ConversationListRoute(),
                              );
                            case 'dispute':
                              final token =
                                  getIt<LocalKeyStorage>().accessToken;
                              if (token == null) return;
                              final supportUrl = Environment()
                                  .config
                                  .apiHost
                                  .replaceAll('api', 'disputes');
                              context.router.pushWidget(
                                SupportWebViewWidget(
                                  supportUrl: supportUrl,
                                  authToken: token,
                                ),
                              );
                            default:
                              // Default action
                              break;
                          }
                        },
                        title: AppText(
                          text: notification.title ?? 'No Title',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        subtitle: AppText(
                          text: notification.description ?? 'No Message',
                          maxLines: 2,
                          color: Colors.grey,
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppText(
                              text: notification.createdAt.toTimeAgo(),
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            8.verticalSpace,
                            const CircleAvatar(
                              radius: 5,
                              backgroundColor: Colors.red,
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: notifications.length,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
