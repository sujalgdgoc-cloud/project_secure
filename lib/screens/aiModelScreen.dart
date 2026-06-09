import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

// ─── Feature descriptor ────────────────────────────────────────────────────
class _Feature {
  final String key;
  final String label;
  final String hint;
  final dynamic defaultValue; // String or num
  const _Feature(this.key, this.label, this.hint, this.defaultValue);
}

// ─── 17 features required by the AI model ──────────────────────────────────
final List<_Feature> _features = [
  _Feature('F3891', 'Occupation',                'student / salaried / housewife / others', 'student'),
  _Feature('F3894', 'Age',                       'e.g. 18',        18),
  _Feature('F3889', 'Account Tenure Code',       'e.g. L7D',       'L7D'),
  _Feature('F3895', 'Credit Score',              '300–900',         350),
  _Feature('F3799', 'Total Inward Amount',       'e.g. 25000000',  25000000),
  _Feature('F3800', 'Total Outward Amount',      'e.g. 24900000',  24900000),
  _Feature('F3796', 'Credit Transaction Count',  'e.g. 650',        650),
  _Feature('F3797', 'Debit Transaction Count',   'e.g. 12',         12),
  _Feature('F3890', 'Location Segment',          'U / M / R',      'M'),
  _Feature('F3886', 'Account Type',              'Savings / Current', 'Savings'),
  _Feature('F3893', 'Customer Segment',          'RETAIL / SME',   'RETAIL'),
  _Feature('F3919', 'Credit Transaction Rate',   'e.g. 6',          6),
  _Feature('F3887', 'Avg Debit Tx Amount',       'e.g. 1',          1),
  _Feature('F3920', 'Avg Amount Per Transaction','e.g. 4',          4),
  _Feature('F3905', 'Normalised Credit Score',   '0.0 – 1.0',       1),
  _Feature('F3915', 'Net Flow Efficiency',       '-1 to +1',        1),
  _Feature('F3922', 'Account Type Code',         'e.g. 3',          3),
];

class AiModelScreen extends StatefulWidget {
  const AiModelScreen({super.key});

  @override
  State<AiModelScreen> createState() => _AiModelScreenState();
}

class _AiModelScreenState extends State<AiModelScreen> {
  // One controller per feature
  late final List<TextEditingController> _ctrls = _features
      .map((f) => TextEditingController(text: f.defaultValue.toString()))
      .toList();

  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  // Firebase Realtime Database reference
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref('ai_model_requests');

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  // Build the payload map from current controllers
  Map<String, dynamic> get _payload {
    final features = <String, dynamic>{};
    for (var i = 0; i < _features.length; i++) {
      final f = _features[i];
      final raw = _ctrls[i].text.trim();
      if (f.defaultValue is String) {
        features[f.key] = raw;
      } else {
        features[f.key] = num.tryParse(raw) ?? 0;
      }
    }
    return {
      'features': features,
      'submitted_at': DateTime.now().toIso8601String(),
      'status': 'pending',
    };
  }

