import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project_secure/services/db_service.dart';

class AlertInfo extends StatefulWidget {
  final String? txnId;
  final VoidCallback? onBack;
  const AlertInfo({super.key, this.txnId, this.onBack});

  @override
  State<AlertInfo> createState() => _AlertInfoState();
}

class _AlertInfoState extends State<AlertInfo> {
  String? _activeTxnId;
  Map<String, dynamic>? _txnData;
  Map<String, dynamic>? _predData;
  bool _loading = true;
  String? _error;

  StreamSubscription? _txnSub;
  StreamSubscription? _predSub;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _txnSub?.cancel();
    _predSub?.cancel();
    super.dispose();
  }

  void _loadData() async {
    try {
      String? targetId = widget.txnId;
      if (targetId == null) {
        // Query the latest alert/transaction
        final snap = await DbService.transactions.limitToLast(1).get();
        if (snap.exists && snap.value is Map) {
          final Map map = snap.value as Map;
          targetId = map.keys.first.toString();
        } else {
          targetId = 'TXN-982341'; // Fallback
        }
      }

      setState(() {
        _activeTxnId = targetId;
        _loading = true;
        _error = null;
      });

      // Listen to transaction updates
      _txnSub?.cancel();
      _txnSub = DbService.transactions.child(targetId).onValue.listen((event) {
        if (!mounted) return;
        final val = event.snapshot.value;
        setState(() {
          if (val is Map) {
            _txnData = Map<String, dynamic>.from(val);
          } else {
            _txnData = null;
          }
          _loading = false;
        });
      }, onError: (err) {
        setState(() {
          _error = err.toString();
          _loading = false;
        });
      });

      // Listen to prediction updates
      _predSub?.cancel();
      _predSub = DbService.predictions.child(targetId).onValue.listen((event) {
        if (!mounted) return;
        final val = event.snapshot.value;
        setState(() {
          if (val is Map) {
            _predData = Map<String, dynamic>.from(val);
          } else {
            _predData = null;
          }
        });
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Action helpers
  Future<void> _freezeAccount(String accountId) async {
    if (_activeTxnId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Freeze Account'),
        content: Text(
          'Are you sure you want to freeze account ending ...${accountId.length > 4 ? accountId.substring(accountId.length - 4) : accountId}?\n\nThis action will be logged and requires supervisor approval to reverse.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Freeze'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await DbService.freezeAccount(
        accountId:   accountId,
        alertId:     _activeTxnId!,
        performedBy: 'Investigator Neil Verma',
        reason:      'High-probability mule transaction flagged by AI Sentinel',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: const [
            Icon(Icons.block, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('Account has been frozen. Action logged.')),
          ]),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error freezing account: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _escalateTransaction() async {
    if (_activeTxnId == null) return;
    try {
      await DbService.escalateAlert(
        txnId:       _activeTxnId!,
        escalatedBy: 'Investigator Neil Verma',
        reason:      'Manually escalated via Alert Details — requires senior review',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: const [
            Icon(Icons.crisis_alert, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('Alert escalated to senior investigator queue.')),
          ]),
          backgroundColor: Colors.blueAccent,
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error escalating alert: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _markSafe() async {
    if (_activeTxnId == null) return;
    try {
      await DbService.markSafe(
        txnId:      _activeTxnId!,
        reviewedBy: 'Investigator Neil Verma',
        note:       'Investigation completed — transaction deemed safe after manual review',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('Transaction marked safe. Alert cleared.')),
          ]),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ));
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        if (widget.onBack != null) {
          widget.onBack!();
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error marking transaction safe: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹0.00';
    final num val = amount is num ? amount : (num.tryParse(amount.toString()) ?? 0);
    return '₹${val.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  String _formatTime(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final hr = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hr:$min';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _txnData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Transaction details not found.', style: const TextStyle(color: Colors.red, fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Parse location details
    final loc = _txnData!['location'] is Map ? Map<String, dynamic>.from(_txnData!['location'] as Map) : null;
    final String city = loc?['city']?.toString() ?? 'Worli';
    final String state = loc?['state']?.toString() ?? 'Mumbai';
    final String ip = loc?['ip']?.toString() ?? '192.168.1.45';

    final double amountVal = (_txnData!['amount'] as num?)?.toDouble() ?? 0.0;
    final String accountFrom = _txnData!['accountFrom']?.toString() ?? 'ACC001';
    final String accountTo = _txnData!['accountTo']?.toString() ?? 'ACC002';

    // Parse prediction details
    final double probability = (_predData?['probability'] as num?)?.toDouble() ?? 0.87;
    final String riskTier = _predData?['riskTier']?.toString().toUpperCase() ?? 'CRITICAL';
    final List<dynamic> signalsList = _predData?['signals'] is List ? (_predData!['signals'] as List) : [];

    final String fromLast4 = accountFrom.length > 4 ? accountFrom.substring(accountFrom.length - 4) : accountFrom;
    final String toLast4 = accountTo.length > 4 ? accountTo.substring(accountTo.length - 4) : accountTo;

    // Derived metrics
    final double confidenceVal = 90.0 + (probability * 9.8);
    final String confidence = '${confidenceVal.toStringAsFixed(1)}%';
    const String processingTime = '12ms';
    const String dataPoints = '1,402';


    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // ── APP BAR ──
          Container(
                  height: 70,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
                        onPressed: () {
                          if (widget.onBack != null) {
                            widget.onBack!();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _activeTxnId ?? 'TXN-982341',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'HIGH RISK ALERT',
                              style: TextStyle(color: Color(0xFFB91C1C), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Transaction Analysis Detail • Investigator: Priya Sharma',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const Spacer(),
                      // Search entity
                      Container(
                        width: 240,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search entity...',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            prefixIcon: Icon(Icons.search, color: Color(0xFF64748B), size: 18),
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.notifications_none_outlined, color: Color(0xFF64748B)),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Color(0xFF64748B)),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 12),
                      const CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=100'),
                      ),
                    ],
                  ),
                ),

                // ── CORE DATA PANELS ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isWide = constraints.maxWidth > 950;
                        return Column(
                          children: [
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left column: Core transaction details & Entities
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      children: [
                                        _buildCoreTransactionCard(amountVal, ip, city, state),
                                        const SizedBox(height: 20),
                                        _buildEntitiesCard(accountFrom, accountTo, fromLast4, toLast4),
                                        const SizedBox(height: 20),
                                        _buildMapOverlayCard(city, state),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  // Middle column: Donut circular index
                                  Expanded(
                                    flex: 4,
                                    child: _buildDonutChartCard(probability, riskTier, confidence, processingTime, dataPoints),
                                  ),
                                  const SizedBox(width: 20),
                                  // Right column: AI Reasoning & Log
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      children: [
                                        _buildAiReasoningCard(signalsList),
                                        const SizedBox(height: 20),
                                        _buildInvestigativeLogCard(),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _buildDonutChartCard(probability, riskTier, confidence, processingTime, dataPoints),
                                  const SizedBox(height: 20),
                                  _buildCoreTransactionCard(amountVal, ip, city, state),
                                  const SizedBox(height: 20),
                                  _buildEntitiesCard(accountFrom, accountTo, fromLast4, toLast4),
                                  const SizedBox(height: 20),
                                  _buildMapOverlayCard(city, state),
                                  const SizedBox(height: 20),
                                  _buildAiReasoningCard(signalsList),
                                  const SizedBox(height: 20),
                                  _buildInvestigativeLogCard(),
                                ],
                              ),
                            const SizedBox(height: 24),
                            // Action Buttons Row
                            _buildActionButtonsRow(accountFrom, accountTo),
                          ],
                        );
                      },
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, bool active, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            border: active ? const Border(left: BorderSide(color: Color(0xFF38BDF8), width: 4)) : null,
            color: active ? const Color(0xFF0F2D4A) : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(icon, color: active ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8), size: 20),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: active ? Colors.white : const Color(0xFF94A3B8),
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Left card 1: Core Transaction
  Widget _buildCoreTransactionCard(double amount, String ip, String city, String state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CORE TRANSACTION',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.0),
          ),
          const SizedBox(height: 16),
          const Text(
            'Amount',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(amount),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          _detailRow('Type', 'IMPS / External Transfer'),
          const SizedBox(height: 12),
          _detailRow('Device Fingerprint', 'DV-992-AXL-01', highlight: true),
          const SizedBox(height: 12),
          _detailRow('Network Identity', ip),
          const SizedBox(height: 4),
          Text(
            '$city, $state (Inconsistent Latency)',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        if (highlight)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2F6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
            ),
          )
        else
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
          ),
      ],
    );
  }

  // Left card 2: Entities — names read from Firebase transaction data
  Widget _buildEntitiesCard(String from, String to, String fromLast4, String toLast4) {
    final String senderName   = (_txnData?['senderName']   as String?)?.trim() ?? '';
    final String receiverName = (_txnData?['receiverName'] as String?)?.trim() ?? '';

    final String senderDisplay   = senderName.isNotEmpty   ? senderName   : 'A/C ...$fromLast4';
    final String receiverDisplay = receiverName.isNotEmpty ? receiverName : 'A/C ...$toLast4';

    String deriveInitials(String name, String fallback) {
      if (name.isEmpty) return fallback.substring(0, fallback.length.clamp(0, 2)).toUpperCase();
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
    }

    final String senderInitials   = deriveInitials(senderName, fromLast4);
    final String receiverInitials = deriveInitials(receiverName, toLast4);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENTITIES',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.0),
          ),
          const SizedBox(height: 20),
          // Sender
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEFF6FF),
                radius: 20,
                child: Text(senderInitials, style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senderDisplay,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('Sender  •  A/C ...$fromLast4', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 20, top: 12, bottom: 12),
            child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20),
          ),
          // Receiver
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFEF2F2),
                radius: 20,
                child: Text(receiverInitials, style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receiverDisplay,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('Receiver  •  A/C ...$toLast4', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
            ],
          ),
        ],
      ),
    );
  }

  // Left card 3: Map Overlay
  Widget _buildMapOverlayCard(String city, String state) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=400'),
          fit: BoxFit.cover,
          opacity: 0.4,
        ),
      ),
      child: Stack(
        children: [
          // Cyber network background lines (simulated)
          Center(
            child: Icon(
              Icons.blur_on_sharp,
              size: 100,
              color: Colors.cyan.withOpacity(0.3),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Origin: $city, $state',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Middle card: Donut Chart
  Widget _buildDonutChartCard(double probability, String riskTier, String confidence, String procTime, String dPoints) {
    final int score = (probability * 100).round();
    final Color chartColor = score >= 80 ? const Color(0xFFDC2626) : (score >= 50 ? Colors.orange : Colors.green);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(32),
      height: 600,
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Sentinel AI Probability Index',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const Spacer(),
          // Donut Stack
          Stack(
            alignment: Alignment.center,
            children: [
              // Chart
              SizedBox(
                width: 250,
                height: 250,
                child: CustomPaint(
                  painter: DonutChartPainter(
                    percentage: probability,
                    color: chartColor,
                    backgroundColor: const Color(0xFFF1F5F9),
                  ),
                ),
              ),
              // Inside Center text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score%',
                    style: TextStyle(fontSize: 54, fontWeight: FontWeight.bold, color: chartColor),
                  ),
                  const Text(
                    'MULE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.0),
                  ),
                  const Text(
                    'PROBABILITY',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.0),
                  ),
                ],
              ),
              // Banner Badge Tooltip absolute positioned
              Positioned(
                top: 30,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: chartColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: chartColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        riskTier,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Underneath statistics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _metricLabelVal('Confidence', confidence),
              _metricLabelVal('Processing', procTime),
              _metricLabelVal('Data Points', dPoints),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _metricLabelVal(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }

  // Right card 1: AI Reasoning
  Widget _buildAiReasoningCard(List<dynamic> signals) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.psychology, color: Color(0xFF0074bd)),
              SizedBox(width: 8),
              Text(
                'AI Reasoning',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0074bd)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (signals.isNotEmpty)
                  ...signals.map((sig) => _reasonRow(
                        Icons.crisis_alert,
                        'Triggered Signal',
                        sig.toString(),
                      ))
                else ...[
                  _reasonRow(
                    Icons.link,
                    'Rapid transfer chain',
                    'Funds arrived from 3 separate accounts and were attempted to be moved within 180 seconds.',
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 24),
                  _reasonRow(
                    Icons.person_remove_outlined,
                    'Flagged Beneficiary',
                    'Recipient account has been linked to three previous mule investigation reports in the last 30 days.',
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 24),
                  _reasonRow(
                    Icons.timer_outlined,
                    'Abnormal Timing',
                    'Transaction initiated at 03:14 AM, highly inconsistent with user\'s typical login patterns (09:00 - 21:00).',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reasonRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFDC2626), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  // Right card 2: Investigative Log
  Widget _buildInvestigativeLogCard() {
    final int baseTs = _txnData?['createdAt'] is int ? _txnData!['createdAt'] as int : DbService.nowMs();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INVESTIGATIVE LOG',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.0),
          ),
          const SizedBox(height: 16),
          _logRow(_formatTime(baseTs - 180000), 'Alert triggered by Real-time Engine'),
          const SizedBox(height: 12),
          _logRow(_formatTime(baseTs - 120000), 'Cross-entity graph analyzed (12 nodes)'),
          const SizedBox(height: 12),
          _logRow(_formatTime(baseTs - 60000), 'Case assigned to High-Priority Queue'),
        ],
      ),
    );
  }

  Widget _logRow(String time, String message) {
    return Row(
      children: [
        Text(
          time,
          style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
        ),
      ],
    );
  }

  // Bottom action buttons — Hold Transaction removed, 3 buttons fill the row evenly
  Widget _buildActionButtonsRow(String accountFrom, String accountTo) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _freezeAccount(accountTo),
                icon: const Icon(Icons.block, size: 18),
                label: const Text('Freeze Account', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _escalateTransaction,
                icon: const Icon(Icons.crisis_alert, size: 18),
                label: const Text('Escalate', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _markSafe,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Mark Safe', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CUSTOM DONUT CHART PAINTER ─────────────────────────────────────────────
class DonutChartPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;

  DonutChartPainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 16;
    const strokeWidth = 20.0;

    final paintBackground = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, paintBackground);

    final paintForeground = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const double startAngle = -3.1415926535 / 2; // Top
    final double sweepAngle = 2 * 3.1415926535 * percentage;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paintForeground,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
