import 'dart:math';
import 'package:driver_app/core/operations/driver_operations_api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String _requestId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with WidgetsBindingObserver {
  final _api = DriverOperationsApi();
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  double _number(Object? value) => double.tryParse('$value') ?? 0;
  String _money(Object? value) => '${_number(value).toStringAsFixed(2)} ETB';
  Future<void> _load() async {
    try {
      final data = await _api.load();
      if (mounted)
        setState(() {
          _data = data;
          _error = null;
          _loading = false;
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _error = '$error'.replaceFirst('Exception: ', '');
          _loading = false;
        });
    }
  }

  Future<void> _request(String kind) async {
    final form = GlobalKey<FormState>();
    final amount = TextEditingController();
    final name = TextEditingController();
    final account = TextEditingController();
    final bank = TextEditingController();
    final key = _requestId();
    String method = kind == 'convert' ? 'earnings' : 'telebirr';
    bool busy = false;
    bool submitted = false;
    Map<String, dynamic>? attemptedBody;
    String? error;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return PopScope(
            canPop: !busy,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        kind == 'topup'
                            ? 'Buy commission credit'
                            : kind == 'cashout'
                            ? 'Request a cash out'
                            : 'Move earnings to credit',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        kind == 'convert'
                            ? 'Moves available wallet earnings into non-withdrawable commission credit.'
                            : kind == 'topup'
                            ? 'Contact dispatch for payment account details. Credit is added only after dispatch verifies your actual Telebirr or bank payment.'
                            : 'Dispatch reviews this request and sends payment to the account below. The amount stays reserved until payment is reconciled or the request is rejected.',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amount,
                        enabled: !busy && !submitted,
                        decoration: const InputDecoration(
                          labelText: 'Amount (ETB)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          final n = double.tryParse(value ?? '');
                          return n == null ||
                                  !n.isFinite ||
                                  n <= 0 ||
                                  n > 1000000 ||
                                  !RegExp(
                                    r'^\d+(\.\d{1,2})?$',
                                  ).hasMatch(value ?? '')
                              ? 'Enter a positive amount with at most 2 decimals.'
                              : null;
                        },
                      ),
                      if (kind != 'convert') ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: method,
                          decoration: const InputDecoration(
                            labelText: 'Payment method',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'telebirr',
                              child: Text('Telebirr'),
                            ),
                            DropdownMenuItem(
                              value: 'bank',
                              child: Text('Bank account'),
                            ),
                          ],
                          onChanged: busy || submitted
                              ? null
                              : (value) => setSheetState(
                                  () => method = value ?? 'telebirr',
                                ),
                        ),
                      ],
                      if (kind == 'cashout') ...[
                        TextFormField(
                          controller: name,
                          enabled: !busy && !submitted,
                          decoration: const InputDecoration(
                            labelText: 'Account holder name',
                          ),
                          validator: (v) => (v?.trim().length ?? 0) < 2
                              ? 'Enter the account holder name.'
                              : null,
                        ),
                        TextFormField(
                          controller: account,
                          enabled: !busy && !submitted,
                          decoration: InputDecoration(
                            labelText: method == 'telebirr'
                                ? 'Telebirr phone number'
                                : 'Bank account number',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => (v?.trim().length ?? 0) < 7
                              ? 'Enter a valid recipient account.'
                              : null,
                        ),
                        if (method == 'bank')
                          TextFormField(
                            controller: bank,
                            enabled: !busy && !submitted,
                            decoration: const InputDecoration(
                              labelText: 'Bank name',
                            ),
                            validator: (v) => (v?.trim().length ?? 0) < 2
                                ? 'Enter your bank name.'
                                : null,
                          ),
                      ],
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: busy
                            ? null
                            : () async {
                                if (!form.currentState!.validate()) return;
                                attemptedBody ??= {
                                  'kind': kind,
                                  'amount': double.parse(amount.text),
                                  'method': method,
                                  'account_name': name.text.trim(),
                                  'account_number': account.text.trim(),
                                  'bank_name': bank.text.trim(),
                                  'idempotency_key': key,
                                };
                                setSheetState(() {
                                  busy = true;
                                  submitted = true;
                                  error = null;
                                });
                                try {
                                  await _api.walletRequest(attemptedBody!);
                                  if (context.mounted) Navigator.pop(context);
                                  if (mounted) {
                                    await _load();
                                    if (mounted)
                                      ScaffoldMessenger.of(
                                        this.context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            kind == 'convert'
                                                ? 'Earnings moved to commission credit.'
                                                : 'Request submitted. Payment is pending dispatch review.',
                                          ),
                                        ),
                                      );
                                  }
                                } catch (e) {
                                  if (context.mounted)
                                    setSheetState(() {
                                      error = '$e'.replaceFirst(
                                        'Exception: ',
                                        '',
                                      );
                                      busy = false;
                                    });
                                }
                              },
                        child: Text(
                          busy
                              ? 'Submitting…'
                              : submitted
                              ? 'Retry same request'
                              : kind == 'convert'
                              ? 'Confirm conversion'
                              : 'Submit request',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    amount.dispose();
    name.dispose();
    account.dispose();
    bank.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = (_data?['wallet'] as Map?) ?? {};
    final requests = (_data?['requests'] as List?) ?? [];
    final ledger = (_data?['ledger'] as List?) ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver wallet'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Try again'),
                    ),
                  ],
                  if (_data != null) ...[
                    _balance(
                      'Commission credit',
                      _number(wallet['commission_credit']) -
                          _number(wallet['reserved_credit']),
                      '${_money(wallet['reserved_credit'])} reserved for active cash deliveries',
                    ),
                    _balance(
                      'Available earnings',
                      _number(wallet['earnings_balance']) -
                          _number(wallet['reserved_cashout']),
                      '${_money(wallet['reserved_cashout'])} reserved for cash out',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Cash fares are collected directly by you. Only business-collected trip earnings appear in the withdrawable wallet. Owner commission applies to the delivery fee.',
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _request('topup'),
                      icon: const Icon(Icons.add),
                      label: const Text('Buy commission credit'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _request('cashout'),
                      icon: const Icon(Icons.account_balance_outlined),
                      label: const Text('Cash out to Telebirr or bank'),
                    ),
                    TextButton(
                      onPressed: () => _request('convert'),
                      child: const Text('Use earnings for commission credit'),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Recent requests',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (requests.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No wallet requests yet.'),
                      ),
                    for (final request in requests)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${request['kind']} · ${_money(request['amount'])}',
                        ),
                        subtitle: Text(
                          '${request['method']} · ${request['status']}${request['review_note'] == null ? '' : '\n${request['review_note']}'}',
                        ),
                        trailing: Icon(
                          request['status'] == 'completed'
                              ? Icons.check_circle_outline
                              : request['status'] == 'rejected'
                              ? Icons.cancel_outlined
                              : Icons.schedule,
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'Wallet activity',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (ledger.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Settled trips and verified wallet payments will appear here.',
                        ),
                      ),
                    for (final entry in ledger)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${entry['kind']}'.replaceAll('_', ' ')),
                        subtitle: Text(
                          '${DateFormat('dd MMM, HH:mm').format(DateTime.parse('${entry['created_at']}').toLocal())}\nCredit ${_money(entry['credit_delta'])} · Earnings ${_money(entry['earnings_delta'])}',
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _balance(String title, double value, String detail) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 8),
          Text(
            _money(value),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(detail),
        ],
      ),
    ),
  );
}