  Future<void> _submitToFirebase() async {
    // Validate — no blank fields
    for (var i = 0; i < _features.length; i++) {
      if (_ctrls[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in: ${_features[i].label}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _submitting = true;
      _submitted = false;
      _error = null;
    });

    try {
      // Push a new entry under /ai_model_requests
      await _dbRef.push().set(_payload);
      if (!mounted) return;
      setState(() => _submitted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Data sent to AI model queue successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetFields() {
    for (var i = 0; i < _features.length; i++) {
      _ctrls[i].text = _features[i].defaultValue.toString();
    }
    setState(() {
      _submitted = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      body: Column(
        children: [
          // ── Custom App Bar (matches other screens) ──────────────────────
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFcacfd6)),
                ),
              ),
              height: MediaQuery.of(context).size.height * 0.09,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 50.0, top: 15),
                        child: Text(
                          'Good Morning, Team BOI',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Row(
                        children: const [
                          CircleAvatar(
                            radius: 5,
                            backgroundColor: Colors.greenAccent,
                          ),
                          Text('System Active'),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.15,
                    width: MediaQuery.of(context).size.width * 0.3,
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
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_active_outlined),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings_outlined),
                  ),
                  const VerticalDivider(width: 0.2, color: Color(0xFFcacfd6)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      CircleAvatar(
                        backgroundColor: Colors.black,
                        radius: 15,
                      ),
                      SizedBox(width: 10),
                      Text('Investigator Neil verma'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Page header ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Model Tester',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        CircleAvatar(
                          radius: 5,
                          backgroundColor: Colors.greenAccent,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Send feature values to the Mule Detection AI model queue',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _resetFields,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submitToFirebase,
                      icon: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(_submitting ? 'Submitting…' : 'Submit to AI Queue'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF121b2c),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Status banner (shown after submit) ──────────────────────────
          if (_submitted)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.green.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Feature values successfully queued in Firebase Realtime Database '
                        'under /ai_model_requests. The model will process this entry shortly.',
                        style: TextStyle(
                            color: Colors.green.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
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
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                            color: Colors.red.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

          // ── Main content: two-column layout ────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left — feature input fields
                  Expanded(
                    flex: 3,
                    child: Card(
                      elevation: 4,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.tune_rounded,
                                    color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Feature Values',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                        color: Colors.blue.shade200),
                                  ),
                                  child: Text(
                                    '${_features.length} features',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Fill in the account attributes below. These values will be '
                              'sent to the Mule Detection AI model via Firebase.',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300),
                            ),
                            const Divider(height: 24),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: List.generate(
                                    _features.length,
                                    (i) => _buildFeatureField(i),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Right — live JSON preview + info cards
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Info card
                        Card(
                          elevation: 4,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.info_outline,
                                        color: Colors.blue, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'About This Tool',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _infoRow(Icons.storage_rounded,
                                    'Writes payload to Firebase Realtime DB'),
                                _infoRow(Icons.model_training_rounded,
                                    'AI model reads from /ai_model_requests'),
                                _infoRow(Icons.rule_rounded,
                                    'Categorical fields are sent as strings'),
                                _infoRow(Icons.numbers_rounded,
                                    'Numeric fields are sent as numbers'),
                                _infoRow(Icons.flag_rounded,
                                    'Each entry includes status: pending'),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Live JSON preview
                        Expanded(
                          child: Card(
                            elevation: 4,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.data_object_rounded,
                                          color: Colors.blue, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Live JSON Preview',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E2D3D),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: AnimatedBuilder(
                                        animation: Listenable.merge(_ctrls),
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
                      ],
                    ),
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

  // ── Feature input field row ─────────────────────────────────────────────
  Widget _buildFeatureField(int i) {
    final f = _features[i];
    final isString = f.defaultValue is String;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type chip
          Container(
            width: 76,
            margin: const EdgeInsets.only(top: 14, right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: isString ? Colors.purple.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isString
                    ? Colors.purple.shade200
                    : Colors.blue.shade200,
              ),
            ),
            child: Column(
              children: [
                Text(
                  f.key,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isString
                        ? Colors.purple.shade700
                        : Colors.blue.shade700,
                  ),
                ),
                Text(
                  isString ? 'string' : 'number',
                  style: TextStyle(
                    fontSize: 8,
                    color: isString
                        ? Colors.purple.shade400
                        : Colors.blue.shade400,
                  ),
                ),
              ],
            ),
          ),
          // Text field
          Expanded(
            child: TextFormField(
              controller: _ctrls[i],
              keyboardType:
                  isString ? TextInputType.text : TextInputType.number,
              decoration: InputDecoration(
                labelText: f.label,
                hintText: f.hint,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
        ],
      ),
    );
  }

  // ── Info row helper ─────────────────────────────────────────────────────
  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.blue.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pretty JSON from live controllers ───────────────────────────────────
  String get _prettyPayload =>
      const JsonEncoder.withIndent('  ').convert(_payload);
}
