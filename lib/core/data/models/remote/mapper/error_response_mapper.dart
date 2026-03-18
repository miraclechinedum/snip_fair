import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/models/server_error.dart';
import 'package:snip_fair/core/data/models/remote/error_response.dart';
import 'package:snip_fair/core/data/models/remote/mapper/base_remote_data_mapper.dart';

@Injectable()
class ErrorResponseMapper
    extends BaseRemoteDataMapper<ErrorResponse, ServerError> {
  ErrorResponseMapper();

  @override
  ServerError mapToEntity(ErrorResponse? data) {
    return ServerError(
      status: data?.status ?? false,
      message: data?.message ?? '',
      errors: data?.errors ?? {},
    );
  }
}
