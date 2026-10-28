import 'package:driver_app/core/operations/driver_operations_api.dart';
import 'package:driver_app/features/profile/presentation/screens/wallet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _WalletApi extends DriverOperationsApi {
  @override
  Future<Map<String, dynamic>> load() async => {
    'wallet': {
      'commission_credit': 0,
      'reserved_credit': 0,
      'earnings_balance': 0,
      'reserved_cashout': 0,
    },
    'requests': <Map<String, dynamic>>[],
    'ledger': <Map<String, dynamic>>[],
  };
}

class _WalletApiWithRequest extends _WalletApi {
  @override
  Future<Map<String, dynamic>> load() async {
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

      Navigator.of(tester.element(find.byType(TextFormField).first)).pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
