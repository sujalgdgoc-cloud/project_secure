import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:project_secure/services/db_service.dart';

class Homepage extends StatefulWidget {
  final VoidCallback? onViewAll;
  final ValueChanged<String>? onViewTxn;
  const Homepage({super.key, this.onViewAll, this.onViewTxn});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentPage = 1;
  static const int _pageSize = 10;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Helper to safely convert Firebase map to Map<String, dynamic>
  static Map<String, dynamic> _safe(dynamic raw) {
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  // Parses Unix ms or ISO string into a time-ago label
  static String _timeAgo(dynamic ts) {
    if (ts == null) return '—';
    try {
      final dt = DbService.parseTs(ts);
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '—';
    }
  }

  static String _shortTime(dynamic ts) {
    if (ts == null) return '—';
    try {
      final dt = DbService.parseTs(ts).toLocal();
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
      case 'CRITICAL':
      case 'HIGH':
        return const Color(0xFFFEE2E2); // Light red background
      case 'MEDIUM':
        return const Color(0xFFFEF3C7); // Light amber background
      case 'LOW':
        return const Color(0xFFDBEAFE); // Light blue background
      default:
        return const Color(0xFFF3F4F6); // Light grey background
    }
  }

  static Color _riskTextColor(String? tier) {
    switch ((tier ?? '').toUpperCase()) {
      case 'CRITICAL':
      case 'HIGH':
        return const Color(0xFFDC2626); // Red text
      case 'MEDIUM':
        return const Color(0xFFD97706); // Amber text
      case 'LOW':
        return const Color(0xFF2563EB); // Blue text
      default:
        return const Color(0xFF4B5563); // Grey text
    }
  }

  static String _riskLabel(String? tier, String? status) {
    if (status == 'pending' || status == 'analyzing') return 'ANALYZING';
    if (status == 'analysis_failed') return 'FAILED';
    final t = (tier ?? 'UNKNOWN').toUpperCase();
    if (t == 'PENDING' || t == 'UNKNOWN') return 'PENDING';
    return '$t RISK';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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

                  // ── Compute Metrics ─────────────────────────────────
                  final total = txnMap.length;
                  final highRisk = predMap.values.where((p) {
                    final tier = (p['riskTier'] ?? '').toString().toUpperCase();
                    return tier == 'HIGH' || tier == 'CRITICAL';
                  }).length;
                  final muleCount = alertMap.length;
                  final underReview = txnMap.values.where((t) {
                    final s = (t['status'] ?? '').toString();
                    return s == 'pending' || s == 'analyzing';
                  }).length;

                  // ── Compute Dynamic Metrics & Trends ────────────────
                  final double analyzedProgress = total > 0 ? (total - underReview) / total : 0.0;
                  final String totalTrend = total > 0 ? '↗${((total / 15) * 100).clamp(1, 99).toStringAsFixed(0)}%' : '0%';
                  final String riskTrend = total > 0 ? '↗${((highRisk / total.clamp(1, 999999)) * 100).toStringAsFixed(0)}%' : '0%';
                  final String muleTrend = total > 0 ? '↘${((muleCount / total.clamp(1, 999999)) * 100).toStringAsFixed(0)}%' : '0%';
                  final String reviewTrend = underReview > 0 ? '↗$underReview' : '— Stable';

                  final Color riskTrendColor = highRisk > 0 ? const Color(0xFFEF4444) : const Color(0xFF64748B);
                  final Color muleTrendColor = muleCount > 0 ? const Color(0xFFD97706) : const Color(0xFF64748B);
                  final Color reviewTrendColor = underReview > 0 ? const Color(0xFF3B82F6) : const Color(0xFF64748B);

                  final IconData riskIcon = highRisk > 0 ? Icons.warning_amber_rounded : Icons.gpp_good_outlined;
                  final Color riskIconBg = highRisk > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF);
                  final Color riskIconColor = highRisk > 0 ? const Color(0xFFEF4444) : const Color(0xFF22C55E);

                  final IconData muleIcon = muleCount > 0 ? Icons.no_accounts_outlined : Icons.supervised_user_circle_outlined;
                  final Color muleIconBg = muleCount > 0 ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4);
                  final Color muleIconColor = muleCount > 0 ? const Color(0xFFD97706) : const Color(0xFF15803D);

