import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:project_secure/screens/alertinfoScreen.dart';
import 'package:project_secure/widgets/ai_sum_feed.dart';
import 'package:project_secure/widgets/realtimeAlertcard.dart';
import 'package:project_secure/services/db_service.dart';

class AlertScreen extends StatefulWidget {
  final ValueChanged<String>? onViewTxn;
  const AlertScreen({super.key, this.onViewTxn});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  Map<String, dynamic> _safe(dynamic val) {
    if (val is Map) return Map<String, dynamic>.from(val);
    return <String, dynamic>{};
  }

  String _getDuration(dynamic createdAt) {
    if (createdAt == null) return 'unknown';
    final int ts = createdAt is int
        ? createdAt
        : (int.tryParse(createdAt.toString()) ?? 0);
    if (ts == 0) return 'unknown';

    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color text = Color(0xFF0F172A);
    const Color bgColor = Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      body: StreamBuilder<DatabaseEvent>(
        stream: DbService.transactions.onValue,
        builder: (context, txnSnap) {
          return StreamBuilder<DatabaseEvent>(
            stream: DbService.predictions.onValue,
            builder: (context, predSnap) {
              return StreamBuilder<DatabaseEvent>(
                stream: DbService.alerts.onValue,
                builder: (context, alertSnap) {
                  // ── Parse Transactions ──────────────────────────────
                  Map<String, Map<String, dynamic>> txnMap = {};
                  if (txnSnap.hasData && txnSnap.data!.snapshot.value != null) {
                    final raw = txnSnap.data!.snapshot.value;
                    if (raw is Map) {
                      txnMap = Map.fromEntries(raw.entries
                          .where((e) => e.key.toString() != 'mule-response')
                          .map((e) => MapEntry(e.key.toString(), _safe(e.value))));
                    }
                  }

                  // ── Parse Predictions ───────────────────────────────
                  Map<String, Map<String, dynamic>> predMap = {};
                  if (predSnap.hasData && predSnap.data!.snapshot.value != null) {
                    final raw = predSnap.data!.snapshot.value;
                    if (raw is Map) {
                      predMap = raw.map((k, v) => MapEntry(k.toString(), _safe(v)));
                    }
                  }

                  // ── Parse Alerts ────────────────────────────────────
                  Map<String, Map<String, dynamic>> alertMap = {};
                  if (alertSnap.hasData && alertSnap.data!.snapshot.value != null) {
                    final raw = alertSnap.data!.snapshot.value;
                    if (raw is Map) {
                      alertMap = raw.map((k, v) => MapEntry(k.toString(), _safe(v)));
                    }
                  }

                  // ── Top Row Dynamic Metrics ────────────────────────
                  final criticalAlertsCount = alertMap.length;
                  final inProgressCount = txnMap.values.where((t) {
                    final s = (t['status'] ?? '').toString();
                    return s == 'pending' || s == 'analyzing';
                  }).length;
                  final escalatedCount = txnMap.values.where((t) {
                    final s = (t['status'] ?? '').toString();
                    return s == 'escalated' || s == 'held';
                  }).length;

                  // ── Process Alerts List ─────────────────────────────
                  final List<MapEntry<String, Map<String, dynamic>>> alertEntries = alertMap.entries.toList();
                  
                  // Sort by analyzedAt descending
                  alertEntries.sort((a, b) {
                    final aTs = a.value['analyzedAt'] ?? 0;
                    final bTs = b.value['analyzedAt'] ?? 0;
                    return bTs.compareTo(aTs);
                  });

                  // Filter by Search Query
                  final filteredAlerts = alertEntries.where((entry) {
                    if (_searchQuery.isEmpty) return true;
                    final query = _searchQuery.toLowerCase();
                    final txnId = entry.key.toLowerCase();
                    final alertData = entry.value;
                    final txnData = txnMap[entry.key] ?? {};
                    
                    final from = (txnData['accountFrom'] ?? '').toString().toLowerCase();
                    final to = (txnData['accountTo'] ?? '').toString().toLowerCase();
                    final riskTier = (alertData['riskTier'] ?? '').toString().toLowerCase();
                    
                    final List<dynamic> signals = alertData['signals'] is List ? alertData['signals'] as List : [];
                    final signalsText = signals.join(" ").toLowerCase();

                    return txnId.contains(query) ||
                        from.contains(query) ||
                        to.contains(query) ||
                        riskTier.contains(query) ||
                        signalsText.contains(query);
                  }).toList();

                  // Layout calculations for responsive grid
                  final double screenWidth = MediaQuery.of(context).size.width;
                  // Sidebar width = 260. Body horizontal padding = 24 * 2 = 48.
                  final double contentWidth = (screenWidth - 260 - 48).clamp(320.0, 9999.0);
                  
                  final int crossAxisCount = contentWidth > 1100
                      ? 3
                      : (contentWidth > 700 ? 2 : 1);

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Custom App Bar (matching Dashboard/Homepage style)
                        Container(
                          height: 75,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Good Morning, Team BOI',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF22C55E),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'System Active',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  // Rounded Search Bar
                                  Container(
                                    width: contentWidth > 800 ? 280.0 : 180.0,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: TextField(
                                      controller: _searchCtrl,
                                      onChanged: (val) {
                                        setState(() {
                                          _searchQuery = val;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        hintText: 'Search suspicious patterns...',
                                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                        prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Notification Bell
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.notifications_outlined, color: Color(0xFF64748B)),
                                      onPressed: () {},
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Settings Gear
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.settings_outlined, color: Color(0xFF64748B)),
                                      onPressed: () {},
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Investigator profile info
                                  Row(
                                    children: const [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Color(0xFF0F172A),
                                        child: Text(
                                          'NV',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Investigator Neil Verma',
                                        style: TextStyle(
                                          color: Color(0xFF334155),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Section Heading + Refresh Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Real-time Alert Center',
                                    style: TextStyle(
                                      color: text,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Monitoring active transaction patterns',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onPressed: () {
                                  // Refresh stream trigger or visual feedback
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Checking live alert updates...'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                                label: const Text(
                                  'Live Refresh',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Top KPI Cards Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: RealTimeCard(
                                  text: 'Critical Alerts',
                                  number: criticalAlertsCount.toString(),
                                  icon: Icons.error_outline_rounded,
                                  icon_color: const Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: RealTimeCard(
                                  text: 'Active In-Progress',
                                  number: inProgressCount.toString(),
                                  icon: Icons.trending_up_rounded,
                                  icon_color: const Color(0xFFF59E0B),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: RealTimeCard(
                                  text: 'Escalated Priority',
                                  number: escalatedCount.toString(),
                                  icon: Icons.shield_outlined,
                                  icon_color: const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Live Investigation Feed Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Live Investigation Feed',
                                style: TextStyle(
                                  color: text,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Grid of Alerts
                        if (filteredAlerts.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 80),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.shield_outlined, color: Colors.green, size: 64),
                                  SizedBox(height: 16),
                                  Text(
                                    'No Active Alerts Found',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No alerts match the current query.',
                                    style: TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisExtent: 460,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(8),
                              itemCount: filteredAlerts.length,
                              itemBuilder: (context, index) {
                                final alertEntry = filteredAlerts[index];
                                final txnId = alertEntry.key;
                                final alertData = alertEntry.value;
                                final txnData = txnMap[txnId] ?? {};

                                final String riskTier = (alertData['riskTier'] ?? 'HIGH').toString();
                                final double probability = (alertData['probability'] as num?)?.toDouble() ?? 0.8;
                                final String scoreStr = (probability * 100).round().toString();

                                final String accountFrom = txnData['accountFrom']?.toString() ?? 'unknown';
                                final String formattedAcc = accountFrom.length > 8
                                    ? '${accountFrom.substring(0, 4)}XXXX${accountFrom.substring(accountFrom.length - 4)}'
                                    : accountFrom;

                                final String duration = _getDuration(txnData['createdAt']);

                                // Location details
                                final loc = txnData['location'] is Map
                                    ? Map<String, dynamic>.from(txnData['location'] as Map)
                                    : null;
                                final String city = loc?['city']?.toString() ?? 'Mumbai';
                                final String country = loc?['country']?.toString() ?? 'IN';
                                final String locationStr = '$city, $country';

                                final List<dynamic> signals = alertData['signals'] is List
                                    ? alertData['signals'] as List
                                    : [];
                                final String summary = signals.isNotEmpty
                                    ? 'Flagged due to: ${signals.join(", ")}'
                                    : 'AI model flagged this transaction as a high-risk transfer.';

                                Color boxColor = const Color(0xFFEF4444);
                                String ctgy = 'High';
                                if (riskTier.toUpperCase() == 'CRITICAL') {
                                  boxColor = const Color(0xFF991B1B);
                                  ctgy = 'Critical';
                                } else if (riskTier.toUpperCase() == 'MEDIUM') {
                                  boxColor = const Color(0xFFF59E0B);
                                  ctgy = 'Medium';
                                } else if (riskTier.toUpperCase() == 'LOW') {
                                  boxColor = const Color(0xFF3B82F6);
                                  ctgy = 'Low';
                                }
                                final String accountTo = txnData['accountTo']?.toString() ?? '';

                                return AiSumCard(
                                  box_color: boxColor,
                                  ctgy: ctgy,
                                  Score: scoreStr,
                                  acc_no: formattedAcc,
                                  duration: duration,
                                  location: locationStr,
                                  summary: summary,
                                  txnId: txnId,
                                  accountTo: accountTo,
                                  onReview: () async {
                                    if (widget.onViewTxn != null) {
                                      widget.onViewTxn!(txnId);
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => AlertInfo(txnId: txnId)),
                                      );
                                    }
                                  },
                                  onFreeze: () async {
                                    await DbService.freezeAccount(
                                      accountId:   accountTo,
                                      alertId:     txnId,
                                      performedBy: 'Investigator Neil Verma',
                                      reason:      'High-probability mule — flagged via Alert Card',
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                        content: Text('Account frozen. Action logged.'),
                                        backgroundColor: Color(0xFFDC2626),
                                        duration: Duration(seconds: 2),
                                      ));
                                    }
                                  },
                                  onEscalate: () async {
                                    await DbService.escalateAlert(
                                      txnId:       txnId,
                                      escalatedBy: 'Investigator Neil Verma',
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                        content: Text('Alert escalated to senior queue.'),
                                        backgroundColor: Colors.blueAccent,
                                        duration: Duration(seconds: 2),
                                      ));
                                    }
                                  },
                                  onDismiss: () async {
                                    await DbService.alerts.child(txnId).remove();
                                    await DbService.markTxnStatus(txnId, 'dismissed');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                        content: Text('Alert dismissed.'),
                                        backgroundColor: Color(0xFF64748B),
                                        duration: Duration(seconds: 2),
                                      ));
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
