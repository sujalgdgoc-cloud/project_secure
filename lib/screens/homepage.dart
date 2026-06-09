import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/alert_card.dart';
import '../widgets/custom_card.dart';
import '../widgets/info_card.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Safely converts a Firebase dynamic map to Map<String, dynamic>.
  static Map<String, dynamic> _safe(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }

  /// Converts a Firebase timestamp ISO string to a short time label.
  static String _timeAgo(dynamic ts) {
    if (ts == null) return '—';
    try {
      final dt = DateTime.parse(ts.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}min ago';
      if (diff.inHours < 24) return '${diff.inHours}hr ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '—';
    }
  }

  static String _shortTime(dynamic ts) {
    if (ts == null) return '—';
    try {
      final dt = DateTime.parse(ts.toString()).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final s = dt.second.toString().padLeft(2, '0');
      final period = dt.hour < 12 ? 'AM' : 'PM';
      return '$h:$m:$s $period';
    } catch (_) {
      return '—';
    }
  }

  static Color _riskColor(String? tier) {
    switch ((tier ?? '').toUpperCase()) {
      case 'CRITICAL': return Colors.redAccent;
      case 'HIGH':     return Colors.redAccent;
      case 'MEDIUM':   return Colors.deepOrangeAccent;
      case 'LOW':      return Colors.blue;
      default:         return Colors.grey;
    }
  }

  static String _riskLabel(String? tier, String? status) {
    if (status == 'pending' || status == 'analyzing') return 'Analyzing…';
    if (status == 'analysis_failed') return 'Failed';
    final t = (tier ?? 'UNKNOWN').toUpperCase();
    if (t == 'PENDING') return 'Pending';
    return '$t Risk';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('transactions').onValue,
        builder: (context, snapshot) {
          // ── Parse transactions from Firebase ──────────────────────────
          Map<String, Map<String, dynamic>> txnMap = {};
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final raw = snapshot.data!.snapshot.value;
            if (raw is Map) {
              txnMap = raw.map((k, v) =>
                  MapEntry(k.toString(), _safe(v)));
            }
          }

          // ── Compute metrics ──────────────────────────────────────────
          final total = txnMap.length;
          final highRisk = txnMap.values.where((t) {
            final tier = (t['risk_tier'] ?? '').toString().toUpperCase();
            return tier == 'HIGH' || tier == 'CRITICAL';
          }).length;
          final muleCount = txnMap.values.where((t) => t['mule'] == true).length;
          final underReview = txnMap.values.where((t) {
            final s = (t['status'] ?? '').toString();
            return s == 'pending' || s == 'analyzing';
          }).length;

          // ── Sort by timestamp desc for feed ──────────────────────────
          final sortedEntries = txnMap.entries.toList()
            ..sort((a, b) {
              final ta = a.value['timestamp']?.toString() ?? '';
              final tb = b.value['timestamp']?.toString() ?? '';
              return tb.compareTo(ta);
            });
          final feedItems = sortedEntries.take(6).toList();

          // ── High-risk items for alerts panel ────────────────────────
          final alertItems = sortedEntries
              .where((e) {
                final tier = (e.value['risk_tier'] ?? '').toString().toUpperCase();
                return tier == 'HIGH' || tier == 'CRITICAL';
              })
              .take(3)
              .toList();

          // ── Trend indicator ──────────────────────────────────────────
          final bool hasData = total > 0;

          return Column(
            children: [
              // ── Custom App Bar ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(4.0),
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
                          padding: EdgeInsets.only(left: 50.0, top: 15),
                          child: Text('Good Morning, Team BOI',
                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        Row(children: const [
                          CircleAvatar(radius: 5, backgroundColor: Colors.greenAccent),
                          Text('System Active'),
                        ]),
                      ]),
                      SizedBox(
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
                      IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_active_outlined)),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
                      const VerticalDivider(width: 0.2, color: Color(0xFFcacfd6)),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: const [
                        CircleAvatar(backgroundColor: Colors.black, radius: 15),
                        SizedBox(width: 10),
                        Text('Investigator Neil verma'),
                      ]),
                    ],
                  ),
                ),
              ),

              // ── Metric Cards ─────────────────────────────────────────
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _metricCard(
                      title: 'Total Transactions',
                      value: hasData ? _fmt(total) : '—',
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: Colors.blue,
                      stonksIcon: Icons.trending_up,
                      stonksColor: Colors.green,
                      stonksString: hasData ? '+$total' : '0',
                      context: context,
                    ),
                    const SizedBox(width: 30),
                    _metricCard(
                      title: 'High Risk Alerts',
                      value: hasData ? _fmt(highRisk) : '—',
                      icon: Icons.warning_amber,
                      iconColor: Colors.red,
                      stonksIcon: highRisk > 0 ? Icons.trending_up : Icons.trending_flat,
                      stonksColor: Colors.red,
                      stonksString: hasData ? '$highRisk' : '0',
                      context: context,
                    ),
                    const SizedBox(width: 30),
                    _metricCard(
                      title: 'Mule Accounts',
                      value: hasData ? _fmt(muleCount) : '—',
                      icon: Icons.no_accounts,
                      iconColor: Colors.deepOrangeAccent,
                      stonksIcon: muleCount > 0 ? Icons.trending_up : Icons.trending_down,
                      stonksColor: Colors.deepOrangeAccent,
                      stonksString: hasData ? '$muleCount' : '0',
                      context: context,
                    ),
                    const SizedBox(width: 30),
                    _metricCard(
                      title: 'Under Review',
                      value: hasData ? _fmt(underReview) : '—',
                      icon: Icons.assignment,
                      iconColor: Colors.blue,
                      stonksIcon: Icons.gpp_good,
                      stonksColor: Colors.grey,
                      stonksString: hasData ? 'active' : 'stable',
                      context: context,
                    ),
                  ],
                ),
              ),

              const Padding(padding: EdgeInsets.all(16)),

              // ── Live Feed + Side Panel ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Live Transaction Feed
                  Container(
                    width: MediaQuery.sizeOf(context).width * 0.45,
                    height: MediaQuery.sizeOf(context).height * 0.6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(21),
                      border: Border.all(color: const Color(0xFFcacfd6)),
                    ),
                    child: Column(children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Live Transaction Feed',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21)),
                            Row(children: [
                              if (snapshot.connectionState == ConnectionState.waiting)
                                const SizedBox(width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2)),
                              const SizedBox(width: 8),
                              TextButton(onPressed: () {}, child: const Text('View All →')),
                            ]),
                          ],
                        ),
                      ),
                      const Divider(color: Color(0xFFcacfd6)),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ColHead('Time'), _ColHead('ID'), _ColHead('From'),
                          _ColHead('Amount'), _ColHead('Risk'), _ColHead('Action'),
                        ],
                      ),
                      const Divider(color: Color(0xFFcacfd6)),
                      Expanded(
                        child: feedItems.isEmpty
                            ? const Center(
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.inbox_outlined, color: Colors.grey, size: 40),
                                  SizedBox(height: 8),
                                  Text('No transactions yet', style: TextStyle(color: Colors.grey)),
                                ]),
                              )
                            : ListView.separated(
                                itemCount: feedItems.length,
                                separatorBuilder: (_, __) => const Divider(color: Color(0xFFcacfd6)),
                                itemBuilder: (_, i) {
                                  final txn = feedItems[i].value;
                                  final tier = txn['risk_tier']?.toString();
                                  final status = txn['status']?.toString();
                                  return Feed_Card(
                                    time: _shortTime(txn['timestamp']),
                                    ID: feedItems[i].key.substring(0, 8),
                                    snd_name: txn['accountFrom']?.toString() ?? '—',
                                    Amount: '₹${txn['amount'] ?? 0}',
                                    rsk_type: _riskLabel(tier, status),
                                    rsk_color: _riskColor(tier),
                                  );
                                },
                              ),
                      ),
                    ]),
                  ),

                  // Side panel
                  Column(children: [
                    // Graph placeholder
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(color: const Color(0xFFcacfd6)),
                      ),
                      height: MediaQuery.of(context).size.height * 0.3,
                      width: MediaQuery.of(context).size.width * 0.2,
                      child: Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.bar_chart_rounded, color: Colors.blue, size: 40),
                          Text('$total Total Txns',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text('$muleCount Mule Detected',
                              style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Recent alerts panel
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(color: const Color(0xFFcacfd6)),
                      ),
                      height: MediaQuery.of(context).size.height * 0.3,
                      width: MediaQuery.of(context).size.width * 0.2,
                      child: Column(children: [
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Recent Alerts',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Expanded(
                          child: alertItems.isEmpty
                              ? const Center(child: Text('No high-risk alerts',
                                  style: TextStyle(color: Colors.grey, fontSize: 13)))
                              : SingleChildScrollView(
                                  child: Column(
                                    children: alertItems.map((e) {
                                      final txn = e.value;
                                      final prob = ((txn['mule_probability'] ?? 0.0) as num).toDouble();
                                      return AlertCard(
                                        heading: '${txn['risk_tier'] ?? 'HIGH'} risk — ${txn['accountFrom'] ?? '?'}',
                                        description: 'Mule probability: ${(prob * 100).toStringAsFixed(1)}%  •  To: ${txn['accountTo'] ?? '?'}',
                                        timeDuration: _timeAgo(txn['timestamp']),
                                        icon: Icons.gpp_bad,
                                        icon_color: Colors.redAccent,
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ),
                      ]),
                    ),
                  ]),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required IconData stonksIcon,
    required Color stonksColor,
    required String stonksString,
    required BuildContext context,
  }) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.25,
      width: MediaQuery.of(context).size.width * 0.17,
      child: CardWidget(
        title: title,
        subtitle: value,
        icon: icon,
        iconColor: iconColor,
        headingColor: Colors.grey,
        subTitleColor: Colors.black,
        stonksIcon: stonksIcon,
        stonksColor: stonksColor,
        stonksString: stonksString,
      ),
    );
  }
}

// Small column header widget
class _ColHead extends StatelessWidget {
  final String text;
  const _ColHead(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w300, color: Colors.black));
}
