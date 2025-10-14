import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';

part 'customer_favorites_state.dart';

@Injectable()
class CustomerFavoritesCubit extends Cubit<CustomerFavoritesState> {
  CustomerFavoritesCubit(this._profileRepository)
      : super(CustomerFavoritesState());

  final ProfileRepository _profileRepository;
}
