import 'package:injectable/injectable.dart';
import '../../server_error.dart';
import '../error_response.dart';
import 'base_remote_data_mapper.dart';

@Injectable()
class ErrorResponseMapper
    extends BaseRemoteDataMapper<ErrorResponse, ServerError> {
  ErrorResponseMapper();

  @override
  ServerError mapToEntity(ErrorResponse? data) {
    return ServerError(
      status: data?.status ?? '',
      message: data?.message ?? '',
      errors: data?.errors ?? {},
    );
  }
}
