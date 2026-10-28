import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:driver_app/core/operations/driver_operations_api.dart';
import 'package:driver_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

const _telebirrTopupNumber = '+251 931 323 328';

String _requestId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class _WalletRequestControllerScope extends StatefulWidget {
  const _WalletRequestControllerScope({required this.builder});

  final Widget Function(BuildContext, List<TextEditingController>) builder;

  @override
  State<_WalletRequestControllerScope> createState() =>
      _WalletRequestControllerScopeState();
}

class _WalletRequestControllerScopeState
    extends State<_WalletRequestControllerScope> {
  final _controllers = List<TextEditingController>.generate(
    4,
    (_) => TextEditingController(),
  );

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controllers);
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, this.api});
  final DriverOperationsApi? api;
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with WidgetsBindingObserver {
  late final DriverOperationsApi _api;
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;
  Timer? _refreshTimer;
  @override
  void initState() {
    super.initState();
    _api = widget.api ?? DriverOperationsApi();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted &&
          ((_data?['requests'] as List?) ?? []).any(
            (r) => r['status'] == 'pending',
          )) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
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

  Future<void> _attachProof(Map<String, dynamic> walletRequest) async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1800,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        throw Exception('Choose a screenshot under 5 MB.');
      }
      await _api.walletTopupRequest(
        {
          'kind': 'topup',
          'amount': _number(walletRequest['amount']),
          'method': 'telebirr',
          'account_name': walletRequest['account_name'] ?? '',
          'account_number': walletRequest['account_number'] ?? '',
          'bank_name': walletRequest['bank_name'] ?? '',
          'idempotency_key': walletRequest['idempotency_key'],
        },
        bytes,
        image.name,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Screenshot attached for review.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'.replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _request(String kind) async {
    final form = GlobalKey<FormState>();
    final key = _requestId();
    String method = kind == 'convert' ? 'earnings' : 'telebirr';
    bool busy = false;
    bool submitted = false;
    Map<String, dynamic>? attemptedBody;
    String? error;
    Uint8List? proofBytes;
    String? proofName;
    bool pickingProof = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _WalletRequestControllerScope(
        builder: (context, controllers) {
          final amount = controllers[0];
          final name = controllers[1];
          final account = controllers[2];
          final bank = controllers[3];
          return StatefulBuilder(
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
                                ? 'Pay the amount by Telebirr to $_telebirrTopupNumber, then upload a screenshot of the completed payment. Credit is added after review.'
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
                          if (kind == 'cashout') ...[
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
                          if (kind == 'topup') ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: busy || pickingProof
                                  ? null
                                  : () async {
                                      setSheetState(() => pickingProof = true);
                                      try {
                                        final image = await ImagePicker()
                                            .pickImage(
                                              source: ImageSource.gallery,
                                              imageQuality: 90,
                                              maxWidth: 1800,
                                            );
                                        if (image == null) return;
                                        final bytes = await image.readAsBytes();
                                        if (bytes.isEmpty ||
                                            bytes.length > 5 * 1024 * 1024) {
                                          if (context.mounted)
                                            setSheetState(
                                              () => error =
                                                  'Choose a screenshot under 5 MB.',
                                            );
                                          return;
                                        }
                                        if (context.mounted)
                                          setSheetState(() {
                                            proofBytes = bytes;
                                            proofName = image.name;
                                            error = null;
                                          });
                                      } catch (_) {
                                        if (context.mounted)
                                          setSheetState(
                                            () => error =
                                                'Could not read that screenshot. Please choose another image.',
                                          );
                                      } finally {
                                        if (context.mounted)
                                          setSheetState(
                                            () => pickingProof = false,
                                          );
                                      }
                                    },
                              icon: const Icon(
                                Icons.add_photo_alternate_outlined,
                              ),
                              label: Text(
                                proofName == null
                                    ? 'Upload payment screenshot'
                                    : 'Screenshot selected: $proofName',
                              ),
                            ),
                            if (proofBytes != null)
                              Image.memory(
                                proofBytes!,
                                height: 140,
                                fit: BoxFit.contain,
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
                                    if (kind == 'topup' && proofBytes == null) {
                                      setSheetState(
                                        () => error =
                                            'Upload your Telebirr payment screenshot.',
                                      );
                                      return;
                                    }
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
                                      if (kind == 'topup') {
                                        await _api.walletTopupRequest(
                                          attemptedBody!,
                                          proofBytes!,
                                          proofName!,
                                        );
                                      } else {
                                        await _api.walletRequest(
                                          attemptedBody!,
                                        );
                                      }
                                      if (context.mounted)
                                        Navigator.pop(context);
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
                                                    : 'Request submitted. Payment is pending review.',
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = (_data?['wallet'] as Map?) ?? {};
    final requests = (_data?['requests'] as List?) ?? [];
    final ledger = (_data?['ledger'] as List?) ?? [];
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wallet',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh wallet',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
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
                    Text(
                      'Your money at a glance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Keep credit ready for cash deliveries.',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    _balance(
                      'Commission credit',
                      _number(wallet['commission_credit']) -
                          _number(wallet['reserved_credit']),
                      '${_money(wallet['reserved_credit'])} reserved for active cash deliveries',
                      featured: true,
                      icon: Icons.account_balance_wallet_rounded,
                    ),
                    const SizedBox(height: 12),
                    _balance(
                      'Available earnings',
                      _number(wallet['earnings_balance']) -
                          _number(wallet['reserved_cashout']),
                      '${_money(wallet['reserved_cashout'])} reserved for cash out',
                      icon: Icons.trending_up_rounded,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: colors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Cash fares are paid to you directly. Your wallet shows earnings from trips paid through the business.',
                              style: TextStyle(
                                color: colors.onSurface,
                                height: 1.4,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => _request('topup'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Buy commission credit'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _request('cashout'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.account_balance_outlined),
                      label: const Text('Cash out'),
                    ),
                    TextButton(
                      onPressed: () => _request('convert'),
                      child: const Text('Move earnings to credit'),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Recent requests',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (requests.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No wallet requests yet.'),
                      ),
                    for (final request in requests)
                      Card(
                        margin: const EdgeInsets.only(top: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          title: Text(
                            '${request['kind']} · ${_money(request['amount'])}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${request['method']} · ${request['status'] == 'completed'
                                ? request['kind'] == 'topup'
                                      ? 'Approved'
                                      : 'Completed'
                                : request['status'] == 'rejected'
                                ? 'Rejected'
                                : 'Pending review'}${request['review_note'] == null ? '' : '\n${request['review_note']}'}',
                          ),
                          trailing:
                              request['kind'] == 'topup' &&
                                  request['method'] == 'telebirr' &&
                                  request['status'] == 'pending' &&
                                  request['proof_path'] == null
                              ? TextButton(
                                  onPressed: () => _attachProof(
                                    Map<String, dynamic>.from(request as Map),
                                  ),
                                  child: const Text('Add screenshot'),
                                )
                              : Icon(
                                  request['status'] == 'completed'
                                      ? Icons.check_circle_outline
                                      : request['status'] == 'rejected'
                                      ? Icons.cancel_outlined
                                      : Icons.schedule,
                                ),
                        ),
                      ),
                    const SizedBox(height: 28),
                    Text(
                      'Wallet activity',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (ledger.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Settled trips and verified wallet payments will appear here.',
                        ),
                      ),
                    for (final entry in ledger)
                      Card(
                        margin: const EdgeInsets.only(top: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          title: Text('${entry['kind']}'.replaceAll('_', ' ')),
                          subtitle: Text(
                            '${DateFormat('dd MMM, HH:mm').format(DateTime.parse('${entry['created_at']}').toLocal())}\nCredit ${_money(entry['credit_delta'])} · Earnings ${_money(entry['earnings_delta'])}',
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _balance(
    String title,
    double value,
    String detail, {
    required IconData icon,
    bool featured = false,
  }) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: featured
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.primary],
            )
          : null,
      color: featured
          ? null
          : Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
      border: featured
          ? null
          : Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      boxShadow: featured
          ? [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ]
          : null,
    ),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: featured
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
                size: 21,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: featured
                        ? Colors.white70
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            _money(value),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: featured
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            detail,
            style: TextStyle(
              color: featured
                  ? Colors.white70
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}
