import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/pagination_data.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/services/notification_service.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/notifications_list/notification_datum.dart';

part 'notifications_state.dart';

@Injectable()
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._profileRepository) : super(NotificationsState.initial());

  final ProfileRepository _profileRepository;

  void startListeningForNotifications() {
    NotificationService.instance.updates.listen((event) {
      fetchNotifications(isInitial: true);
    });
  }

  Future<void> fetchNotifications({bool isInitial = false}) async {
    if (isInitial) {
      emit(
        state.copyWith(
          notificationsListState: const ProcessState.loading(),
          paginationData: const PaginationData(),
        ),
      );
    } else {
      emit(
        state.copyWith(
          paginationData: PaginationData(
            isLoadingMore: true,
            nextPageCursor: state.paginationData.nextPageCursor,
            prevPageCursor: state.paginationData.prevPageCursor,
          ),
        ),
      );
    }

    final result = await _profileRepository.getNotifications(
      page: state.paginationData.nextPageCursor,
      perPage: 15,
    );

    result.when(
      success: (data) {
        final notifications = data.data ?? [];
        final updatedList = isInitial
            ? notifications
            : [
                ...?state.notificationsListState.data,
                ...notifications,
              ];

        final updatedPaginationData = PaginationData(
          nextPageCursor: data.nextCursor,
          prevPageCursor: data.prevCursor,
          hasReachedMax: data.nextCursor == null,
        );

        emit(
          state.copyWith(
            notificationsListState: ProcessState.success(updatedList),
            paginationData: updatedPaginationData,
          ),
        );
      },
      failure: (error) {
        emit(
          state.copyWith(
            notificationsListState: ProcessState.error(error, state.notificationsListState.data),
          ),
        );
      },
    );
  }

  void onLogout() {
    emit(NotificationsState.initial());
  }

  Future<void> markNotificationAsRead(int id) async {
    final response = await _profileRepository.markNotificationAsRead(id.toString());
    response.when(
      success: (data) {
        // Optionally handle success response
        Fluttertoast.showToast(msg: 'Notification marked as read');
      },
      failure: (error) {
        // Optionally handle error response
      },
    );
  }
}
