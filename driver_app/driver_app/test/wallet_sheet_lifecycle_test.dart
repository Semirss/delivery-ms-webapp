import 'package:driver_app/core/operations/driver_operations_api.dart';
import 'package:driver_app/features/profile/presentation/screens/wallet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _WalletApi extends DriverOperationsApi {
  @override
  Future<Map<String, dynamic>> load({int requestsPage = 1, int ledgerPage = 1}) async => {
    'wallet': {
      'commission_credit': 0,
      'reserved_credit': 0,
      'earnings_balance': 0,
      'reserved_cashout': 0,
    },
    'requests': <Map<String, dynamic>>[],
    'ledger': <Map<String, dynamic>>[],
    'settings': {
      'telebirr_phone': '0912345678',
      'bank_enabled': true,
      'bank_name': 'Example Bank',
      'bank_account_name': 'MotoBike Business',
      'bank_account_number': '1234567890',
    },
  };
}

class _WalletApiWithRequest extends _WalletApi {
  @override
  Future<Map<String, dynamic>> load({int requestsPage = 1, int ledgerPage = 1}) async {
    final data = await super.load();
    data['requests'] = <Map<String, dynamic>>[
      {
        'id': 'pending-request',
        'kind': 'topup',
        'method': 'telebirr',
        'amount': 100,
        'status': 'pending',
        'proof_path': null,
        'review_note': null,
      },
    ];
    return data;
  }
}

class _WalletApiWithHistory extends _WalletApi {
  int lastRequestsPage = 1;
  int lastLedgerPage = 1;

  @override
  Future<Map<String, dynamic>> load({int requestsPage = 1, int ledgerPage = 1}) async {
    lastRequestsPage = requestsPage;
    lastLedgerPage = ledgerPage;
    final data = await super.load();
    data['requests'] = List.generate(10, (index) {
      final number = (requestsPage - 1) * 10 + index + 1;
      return {
        'id': 'request-$number', 'kind': 'topup', 'method': 'telebirr',
        'amount': number, 'status': 'completed', 'proof_path': 'proof',
      };
    }).where((request) => (request['amount'] as int) <= 25).toList();
    data['ledger'] = List.generate(10, (index) {
      final number = (ledgerPage - 1) * 10 + index + 1;
      return {
        'id': 'entry-$number', 'kind': 'credit_$number',
        'created_at': '2026-11-01T09:00:00Z',
        'credit_delta': number, 'earnings_delta': 0,
      };
    }).where((entry) => (entry['credit_delta'] as int) <= 25).toList();
    data['requests_total'] = 25;
    data['ledger_total'] = 25;
    data['pending_requests_count'] = 0;
    data['history_page_size'] = 10;
    return data;
  }
}

void main() {
  testWidgets('wallet fits a narrow phone with a pending proof request', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(home: WalletScreen(api: _WalletApiWithRequest())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your money at a glance'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Add screenshot'), 200);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'dismissing a wallet request keeps controllers alive through animation',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: WalletScreen(api: _WalletApi())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buy commission credit'));
      await tester.pumpAndSettle();
      expect(find.text('Amount (ETB)'), findsOneWidget);
      expect(find.textContaining('0912345678'), findsOneWidget);

      await tester.tap(find.text('Telebirr').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bank transfer').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Example Bank, MotoBike Business, account 1234567890'), findsOneWidget);

      Navigator.of(tester.element(find.byType(TextFormField).first)).pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('wallet history pages requests and activity independently', (tester) async {
    final api = _WalletApiWithHistory();
    await tester.pumpWidget(MaterialApp(home: WalletScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.byKey(const Key('requests-next')), 250);
    await tester.ensureVisible(find.byKey(const Key('requests-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('requests-next')));
    await tester.pumpAndSettle();
    expect(api.lastRequestsPage, 2);
    expect(api.lastLedgerPage, 1);
    await tester.scrollUntilVisible(
      find.byKey(const Key('wallet-request-request-11')),
      -250,
    );
    expect(find.byKey(const Key('wallet-request-request-11')), findsOneWidget);

    await tester.scrollUntilVisible(find.byKey(const Key('ledger-next')), 250);
    await tester.ensureVisible(find.byKey(const Key('ledger-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ledger-next')));
    await tester.pumpAndSettle();
    expect(api.lastRequestsPage, 2);
    expect(api.lastLedgerPage, 2);
    await tester.scrollUntilVisible(
      find.byKey(const Key('wallet-ledger-entry-11')),
      -250,
    );
    expect(find.byKey(const Key('wallet-ledger-entry-11')), findsOneWidget);
  });
}
