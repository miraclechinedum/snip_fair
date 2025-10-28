import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/notifications_list/notification_datum.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/utils/pagination_data.dart';

part 'notifications_state.dart';

@Injectable()
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._profileRepository)
      : super(NotificationsState.initial());

  final ProfileRepository _profileRepository;

  Future<void> fetchNotifications({bool isInitial = false}) async {
    if (isInitial) {
      emit(
        state.copyWith(
          notificationsListState: ProcessState.loading(null),
          paginationData: PaginationData(),
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
            notificationsListState:
                ProcessState.error(error, state.notificationsListState.data),
          ),
        );
      },
    );
  }

  void onLogout() {
    emit(NotificationsState.initial());
  }
}