                  final IconData reviewIcon = underReview > 0 ? Icons.assignment_outlined : Icons.assignment_turned_in_outlined;
                  final Color reviewIconBg = underReview > 0 ? const Color(0xFFF8FAFC) : const Color(0xFFF0FDF4);
                  final Color reviewIconColor = underReview > 0 ? const Color(0xFF64748B) : const Color(0xFF15803D);

                  // ── Risk Activity Dynamic Bar Calculations ──────────
                  final now = DateTime.now();
                  final List<int> txnCounts = List.filled(6, 0);
                  final List<int> riskCounts = List.filled(6, 0);

                  for (final entry in txnMap.entries) {
                    final data = entry.value;
                    final createdAtStr = data['createdAt']?.toString();
                    if (createdAtStr == null) continue;
                    final parsedTime = DateTime.tryParse(createdAtStr);
                    if (parsedTime == null) continue;

                    final diffHours = now.difference(parsedTime).inHours;
                    if (diffHours >= 0 && diffHours < 24) {
                      final int bucketIndex = 5 - (diffHours ~/ 4);
                      if (bucketIndex >= 0 && bucketIndex < 6) {
                        txnCounts[bucketIndex]++;
                        final isMule = data['mule'] == true;
                        final pred = predMap[entry.key];
                        final isHighRisk = pred != null &&
                            (pred['riskTier'] == 'CRITICAL' || pred['riskTier'] == 'HIGH');
                        if (isMule || isHighRisk) {
                          riskCounts[bucketIndex]++;
                        }
                      }
                    }
                  }

                  final List<double> barHeights = List.filled(6, 15.0);
                  for (int i = 0; i < 6; i++) {
                    if (txnCounts[i] > 0) {
                      final double computed = (txnCounts[i] * 12.0) + (riskCounts[i] * 25.0);
                      barHeights[i] = computed.clamp(15.0, 95.0);
                    }
                  }

                  int highlightIndex = 5;
                  double maxRisk = -1;
                  for (int i = 0; i < 6; i++) {
                    final double score = (riskCounts[i] * 2.0) + txnCounts[i];
                    if (score > maxRisk && score > 0) {
                      maxRisk = score;
                      highlightIndex = i;
                    }
                  }

                  String formatBucketLabel(DateTime dt) {
                    final hr = dt.hour.toString().padLeft(2, '0');
                    return '$hr:00';
                  }

                  final String lbl0 = formatBucketLabel(now.subtract(const Duration(hours: 20)));
                  final String lbl1 = formatBucketLabel(now.subtract(const Duration(hours: 16)));
                  final String lbl2 = formatBucketLabel(now.subtract(const Duration(hours: 12)));
                  final String lbl3 = formatBucketLabel(now.subtract(const Duration(hours: 8)));
                  final String lbl4 = formatBucketLabel(now.subtract(const Duration(hours: 4)));
                  const String lbl5 = 'Current';

                  // ── Sort & Merge transactions ─────────────────────────────
                  final sortedEntries = txnMap.entries.toList()
                    ..sort((a, b) {
                      final ta = a.value['createdAt'];
                      final tb = b.value['createdAt'];
                      final int da = ta is int
                          ? ta
                          : (ta != null ? DateTime.tryParse(ta.toString())?.millisecondsSinceEpoch ?? 0 : 0);
                      final int db = tb is int
                          ? tb
                          : (tb != null ? DateTime.tryParse(tb.toString())?.millisecondsSinceEpoch ?? 0 : 0);
                      return db.compareTo(da);
                    });

                  final allMerged = sortedEntries.map((e) {
                    final pred = predMap[e.key] ?? {};
                    return MapEntry(e.key, {...e.value, ...pred});
                  }).toList();

