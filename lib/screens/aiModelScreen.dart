import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:project_secure/services/ai_model_service.dart';

// ─── Feature descriptor ───────────────────────────────────────────────────
class _Feature {
  final String key;
  final String label;
  final String hint;
  final dynamic defaultValue;
  const _Feature(this.key, this.label, this.hint, this.defaultValue);
}

final List<_Feature> _features = [
  _Feature('F3891', 'Occupation', 'student / salaried / housewife / others', 'student'),
  _Feature('F3894', 'Age', 'e.g. 18', 18),
  _Feature('F3889', 'Account Tenure Code', 'e.g. L7D', 'L7D'),
  _Feature('F3895', 'Credit Score', '300–900', 350),
  _Feature('F3799', 'Total Inward Amount', 'e.g. 25000000', 25000000),
  _Feature('F3800', 'Total Outward Amount', 'e.g. 24900000', 24900000),
  _Feature('F3796', 'Credit Transaction Count', 'e.g. 650', 650),
  _Feature('F3797', 'Debit Transaction Count', 'e.g. 12', 12),
  _Feature('F3890', 'Location Segment', 'U / M / R', 'M'),
  _Feature('F3886', 'Account Type', 'Savings / Current', 'Savings'),
  _Feature('F3893', 'Customer Segment', 'RETAIL / SME', 'RETAIL'),
  _Feature('F3919', 'Credit Transaction Rate', 'e.g. 6', 6),
  _Feature('F3887', 'Avg Debit Tx Amount', 'e.g. 1', 1),
  _Feature('F3920', 'Avg Amount Per Transaction', 'e.g. 4', 4),
  _Feature('F3905', 'Normalised Credit Score', '0.0 – 1.0', 1),
  _Feature('F3915', 'Net Flow Efficiency', '-1 to +1', 1),
  _Feature('F3922', 'Account Type Code', 'e.g. 3', 3),
];

class AiModelScreen extends StatefulWidget {
  const AiModelScreen({super.key});
  @override
  State<AiModelScreen> createState() => _AiModelScreenState();
}

class _AiModelScreenState extends State<AiModelScreen> {
  // Account fields
  final _accountFromCtrl = TextEditingController();
  final _accountToCtrl = TextEditingController();

  // Feature controllers
  late final List<TextEditingController> _ctrls = _features
      .map((f) => TextEditingController(text: f.defaultValue.toString()))
      .toList();

  bool _submitting = false;
  bool _submitted = false;
  String? _error;
  String _step = '';              // tracks current step for UI feedback
  Map<String, dynamic>? _aiResult; // stores AI response to show in UI
  StreamSubscription<DatabaseEvent>? _activeTxnSub;

  final _txnRef = FirebaseDatabase.instance.ref('transactions');
  final _accRef = FirebaseDatabase.instance.ref('accounts');
  final _muleRef = FirebaseDatabase.instance.ref('transactions/mule-response');

  @override
  void dispose() {
    _accountFromCtrl.dispose();
    _accountToCtrl.dispose();
    for (final c in _ctrls) { c.dispose(); }
    _activeTxnSub?.cancel();
    super.dispose();
  }

  // Build the features map from controllers
  Map<String, dynamic> get _featuresMap {
    final m = <String, dynamic>{};
    for (var i = 0; i < _features.length; i++) {
      final f = _features[i];
      final raw = _ctrls[i].text.trim();
      m[f.key] = f.defaultValue is String ? raw : (num.tryParse(raw) ?? 0);
    }
    return m;
  }

  String get _prettyPayload =>
      const JsonEncoder.withIndent('  ').convert({
        'accountFrom': _accountFromCtrl.text.trim(),
        'accountTo': _accountToCtrl.text.trim(),
        'features': _featuresMap,
      });

  Future<void> _submitToFirebase() async {
    final from = _accountFromCtrl.text.trim();
    final to   = _accountToCtrl.text.trim();

    if (from.isEmpty || to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill Account From and Account To'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    for (var i = 0; i < _features.length; i++) {
      if (_ctrls[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please fill: ${_features[i].label}'),
          backgroundColor: Colors.red,
        ));
        return;
      }
    }

