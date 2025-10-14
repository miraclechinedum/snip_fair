import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/stylist_stats/stylist_stats.dart';
import 'package:snip_fair/core/domain/entities/work_category/work_category.dart';
import 'package:snip_fair/core/domain/entities/work_list/work_item.dart';
import 'package:snip_fair/core/domain/entities/work_list/work_list.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/app_extensions.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/utils/input/string_input.dart';

part 'seller_works_state.dart';

@Injectable()
class SellerWorksCubit extends Cubit<SellerWorksState> {
  SellerWorksCubit(this._profileRepository)
      : super(const SellerWorksState.initial());

  final ProfileRepository _profileRepository;

  Future<void> getWorkList() async {
    emit(state.copyWith(worksList: const ProcessState.loading()));
    final response = await _profileRepository.fetchWorks();
    response.when(
      success: (data) {
        emit(state.copyWith(worksList: ProcessState.success(data)));
      },
      failure: (error) {
        emit(state.copyWith(worksList: ProcessState.error(error)));
      },
    );
  }

  Future<void> getPortfolioStats() async {
    emit(state.copyWith(portfolioStats: const ProcessState.loading()));
    final response = await _profileRepository.getStylistStats();
    response.when(
      success: (data) {
        emit(state.copyWith(portfolioStats: ProcessState.success(data)));
      },
      failure: (error) {
        emit(state.copyWith(portfolioStats: ProcessState.error(error)));
      },
    );
  }

  Future<void> getWorkCategories() async {
    emit(state.copyWith(workCategories: const ProcessState.loading()));
    final response = await _profileRepository.fetchWorkCategories();
    response.when(
      success: (data) {
        emit(state.copyWith(workCategories: ProcessState.success(data)));
      },
      failure: (error) {
        emit(state.copyWith(workCategories: ProcessState.error(error)));
      },
    );
  }

  // Form

  void edit([WorkItem? work]) {
    if (work == null) return;
    emit(
      state.copyWith(
        workTitle: StringInput.dirty(work.title ?? ''),
        workDescription: StringInput.dirty(work.description ?? ''),
        durationInHours: work.duration.pickNumber(),
        workFilePaths: work.mediaUrls,
        selectedWorkCategory: state.workCategories.data
            ?.where((e) => e.id?.toString() == work.categoryId)
            .first,
        price: work.price?.toDouble(),
      ),
    );
  }

  void onTitleChanged(String value) {
    emit(state.copyWith(workTitle: StringInput.dirty(value)));
  }

  void onDescriptionChanged(String value) {
    emit(state.copyWith(workDescription: StringInput.dirty(value)));
  }

  void onDurationChanged(int value) {
    emit(state.copyWith(durationInHours: value));
  }

  void onCategoryChanged(WorkCategory category) {
    emit(state.copyWith(selectedWorkCategory: category));
  }

  void onPriceChanged(double value) {
    emit(state.copyWith(price: value));
  }

  void onSelectImages(List<String> filePaths) {
    emit(state.copyWith(workFilePaths: [...state.workFilePaths, ...filePaths]));
  }

  void onRemoveImage(String image) {
    emit(
        state.copyWith(workFilePaths: [...state.workFilePaths]..remove(image)));
  }

  void resetForm() {
    emit(
      state.copyWith(
        workTitle: const StringInput.pure(),
        workDescription: const StringInput.pure(),
        durationInHours: 0,
        workFilePaths: [],
        selectedWorkCategory: null,
        price: 0,
      ),
    );
  }

  Future<void> updateOrCreateWorkItem([int? workId]) async {
    emit(state.copyWith(addWorkState: const ProcessState.loading()));
    if (workId != null) {
      final response = await _profileRepository.updateWork(
        workId.toString(),
        title: state.workTitle.value,
        categoryId: state.selectedWorkCategory!.id!.toString(),
        price: state.price.toStringAsFixed(2),
        description: state.workDescription.value,
        duration: '${state.durationInHours} Hours',
        images: state.workFilePaths,
      );
      response.when(
        success: (data) {
          resetForm();
          emit(state.copyWith(addWorkState: const ProcessState.success(true)));
          getWorkList();
        },
        failure: (error) {
          emit(state.copyWith(addWorkState: ProcessState.error(error)));
        },
      );
    } else {
      final response = await _profileRepository.createWork(
        title: state.workTitle.value,
        categoryId: state.selectedWorkCategory!.id!.toString(),
        price: state.price.toStringAsFixed(2),
        description: state.workDescription.value,
        duration: '${state.durationInHours} Hours',
        images: state.workFilePaths,
      );
      response.when(
        success: (data) {
          resetForm();
          emit(state.copyWith(addWorkState: const ProcessState.success(true)));
          getWorkList();
        },
        failure: (error) {
          emit(state.copyWith(addWorkState: ProcessState.error(error)));
        },
      );
    }
  }

  Future<void> deleteWorkItem(int workId) async {
    emit(state.copyWith(workCategories: const ProcessState.loading()));
    final response = await _profileRepository.fetchWorkCategories();
    response.when(
      success: (data) {
        emit(state.copyWith(workCategories: ProcessState.success(data)));
      },
      failure: (error) {
        emit(state.copyWith(workCategories: ProcessState.error(error)));
      },
    );
  }
}