                  // Filter by Search Query
                  final filteredItems = allMerged.where((item) {
                    if (_searchQuery.isEmpty) return true;
                    final query = _searchQuery.toLowerCase();
                    final from = (item.value['accountFrom'] ?? '').toString().toLowerCase();
                    final to = (item.value['accountTo'] ?? '').toString().toLowerCase();
                    final id = item.key.toLowerCase();
                    return from.contains(query) || to.contains(query) || id.contains(query);
                  }).toList();

                  // Pagination Calculations
                  final totalFiltered = filteredItems.length;
                  final totalPages = (totalFiltered / _pageSize).ceil().clamp(1, 9999);
                  if (_currentPage > totalPages) {
                    _currentPage = totalPages;
                  }
                  final startIndex = (_currentPage - 1) * _pageSize;
                  final endIndex = (startIndex + _pageSize).clamp(0, totalFiltered);
                  final pageItems = filteredItems.sublist(startIndex, endIndex);

                  // Recent Alerts Panel items
                  final alertItems = alertMap.entries.take(3).map((e) {
                    final txn = txnMap[e.key] ?? {};
                    return MapEntry(e.key, {...txn, ...e.value});
                  }).toList();

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final bool showProfileText = constraints.maxWidth > 1150;
                      final double searchBarWidth = constraints.maxWidth > 850 ? 300.0 : 180.0;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Custom Header / App Bar ─────────────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Good Morning, Team BOI',
                                      style: TextStyle(
                                        fontSize: 24,
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
                                      width: searchBarWidth,
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
                                            _currentPage = 1;
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
                                // User Profile
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(100),
                                      child: Image.network(
                                        'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150',
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Color(0xFFCBD5E1),
                                          child: Icon(Icons.person, size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Neil Verma',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Metrics Row ─────────────────────────────────────────────
                        constraints.maxWidth > 950
                            ? Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricCard(
                                      title: 'TOTAL TRANSACTIONS',
                                      value: total >= 1000 ? '${(total / 1000).toStringAsFixed(1)}k' : '$total',
                                      trend: totalTrend,
                                      trendColor: const Color(0xFF22C55E),
                                      icon: Icons.account_balance_wallet_outlined,
                                      iconBg: const Color(0xFFEFF6FF),
                                      iconColor: const Color(0xFF3B82F6),
                                      progress: analyzedProgress,
                                      subtitle: '${(analyzedProgress * 100).toStringAsFixed(0)}% analyzed by AI',
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildMetricCard(
                                      title: 'HIGH RISK ALERTS',
                                      value: '$highRisk',
                                      trend: riskTrend,
                                      trendColor: riskTrendColor,
                                      icon: riskIcon,
                                      iconBg: riskIconBg,
                                      iconColor: riskIconColor,
                                      subtitle: 'Requires immediate attention',
                                      subtitleColor: riskTrendColor,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildMetricCard(
                                      title: 'MULE ACCOUNTS',
                                      value: '$muleCount',
                                      trend: muleTrend,
                                      trendColor: muleTrendColor,
                                      icon: muleIcon,
                                      iconBg: muleIconBg,
                                      iconColor: muleIconColor,
                                      subtitle: 'Identified through AI clustering',
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildMetricCard(
                                      title: 'UNDER REVIEW',
                                      value: '$underReview',
                                      trend: reviewTrend,
                                      trendColor: reviewTrendColor,
                                      icon: reviewIcon,
                                      iconBg: reviewIconBg,
                                      iconColor: reviewIconColor,
                                      subtitle: 'Awaiting manual validation',
                                    ),
                                  ),
                                ],
                              )
                            : Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  _buildMetricCard(
                                    title: 'TOTAL TRANSACTIONS',
                                    value: total >= 1000 ? '${(total / 1000).toStringAsFixed(1)}k' : '$total',
                                    trend: totalTrend,
                                    trendColor: const Color(0xFF22C55E),
                                    icon: Icons.account_balance_wallet_outlined,
                                    iconBg: const Color(0xFFEFF6FF),
                                    iconColor: const Color(0xFF3B82F6),
                                    width: (constraints.maxWidth - 64) / 2,
                                    progress: analyzedProgress,
                                    subtitle: '${(analyzedProgress * 100).toStringAsFixed(0)}% analyzed by AI',
                                  ),
                                  _buildMetricCard(
                                    title: 'HIGH RISK ALERTS',
                                    value: '$highRisk',
                                    trend: riskTrend,
                                    trendColor: riskTrendColor,
                                    icon: riskIcon,
                                    iconBg: riskIconBg,
                                    iconColor: riskIconColor,
                                    width: (constraints.maxWidth - 64) / 2,
                                    subtitle: 'Requires immediate attention',
                                    subtitleColor: riskTrendColor,
                                  ),
                                  _buildMetricCard(
                                    title: 'MULE ACCOUNTS',
                                    value: '$muleCount',
                                    trend: muleTrend,
                                    trendColor: muleTrendColor,
                                    icon: muleIcon,
                                    iconBg: muleIconBg,
                                    iconColor: muleIconColor,
                                    width: (constraints.maxWidth - 64) / 2,
                                    subtitle: 'Identified through AI clustering',
                                  ),
                                  _buildMetricCard(
                                    title: 'UNDER REVIEW',
                                    value: '$underReview',
                                    trend: reviewTrend,
                                    trendColor: reviewTrendColor,
                                    icon: reviewIcon,
                                    iconBg: reviewIconBg,
                                    iconColor: reviewIconColor,
                                    width: (constraints.maxWidth - 64) / 2,
                                    subtitle: 'Awaiting manual validation',
                                  ),
                                ],
                              ),
                        const SizedBox(height: 24),

                        // ── Main Content Grid ───────────────────────────────────────
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isLargeScreen = constraints.maxWidth > 950;
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Panel: Live Transaction Feed
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Live Transaction Feed',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: widget.onViewAll,
                                                child: Row(
                                                  children: const [
                                                    Text(
                                                      'View All',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        color: Color(0xFF2563EB),
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Icon(Icons.arrow_forward, size: 14, color: Color(0xFF2563EB)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Table Header
                                        Container(
                                          color: const Color(0xFFF8FAFC),
                                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                                          child: Row(
                                            children: const [
                                              Expanded(flex: 2, child: Text('TIME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                              Expanded(flex: 3, child: Text('TRANSACTION ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                              Expanded(flex: 3, child: Text('SENDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                              Expanded(flex: 3, child: Text('AMOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                              Expanded(flex: 2, child: Text('RISK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                              SizedBox(width: 50, child: Text('ACTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)), textAlign: TextAlign.center)),
                                            ],
                                          ),
                                        ),
                                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                        // Table Body
                                        if (pageItems.isEmpty)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 40.0),
                                            child: Center(
                                              child: Text(
                                                'No transactions found',
                                                style: TextStyle(color: Color(0xFF64748B)),
                                              ),
                                            ),
                                          )
                                        else
                                          ListView.separated(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: pageItems.length,
                                            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                            itemBuilder: (context, index) {
                                              final item = pageItems[index];
                                              final txnId = item.key;
                                              final data = item.value;
                                              final timeStr = _shortTime(data['createdAt']);
                                              final sender = data['accountFrom']?.toString() ?? '—';
                                              final amountVal = data['amount'] ?? 0;
                                              final tier = data['riskTier']?.toString();
                                              final status = data['status']?.toString();
                                              final rLabel = _riskLabel(tier, status);
                                              final rBg = _riskColor(tier);
                                              final rText = _riskTextColor(tier);

                                              return Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                                                child: Row(
                                                  children: [
                                                    Expanded(flex: 2, child: Text(timeStr, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                                                    Expanded(flex: 3, child: Text(txnId.length > 12 ? 'TXN-${txnId.substring(0, 8).toUpperCase()}' : txnId, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500))),
                                                    Expanded(flex: 3, child: Text(sender, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                                                    Expanded(
                                                      flex: 3,
                                                      child: Text(
                                                        '₹${amountVal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 2,
                                                      child: UnconstrainedBox(
                                                        alignment: Alignment.centerLeft,
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: rBg,
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            rLabel,
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                              color: rText,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 50,
                                                      child: Center(
                                                        child: InkWell(
                                                          onTap: () {
                                                            if (widget.onViewTxn != null) {
                                                              widget.onViewTxn!(txnId);
                                                            } else {
                                                              _showDetailsDialog(context, txnId, data);
                                                            }
                                                          },
                                                          child: const Icon(
                                                            Icons.visibility_outlined,
                                                            color: Color(0xFF3B82F6),
                                                            size: 18,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                        // Pagination Controls
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Showing ${startIndex + 1} to ${endIndex.clamp(0, totalFiltered)} of $totalFiltered transactions',
                                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                              ),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.chevron_left),
                                                    onPressed: _currentPage > 1
                                                        ? () => setState(() => _currentPage--)
                                                        : null,
                                                  ),
                                                  Text(
                                                    'Page $_currentPage of $totalPages',
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.chevron_right),
                                                    onPressed: _currentPage < totalPages
                                                        ? () => setState(() => _currentPage++)
                                                        : null,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isLargeScreen) const SizedBox(width: 24),
                                // Right Side Panel: Risk Activity & Recent Alerts
                                if (isLargeScreen)
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      children: [
                                        // Risk Activity Bar Chart Card
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          padding: const EdgeInsets.all(20.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text(
                                                    'Risk Activity',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      children: const [
                                                        Text('Last 24 Hours', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                                        SizedBox(width: 4),
                                                        Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF64748B)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 24),
                                              // Custom Bar Chart Representation
                                              SizedBox(
                                                height: 130,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    _buildBar(barHeights[0], lbl0, highlightIndex == 0),
                                                    _buildBar(barHeights[1], lbl1, highlightIndex == 1),
                                                    _buildBar(barHeights[2], lbl2, highlightIndex == 2),
                                                    _buildBar(barHeights[3], lbl3, highlightIndex == 3),
                                                    _buildBar(barHeights[4], lbl4, highlightIndex == 4),
                                                    _buildBar(barHeights[5], lbl5, highlightIndex == 5),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        // Recent Alerts Card
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          padding: const EdgeInsets.all(20.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Recent Alerts',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              if (alertItems.isEmpty)
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 20.0),
                                                  child: Center(
                                                    child: Text(
                                                      'No recent alerts',
                                                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                                    ),
                                                  ),
                                                )
                                              else
                                                Column(
                                                  children: alertItems.map((e) {
                                                    final txnId = e.key;
                                                    final merged = e.value;
                                                    final prob = ((merged['probability'] ?? 0.0) as num).toDouble();
                                                    return GestureDetector(
                                                      onTap: () {
                                                        if (widget.onViewTxn != null) {
                                                          widget.onViewTxn!(txnId);
                                                        }
                                                      },
                                                      child: _buildAlertCard(
                                                        title: 'High-risk mule pattern detected',
                                                        description: 'Mule probability: ${(prob * 100).toStringAsFixed(1)}% • A/C: ${merged['accountFrom'] ?? '?'}\nTo A/C: ${merged['accountTo'] ?? '?'}',
                                                        time: _timeAgo(merged['analyzedAt']),
                                                        icon: Icons.warning_amber_rounded,
                                                        iconColor: const Color(0xFFEF4444),
                                                        iconBg: const Color(0xFFFEF2F2),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        // ── Screen size fallback side panels (Vertical list when screen is thin) ──
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isLargeScreen = constraints.maxWidth > 950;
                            if (isLargeScreen) return const SizedBox.shrink();
                            return Column(
                              children: [
                                const SizedBox(height: 24),
                                // Risk Activity
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Risk Activity',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        height: 120,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            _buildBar(45, '06:00', false),
                                            _buildBar(60, '12:00', false),
                                            _buildBar(30, '', false),
                                            _buildBar(85, '18:00', false),
                                            _buildBar(95, '', true),
                                            _buildBar(65, 'Current', false),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Recent Alerts
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Recent Alerts',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 16),
                                      ...alertItems.map((e) {
                                        final txnId = e.key;
                                        final merged = e.value;
                                        final prob = ((merged['probability'] ?? 0.0) as num).toDouble();
                                        return GestureDetector(
                                          onTap: () {
                                            if (widget.onViewTxn != null) {
                                              widget.onViewTxn!(txnId);
                                            }
                                          },
                                          child: _buildAlertCard(
                                            title: 'High-risk mule pattern detected',
                                            description: 'Mule probability: ${(prob * 100).toStringAsFixed(1)}% • A/C: ${merged['accountFrom'] ?? '?'}\nTo A/C: ${merged['accountTo'] ?? '?'}',
                                            time: _timeAgo(merged['analyzedAt']),
                                            icon: Icons.warning_amber_rounded,
                                            iconColor: const Color(0xFFEF4444),
                                            iconBg: const Color(0xFFFEF2F2),
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 40),

                        // ── Bottom Footer ───────────────────────────────────────────
                        const Divider(color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '© 2025 Bank of India Fraud Management. All rights reserved.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                            Row(
                              children: [
                                const Text(
                                  'v2.4.1-stable',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 20),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF22C55E),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'System Status: Operational',
                                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                const Text(
                                  'Privacy Policy',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), decoration: TextDecoration.underline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ── Helper Widgets ────────────────────────────────────────────────────────

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String trend,
    required Color trendColor,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    double? width,
    double? progress,
    String? subtitle,
    Color? subtitleColor,
  }) {
    return Container(
      width: width != null ? width.clamp(200.0, 400.0) : null,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Row(
                children: [
                  Icon(
                    trend.startsWith('↘') ? Icons.trending_down : Icons.trending_up,
                    color: trendColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trend,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                minHeight: 4,
              ),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: subtitleColor ?? const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBar(double heightPercentage, String label, bool isAlert) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: heightPercentage,
          decoration: BoxDecoration(
            color: isAlert ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isAlert ? const Color(0xFFFCA5A5) : const Color(0xFFBFDBFE),
              width: 1,
            ),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String description,
    required String time,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, String txnId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Transaction Detail', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Transaction ID', txnId),
                  _buildDetailRow('Sender A/C', data['accountFrom']?.toString() ?? '—'),
                  _buildDetailRow('Receiver A/C', data['accountTo']?.toString() ?? '—'),
                  _buildDetailRow('Amount', '₹${data['amount'] ?? 0}'),
                  _buildDetailRow('Status', (data['status'] ?? '—').toString().toUpperCase()),
                  _buildDetailRow('Created At', _shortTime(data['createdAt'])),
                  const Divider(height: 30),
                  const Text('AI Predictions & Signals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  _buildDetailRow('Mule Probability', data['probability'] != null ? '${((data['probability'] as num) * 100).toStringAsFixed(1)}%' : 'N/A'),
                  _buildDetailRow('Risk Score', (data['riskScore'] ?? 'N/A').toString()),
                  _buildDetailRow('Risk Tier', (data['riskTier'] ?? 'PENDING').toString().toUpperCase()),
                  _buildDetailRow('Model Version', (data['modelVersion'] ?? 'v1.0').toString()),
                  const SizedBox(height: 16),
                  const Text('Signals Triggered:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  if (data['signals'] == null || (data['signals'] as List).isEmpty)
                    const Text('No anomalies detected.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13))
                  else
                    ...((data['signals'] as List).map((sig) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.circle, size: 6, color: Color(0xFFEF4444)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(sig.toString(), style: const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
                            ],
                          ),
                        ))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 14)),
        ],
      ),
    );
  }
}
