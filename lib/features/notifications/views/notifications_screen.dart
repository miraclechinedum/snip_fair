import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/notifications_list/notification_datum.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
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

                  return SafeArea(
                    child: InfiniteList(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, top: 12, bottom: 100),
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
                        return NotificationTile(notification: notification);
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: notifications.length,
                    ),
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

class NotificationTile extends StatefulWidget {
  const NotificationTile({
    super.key,
    required this.notification,
  });

  final NotificationDatum notification;

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  bool _isRead = false;

  @override
  void didChangeDependencies() {
    if (widget.notification.isRead ?? false) {
      _isRead = true;
    }
    super.didChangeDependencies();
  }

  void _markAsRead() {
    if (!_isRead) {
      setState(() {
        _isRead = true;
      });
      context
          .read<NotificationsCubit>()
          .markNotificationAsRead(widget.notification.id!);
    }
  }

  void _showNotificationDialog() {
    _markAsRead();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        title: AppText(
          text: widget.notification.title ?? 'Notification',
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
        content: AppText(
          text: widget.notification.description ?? 'No details available',
          fontSize: 14.sp,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const AppText(
              text: 'Cancel',
            ),
          ),
          CustomButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToNotificationDestination();
            },
            title: 'View',
          ),
        ],
      ),
    );
  }

  void _navigateToNotificationDestination() {
    final isStylist = context.read<AppCubit>().state.isStylist;

    switch (widget.notification.type) {
      case 'profile':
        if (isStylist) {
          context.router.push(const SellerProfileManagementRoute());
        } else {
          context.router.push(const CustomerProfileMgtRoute());
        }
      case 'appointment':
        final appointmentId = widget.notification.typeIdentifier;
        if (isStylist) {
          if (appointmentId != null) {
            context.router.push(
              SellerAppointmentDetailsRoute(
                appointmentId: appointmentId.toString(),
              ),
            );
          } else {
            context.pop();
          }
        } else {
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
        context.router.push(
          isStylist ? const SellerEarningRoute() : const CustomerWalletRoute(),
        );
      case 'conversation':
        context.router.push(
          ConversationListRoute(),
        );
      case 'dispute':
        final token = getIt<LocalKeyStorage>().accessToken;
        if (token == null) return;
        final supportUrl =
            Environment().config.apiHost.replaceAll('api', 'disputes');
        context.router.pushWidget(
          SupportWebViewWidget(
            supportUrl: supportUrl,
            authToken: token,
          ),
        );

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStylist =
        context.select<AppCubit, bool>((AppCubit bloc) => bloc.state.isStylist);

    return ListTile(
      tileColor: Colors.white,
      onTap: _showNotificationDialog,
      title: AppText(
        text: widget.notification.title ?? 'No Title',
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
      subtitle: AppText(
        text: widget.notification.description ?? 'No Message',
        maxLines: 2,
        color: Colors.grey,
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            text: widget.notification.createdAt.toTimeAgo(),
            fontSize: 12,
            color: Colors.grey,
          ),
          8.verticalSpace,
          if (!_isRead)
            const CircleAvatar(
              radius: 5,
              backgroundColor: Colors.red,
            ),
        ],
      ),
    );
  }
}
