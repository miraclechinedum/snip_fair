import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/data/models/remote/simple_response.dart';
import 'package:snip_fair/core/data/models/server_error.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/stylist_profile_details.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';
import 'package:snip_fair/features/account/shared/account_closure.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

/// Account closure never claims an account was deleted: the app requests
/// closure and erasure, shows the server's explanation on refusal and
/// never logs out by itself.
void main() {
  late _MockProfileRepository repo;

  setUp(() {
    repo = _MockProfileRepository();
    when(repo.getStylistProfile).thenAnswer(
      (_) async => ApiResult.success(data: StylistProfileDetails()),
    );
  });

  test('the closure texts never claim a permanent deletion', () {
    for (final text in [
      AccountClosure.heading,
      AccountClosure.description,
      AccountClosure.confirmContent,
      AccountClosure.submitted,
      AccountClosure.buttonLabel,
    ]) {
      expect(text.toLowerCase(), isNot(contains('permanently deleted')));
      expect(text.toLowerCase(), isNot(contains('deleted successfully')));
      expect(text.toLowerCase(), isNot(contains('cannot be undone')));
    }
    expect(AccountClosure.description, contains('kept by law'));
    expect(AccountClosure.submitted, contains('within 30 days'));
  });

  test('shows the server explanation, else a fallback', () {
    const refusal = RemoteException.serverError(
      403,
      ServerError(message: 'Accounts can only be deactivated.'),
      code: 'account_deletion_not_supported',
    );
    expect(
      AccountClosure.errorMessage(refusal),
      'Accounts can only be deactivated.',
    );
    const blank = RemoteException.serverError(500, ServerError(message: ' '));
    expect(AccountClosure.errorMessage(blank), contains('support@'));
    expect(AccountClosure.errorMessage(Exception('x')), contains('support@'));
  });

  test('a closure request records its outcome and never logs out', () async {
    when(repo.requestAccountClosure).thenAnswer(
      (_) async => ApiResult.success(
        data: SimpleResponse.fromJson({'status': 'submitted'}),
      ),
    );
    final cubit = SellerProfileMgtCubit(repo);
    await cubit.requestAccountClosure();
    expect(cubit.state.deleteAccountState.hasSuccess, isTrue);

    const refusal = RemoteException.serverError(
      403,
      ServerError(message: 'Refused'),
    );
    when(repo.requestAccountClosure).thenAnswer(
      (_) async => const ApiResult.failure(error: refusal),
    );
    await cubit.requestAccountClosure();
    expect(cubit.state.deleteAccountState.hasError, isTrue);
    expect(
      AccountClosure.errorMessage(cubit.state.deleteAccountState.error),
      'Refused',
    );
    await cubit.close();
  });
}
