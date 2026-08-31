import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/stylist_earnings.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/customer_wallet_transaction_list.dart';
import 'package:snip_fair/features/account/seller/earnings/cubit/earnings_cubit.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

StylistEarnings _earnings(List<Map<String, dynamic>> transactions) {
  return StylistEarnings.fromJson({
    'transactions': transactions,
  });
}

void main() {
  late _MockProfileRepository repo;
  late EarningsCubit cubit;

  setUp(() {
    repo = _MockProfileRepository();
    cubit = EarningsCubit(repo);
  });

  tearDown(() => cubit.close());

  test('a newly paid booking shows nothing until stylist approval', () async {
    // Backend returns an empty ledger before approval — no holding pouch
    // exists yet, so the Transactions tab must stay empty rather than
    // inventing a row.
    when(repo.getEarnings).thenAnswer(
      (_) async => ApiResult.success(data: _earnings(const [])),
    );

    await cubit.getEarnings();

    expect(cubit.state.transactionsState.data, isEmpty);
  });

  test('surfaces the holding pouch once the stylist approves', () async {
    when(repo.getEarnings).thenAnswer(
      (_) async => ApiResult.success(
        data: _earnings([
          {
            'id': 501,
            'type': 'earning',
            'amount': 480.75,
            'status': 'holding',
            'description': 'Escrow held for booking BK-1783504974-10',
            'reference': 'BK-1783504974-10',
            'created_at': '2026-08-20T10:00:00.000Z',
          },
        ]),
      ),
    );

    await cubit.getEarnings();

    final rows = cubit.state.transactionsState.data!;
    expect(rows, hasLength(1));
    expect(rows.single.status, 'holding');
    expect(rows.single.amount, 480.75);
    expect(
      rows.single.description,
      'Escrow held for booking BK-1783504974-10',
    );
  });

  test('holding pouches survive a Transactions-tab refresh', () async {
    when(repo.getEarnings).thenAnswer(
      (_) async => ApiResult.success(
        data: _earnings([
          {
            'id': 501,
            'type': 'earning',
            'amount': 480.75,
            'status': 'holding',
            'description': 'Escrow held',
            'created_at': '2026-08-20T10:00:00.000Z',
          },
        ]),
      ),
    );
    // /wallet/transactions does not carry holding pouches — the merge is
    // what keeps them on screen after a pull-to-refresh.
    when(
      () => repo.getWalletTransactions(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => ApiResult.success(
        data: CustomerWalletTransactionList.fromJson({
          'data': [
            {
              'id': 402,
              'type': 'withdraw',
              'amount': 200.0,
              'status': 'completed',
              'description': 'Payout',
              'created_at': '2026-08-19T10:00:00.000Z',
            },
          ],
        }),
      ),
    );

    await cubit.getEarnings();
    await cubit.fetchTransactions(isInitial: true);

    final rows = cubit.state.transactionsState.data!;
    expect(rows.map((r) => r.id), containsAll(<int>[501, 402]));
    // Newest first.
    expect(rows.first.id, 501);
  });

  test('does not duplicate a row present in both collections', () async {
    when(repo.getEarnings).thenAnswer(
      (_) async => ApiResult.success(
        data: _earnings([
          {
            'id': 501,
            'type': 'earning',
            'amount': 480.75,
            'status': 'holding',
            'created_at': '2026-08-20T10:00:00.000Z',
          },
        ]),
      ),
    );
    when(
      () => repo.getWalletTransactions(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => ApiResult.success(
        data: CustomerWalletTransactionList.fromJson({
          'data': [
            {
              'id': 501,
              'type': 'earning',
              'amount': 480.75,
              'status': 'holding',
              'created_at': '2026-08-20T10:00:00.000Z',
            },
          ],
        }),
      ),
    );

    await cubit.getEarnings();
    await cubit.fetchTransactions(isInitial: true);

    expect(cubit.state.transactionsState.data, hasLength(1));
  });
}