    setState(() {
      _submitting = true;
      _submitted  = false;
      _error      = null;
      _aiResult   = null;
      _step       = 'Writing transaction to database…';
    });

    try {
      final now      = DateTime.now().toIso8601String();
      final features = _featuresMap;
      final amount   = features['F3799'] ?? 0;

      // ── STEP 1: Push transaction with status pending ──────────────
      final newTxnRef = _txnRef.push();
      final txnId = newTxnRef.key!;

      await newTxnRef.set({
        'accountFrom': from,
        'accountTo':   to,
        'amount':      amount,
        'features':    features,
        'timestamp':   now,
        'status':      'pending',
        'mule':        false,
        'risk_tier':   'PENDING',
        'mule_probability': 0.0,
      });

      // ── STEP 2: Write account folders ────────────────────────────
      await _accRef.child('$from/sent/$txnId').set(
          {'to': to, 'amount': amount, 'timestamp': now, 'txnId': txnId});
      await _accRef.child('$to/received/$txnId').set(
          {'from': from, 'amount': amount, 'timestamp': now, 'txnId': txnId});

      // ── STEP 3: Setup active transaction listener to update UI ─────
      await _activeTxnSub?.cancel();
      _activeTxnSub = newTxnRef.onValue.listen((event) {
        final val = event.snapshot.value;
        if (val == null || !mounted) return;

        final data = AiModelService.toStringMap(val);
        final status = data['status']?.toString() ?? 'pending';

        setState(() {
          if (status == 'pending') {
            _step = 'Transaction submitted (Pending analysis)…';
          } else if (status == 'analyzing') {
            _step = 'Analyzing transaction using AI model…';
          } else if (status == 'analyzed') {
            final isMule = data['mule'] == true;
            _step = isMule ? '🚨 MULE DETECTED' : '✅ Transaction Cleared';
            _submitted = true;
            _aiResult = {
              'flagged': isMule,
              'risk_tier': data['risk_tier'],
              'mule_probability': data['mule_probability'],
              'signals_triggered': data['signals_triggered'],
              'signals': data['signals'] ?? [],
            };
          } else if (status == 'analysis_failed') {
            _error = 'AI model analysis failed.';
            _step = 'Analysis failed';
          }
        });
      });

      // ── STEP 4: Trigger background analysis (Non-blocking / Unawaited) ─
      _runBackgroundAnalysis(txnId, features, from, to, amount, now);

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted  = true;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _submitting = false;
      });
    }
  }

  void _runBackgroundAnalysis(
      String txnId,
      Map<String, dynamic> features,
      String from,
      String to,
      dynamic amount,
      String timestamp) async {
    final txnRef = _txnRef.child(txnId);

    try {
      // Transition 1: Set status to analyzing in the database
      await txnRef.update({'status': 'analyzing'});

      // Call AI model
      final result = await AiModelService.predict(features);

      if (result == null) {
        // Transition 2 (fail): Set status to analysis_failed in the database
        await txnRef.update({'status': 'analysis_failed'});
        return;
      }

      // Transition 2 (success): Set status to analyzed and update result in the database
      final isMule = result['flagged'] == true;
      final riskTier = result['risk_tier']?.toString() ?? 'UNKNOWN';
      final mulePct = (result['mule_probability'] as num?)?.toDouble() ?? 0.0;

      await txnRef.update({
        'status':           'analyzed',
        'mule':             isMule,
        'risk_tier':        riskTier,
        'mule_probability': mulePct,
        'signals_triggered': result['signals_triggered'] ?? 0,
        'signals':          result['signals'] ?? [],
        'ai_analyzed_at':   DateTime.now().toIso8601String(),
      });

      // Write to transactions/mule-response if it is a mule
      if (isMule) {
        await _muleRef.child(txnId).set({
          'txnId':            txnId,
          'accountFrom':      from,
          'accountTo':        to,
          'amount':           amount,
          'mule_probability': mulePct,
          'risk_tier':        riskTier,
          'flagged':          true,
          'signals':          result['signals'] ?? [],
          'proofs':           result['proofs']  ?? [],
          'signals_triggered': result['signals_triggered'] ?? 0,
          'analyzed_at':      DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      try {
        await txnRef.update({'status': 'analysis_failed'});
      } catch (_) {}
    }
  }

  void _resetFields() {
    _accountFromCtrl.clear();
    _accountToCtrl.clear();
    for (var i = 0; i < _features.length; i++) {
      _ctrls[i].text = _features[i].defaultValue.toString();
    }
    setState(() { _submitted = false; _error = null; _aiResult = null; _step = ''; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      body: Column(
        children: [
          // ── App Bar (matches other screens) ───────────────────────────
          Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFcacfd6))),
              ),
              height: MediaQuery.of(context).size.height * 0.09,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 50, top: 15),
                      child: Text('Good Morning, Team BOI',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    Row(children: const [
                      CircleAvatar(radius: 5, backgroundColor: Colors.greenAccent),
                      Text('System Active'),
                    ]),
                  ]),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.25,
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Search for mule accounts',
                        labelStyle: const TextStyle(color: Colors.black),
                        icon: const Icon(Icons.search),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: const BorderSide(color: Color(0xFFcacfd6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                  ),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_active_outlined)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
                  const VerticalDivider(width: 0.2, color: Color(0xFFcacfd6)),
                  Row(children: const [
                    CircleAvatar(backgroundColor: Colors.black, radius: 15),
                    SizedBox(width: 10),
                    Text('Investigator Neil verma'),
                  ]),
                ],
              ),
            ),
          ),

          // ── Page Header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('AI Model Tester',
                      style: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(children: [
                    CircleAvatar(radius: 5,
                        backgroundColor: _submitting ? Colors.orange : Colors.greenAccent),
                    const SizedBox(width: 6),
                    Text(
                      _submitting ? _step : 'Write → AI Analyze → Update DB → mule-response if flagged',
                      style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w300),
                    ),
                  ]),
                ]),
                Row(children: [
                  OutlinedButton.icon(
                    onPressed: _resetFields,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submitToFirebase,
                    icon: _submitting
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                    label: Text(_submitting ? _step.isNotEmpty ? _step : 'Processing…' : 'Submit Transaction'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF121b2c),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ]),
              ],
            ),
          ),

          // ── Step progress banner (while submitting) ─────────────────────
          if (_submitting && _step.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_step,
                      style: TextStyle(color: Colors.blue.shade800, fontSize: 13))),
                ]),
              ),
            ),

          // ── AI Result banner (after completion) ──────────────────────────
          if (_submitted && _aiResult != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildAiResultBanner(_aiResult!),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade800, fontSize: 13))),
                ]),
              ),
            ),

          const SizedBox(height: 8),

          // ── Main Two-Column Layout ────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Left: Account fields + Feature inputs ─────────────
                  Expanded(
                    flex: 3,
                    child: Card(
                      elevation: 4,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(children: [
                              const Icon(Icons.tune_rounded, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              const Text('Transaction & Feature Values',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Text('${_features.length + 2} fields',
                                    style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                              ),
                            ]),
                            const SizedBox(height: 4),
                            const Text(
                              'Fill in the account details and all AI feature values.',
                              style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w300),
                            ),
                            const Divider(height: 24),

                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ── Account fields section ──────────
                                    _sectionLabel('🏦 Account Details'),
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      Expanded(child: _accountField(
                                        controller: _accountFromCtrl,
                                        label: 'Account From (Sender ID)',
                                        hint: 'e.g. ACC001',
                                        icon: Icons.account_circle_outlined,
                                      )),
                                      const SizedBox(width: 12),
                                      Expanded(child: _accountField(
                                        controller: _accountToCtrl,
                                        label: 'Account To (Receiver ID)',
                                        hint: 'e.g. ACC002',
                                        icon: Icons.send_outlined,
                                      )),
                                    ]),
                                    const SizedBox(height: 16),
                                    const Divider(),
                                    const SizedBox(height: 8),

                                    // ── Feature fields section ──────────
                                    _sectionLabel('🧠 AI Model Features'),
                                    const SizedBox(height: 10),
                                    ...List.generate(_features.length, _buildFeatureField),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // ── Right: Info + Live JSON preview ───────────────────
                  Expanded(
                    flex: 2,
                    child: Column(children: [
                      // Info card
                      Card(
                        elevation: 4,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: const [
                                Icon(Icons.info_outline, color: Colors.blue, size: 18),
                                SizedBox(width: 8),
                                Text('How It Works', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ]),
                              const SizedBox(height: 10),
                              _infoRow(Icons.storage_rounded, 'Writes to transactions/{id}'),
                              _infoRow(Icons.account_tree_rounded, 'Writes to accounts/{from}/sent/{id}'),
                              _infoRow(Icons.account_tree_rounded, 'Writes to accounts/{to}/received/{id}'),
                              _infoRow(Icons.model_training_rounded, 'Listener auto-calls AI model'),
                              _infoRow(Icons.flag_rounded, 'AI result updates mule: true/false'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Live JSON
                      Expanded(
                        child: Card(
                          elevation: 4,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: const [
                                  Icon(Icons.data_object_rounded, color: Colors.blue, size: 18),
                                  SizedBox(width: 8),
                                  Text('Live JSON Preview',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ]),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E2D3D),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: AnimatedBuilder(
                                      animation: Listenable.merge([_accountFromCtrl, _accountToCtrl, ..._ctrls]),
                                      builder: (_, __) => SingleChildScrollView(
                                        child: SelectableText(
                                          _prettyPayload,
                                          style: const TextStyle(
                                            color: Color(0xFF9CDCFE),
                                            fontSize: 11,
                                            height: 1.6,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(label,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87));

  Widget _accountField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue.shade400),
        filled: true,
        fillColor: Colors.blue.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFeatureField(int i) {
    final f = _features[i];
    final isString = f.defaultValue is String;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 76,
          margin: const EdgeInsets.only(top: 14, right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: isString ? Colors.purple.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isString ? Colors.purple.shade200 : Colors.blue.shade200),
          ),
          child: Column(children: [
            Text(f.key, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                color: isString ? Colors.purple.shade700 : Colors.blue.shade700)),
            Text(isString ? 'string' : 'number',
                style: TextStyle(fontSize: 8, color: isString ? Colors.purple.shade400 : Colors.blue.shade400)),
          ]),
        ),
        Expanded(
          child: TextFormField(
            controller: _ctrls[i],
            keyboardType: isString ? TextInputType.text : TextInputType.number,
            decoration: InputDecoration(
              labelText: f.label,
              hintText: f.hint,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFcacfd6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 1.5),
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 15, color: Colors.blue.shade400),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black54))),
      ]),
    );
  }

  Widget _buildAiResultBanner(Map<String, dynamic> r) {
    final isMule  = r['flagged'] == true;
    final tier    = r['risk_tier']?.toString() ?? 'UNKNOWN';
    final prob    = ((r['mule_probability'] as num?)?.toDouble() ?? 0.0);
    final signals = List<String>.from(r['signals'] ?? []);
    final MaterialColor color = isMule ? Colors.red : Colors.green;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.shade50,
        border: Border.all(color: color.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isMule ? Icons.gpp_bad : Icons.verified_user, color: color.shade700, size: 20),
          const SizedBox(width: 8),
          Text(
            isMule ? '🚨 MULE DETECTED — Written to mule-response folder' : '✅ Transaction Cleared — Not a Mule',
            style: TextStyle(fontWeight: FontWeight.bold, color: color.shade800, fontSize: 14),
          ),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 16, children: [
          _chip('Risk Tier', tier, color),
          _chip('Mule Probability', '${(prob * 100).toStringAsFixed(2)}%', color),
          _chip('Signals Triggered', '${r['signals_triggered'] ?? 0}', color),
        ]),
        if (signals.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...signals.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded, size: 13, color: color.shade600),
              const SizedBox(width: 6),
              Expanded(child: Text(s, style: TextStyle(fontSize: 12, color: color.shade800))),
            ]),
          )),
        ],
      ]),
    );
  }

  Widget _chip(String label, String value, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.shade300),
      ),
      child: RichText(text: TextSpan(children: [
        TextSpan(text: '$label: ', style: TextStyle(fontSize: 11, color: color.shade600)),
        TextSpan(text: value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.shade900)),
      ])),
    );
  }
}
