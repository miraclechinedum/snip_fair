part of 'seller_works_cubit.dart';

class SellerWorksState extends Equatable {
  const SellerWorksState._({
    required this.workTitle,
    required this.workDescription,
    required this.workFilePaths,
    required this.workCategories,
    required this.selectedWorkCategory,
    required this.durationInHours,
    required this.price,
    required this.addWorkState,
    required this.portfolioStats,
    required this.worksList,
    required this.deleteWorkState,
    required this.isWorkItemAvailable,
    required this.updateWorkItemAvailability,
  });

  const SellerWorksState.initial()
      : workTitle = const StringInput.pure(),
        workDescription = const StringInput.pure(),
        workFilePaths = const [],
        workCategories = const ProcessState.init(null),
        selectedWorkCategory = null,
        durationInHours = 0,
        price = 0.0,
        isWorkItemAvailable = false,
        worksList = const ProcessState.init(null),
        portfolioStats = const ProcessState.init(null),
        addWorkState = const ProcessState.init(null),
        updateWorkItemAvailability = const ProcessState.init(null),
        deleteWorkState = const ProcessState.init(null);

  final StringInput workTitle;
  final StringInput workDescription;
  final List<String> workFilePaths;
  final ProcessState<List<WorkCategory>> workCategories;
  final WorkCategory? selectedWorkCategory;
  final int durationInHours;
  final double price;
  final ProcessState<bool> addWorkState;
  final ProcessState<bool> deleteWorkState;
  final ProcessState<StylistStats> portfolioStats;
  final ProcessState<WorkList> worksList;
  final bool isWorkItemAvailable;
  final ProcessState<bool> updateWorkItemAvailability;

  bool get canSubmitWork =>
      Formz.validate([workTitle, workDescription]) &&
      workFilePaths.isNotEmpty &&
      selectedWorkCategory != null &&
      durationInHours > 0 &&
      price > 0;

  SellerWorksState copyWith({
    StringInput? workTitle,
    StringInput? workDescription,
    List<String>? workFilePaths,
    ProcessState<List<WorkCategory>>? workCategories,
    WorkCategory? selectedWorkCategory,
    int? durationInHours,
    double? price,
    bool? isWorkItemAvailable,
    ProcessState<bool>? addWorkState,
    ProcessState<bool>? deleteWorkState,
    ProcessState<bool>? updateWorkItemAvailability,
    ProcessState<StylistStats>? portfolioStats,
    ProcessState<WorkList>? worksList,
  }) {
    return SellerWorksState._(
      workTitle: workTitle ?? this.workTitle,
      workDescription: workDescription ?? this.workDescription,
      workFilePaths: workFilePaths ?? this.workFilePaths,
      workCategories: workCategories ?? this.workCategories,
      selectedWorkCategory: selectedWorkCategory ?? this.selectedWorkCategory,
      durationInHours: durationInHours ?? this.durationInHours,
      price: price ?? this.price,
      isWorkItemAvailable: isWorkItemAvailable ?? this.isWorkItemAvailable,
      addWorkState: addWorkState ?? this.addWorkState,
      deleteWorkState: deleteWorkState ?? this.deleteWorkState,
      updateWorkItemAvailability:
          updateWorkItemAvailability ?? this.updateWorkItemAvailability,
      portfolioStats: portfolioStats ?? this.portfolioStats,
      worksList: worksList ?? this.worksList,
    );
  }

  @override
  List<Object?> get props {
    return [
      workTitle,
      workDescription,
      workFilePaths,
      workCategories,
      selectedWorkCategory,
      durationInHours,
      price,
      addWorkState,
      portfolioStats,
      worksList,
      deleteWorkState,
      isWorkItemAvailable,
      updateWorkItemAvailability,
    ];
  }
}
