import 'package:equatable/equatable.dart';

class PaginationData extends Equatable {
  const PaginationData({
    this.nextPageCursor,
    this.prevPageCursor,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
  });
  final String? nextPageCursor;
  final String? prevPageCursor;
  final bool isLoadingMore;
  final bool hasReachedMax;

  @override
  List<Object?> get props =>
      [nextPageCursor, prevPageCursor, isLoadingMore, hasReachedMax];
}
