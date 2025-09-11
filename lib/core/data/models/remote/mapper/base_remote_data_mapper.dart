import 'package:snip_fair/core/data/models/base_model.dart';
import 'package:snip_fair/core/data/models/remote/base_remote_data.dart';

abstract class BaseRemoteDataMapper<R extends BaseRemoteData,
    E extends BaseModel> {
  E mapToEntity(R? data);

  List<E> mapToListEntity(List<R>? listData) {
    return listData?.map(mapToEntity).toList() ?? List.empty();
  }
}

/// Optional: if need map from entity to remote data
mixin RemoteDataMapperMixin<R extends BaseRemoteData, E extends BaseModel>
    on BaseRemoteDataMapper<R, E> {
  R mapToRemoteData(E entity);

  List<R> mapToListRemoteData(List<E> listEntity) {
    return listEntity.map(mapToRemoteData).toList();
  }
}
