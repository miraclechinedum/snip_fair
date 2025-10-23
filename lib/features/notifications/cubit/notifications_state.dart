part of 'notifications_cubit.dart';

class NotificationsState extends Equatable {
  factory NotificationsState.initial() {
    return const NotificationsState._(
      notificationsListState: ProcessState.init(null),
      paginationData: PaginationData(),
    );
  }

  const NotificationsState._({
    required this.notificationsListState,
    required this.paginationData,
  });

  final ProcessState<List<NotificationDatum>> notificationsListState;
  final PaginationData paginationData;
  @override
  List<Object?> get props => [
        notificationsListState,
        paginationData,
      ];

  NotificationsState copyWith({
    ProcessState<List<NotificationDatum>>? notificationsListState,
    PaginationData? paginationData,
  }) {
    return NotificationsState._(
      notificationsListState:
          notificationsListState ?? this.notificationsListState,
      paginationData: paginationData ?? this.paginationData,
    );
  }
}
