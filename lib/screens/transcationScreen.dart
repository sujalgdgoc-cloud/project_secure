import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:project_secure/services/db_service.dart';
import 'package:project_secure/screens/alertinfoScreen.dart';
import '../widgets/transcation_info_card.dart';

class TranscationScreen extends StatefulWidget {
  final ValueChanged<String>? onViewTxn;
  const TranscationScreen({super.key, this.onViewTxn});

  @override
  State<TranscationScreen> createState() => _TranscationScreenState();
}

class _TranscationScreenState extends State<TranscationScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Temporary selection state for dropdowns
  String _tempRange = 'Last 24 Hours';
  String _tempRisk = 'All Levels';
  String _tempChannel = 'All Channels';
  String _tempStatus = 'All Status';

  // Active filter state applied to the query
  String _activeRange = 'Last 24 Hours';
  String _activeRisk = 'All Levels';
  String _activeChannel = 'All Channels';
  String _activeStatus = 'All Status';

  // Pagination state
  int _currentPage = 1;
  final int _pageSize = 10;

  Map<String, dynamic> _safe(dynamic val) {
    if (val is Map) return Map<String, dynamic>.from(val);
    return <String, dynamic>{};
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt == null) return '—';
    final int ts = createdAt is int
        ? createdAt
        : (int.tryParse(createdAt.toString()) ?? 0);
    if (ts == 0) return '—';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts).toLocal();
    final hr = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final sec = dt.second.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hr:$min:$sec $period';
  }

  String _formatDate(dynamic createdAt) {
    if (createdAt == null) return '—';
    final int ts = createdAt is int
        ? createdAt
        : (int.tryParse(createdAt.toString()) ?? 0);
    if (ts == 0) return '—';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      body: StreamBuilder<DatabaseEvent>(
        stream: DbService.transactions.onValue,
        builder: (context, txnSnap) {
          return StreamBuilder<DatabaseEvent>(
            stream: DbService.predictions.onValue,
            builder: (context, predSnap) {
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

              // ── Combine & Filter ────────────────────────────────
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

              final filteredItems = allMerged.where((item) {
                // 1. Time range filter
                final createdAt = item.value['createdAt'];
                if (createdAt != null) {
                  final int ts = createdAt is int
                      ? createdAt
                      : (int.tryParse(createdAt.toString()) ?? 0);
                  if (ts != 0) {
                    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
                    final diff = DateTime.now().difference(dt);
                    if (_activeRange == 'Last 24 Hours' && diff.inHours > 24) return false;
                    if (_activeRange == 'Last 7 Days' && diff.inDays > 7) return false;
                  }
                }

                // 2. Risk level filter
                final String tier = (item.value['riskTier'] ?? 'LOW').toString().toUpperCase();
                if (_activeRisk != 'All Levels') {
                  if (_activeRisk.toUpperCase() == 'CRITICAL' && tier != 'CRITICAL') return false;
                  if (_activeRisk.toUpperCase() == 'HIGH' && tier != 'HIGH') return false;
                  if (_activeRisk.toUpperCase() == 'MEDIUM' && tier != 'MEDIUM') return false;
                  if (_activeRisk.toUpperCase() == 'LOW' && tier != 'LOW') return false;
                }

                // 3. Status filter
                final String status = (item.value['status'] ?? 'pending').toString().toLowerCase();
                if (_activeStatus != 'All Status') {
                  if (_activeStatus.toLowerCase() != status) return false;
                }

                // 4. Search Filter
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  final from = (item.value['accountFrom'] ?? '').toString().toLowerCase();
                  final to = (item.value['accountTo'] ?? '').toString().toLowerCase();
                  final id = item.key.toLowerCase();
                  if (!from.contains(q) && !to.contains(q) && !id.contains(q)) {
                    return false;
                  }
                }

                return true;
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

              // Layout calculations for responsive spacing
              final double screenWidth = MediaQuery.of(context).size.width;
              final double contentWidth = (screenWidth - 260 - 48).clamp(320.0, 9999.0);

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

                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title Header Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Transaction Ledger',
                                    style: TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDBEAFE),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          totalFiltered.toString(),
                                          style: const TextStyle(
                                            color: Color(0xFF1E40AF),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Total',
                                          style: TextStyle(
                                            color: Color(0xFF1E40AF),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {},
                                    label: const Text('Save View'),
                                    icon: const Icon(Icons.save_alt, size: 16),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF334155),
                                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  FilledButton.icon(
                                    onPressed: () {},
                                    label: const Text('Export CSV'),
                                    icon: const Icon(Icons.arrow_drop_up_outlined, size: 16),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF0074BD),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Sync Status subtitle
                          Row(
                            children: const [
                              CircleAvatar(
                                backgroundColor: Color(0xFF22C55E),
                                radius: 5,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Real-time transaction syncing active",
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Filter Card
                          Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // 1. Data Range Filter Dropdown
                                  _buildFilterDropdown(
                                    label: 'Data range',
                                    value: _tempRange,
                                    items: ['Last 24 Hours', 'Last 7 Days', 'All Time'],
                                    onChanged: (val) => setState(() => _tempRange = val!),
                                  ),
                                  // 2. Risk Level Filter Dropdown
                                  _buildFilterDropdown(
                                    label: 'Risk Level',
                                    value: _tempRisk,
                                    items: ['All Levels', 'Critical', 'High', 'Medium', 'Low'],
                                    onChanged: (val) => setState(() => _tempRisk = val!),
                                  ),
                                  // 3. Channel Filter Dropdown
                                  _buildFilterDropdown(
                                    label: 'Channel',
                                    value: _tempChannel,
                                    items: ['All Channels', 'UPI'],
                                    onChanged: (val) => setState(() => _tempChannel = val!),
                                  ),
                                  // 4. Status Filter Dropdown
                                  _buildFilterDropdown(
                                    label: 'Status',
                                    value: _tempStatus,
                                    items: [
                                      'All Status',
                                      'pending',
                                      'analyzing',
                                      'analyzed',
                                      'safe',
                                      'held',
                                      'escalated',
                                      'analysis_failed'
                                    ],
                                    onChanged: (val) => setState(() => _tempStatus = val!),
                                  ),

                                  // Actions Buttons
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _tempRange = 'Last 24 Hours';
                                            _tempRisk = 'All Levels';
                                            _tempChannel = 'All Channels';
                                            _tempStatus = 'All Status';
                                            _activeRange = 'Last 24 Hours';
                                            _activeRisk = 'All Levels';
                                            _activeChannel = 'All Channels';
                                            _activeStatus = 'All Status';
                                            _currentPage = 1;
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          backgroundColor: const Color(0xFFF1F5F9),
                                          foregroundColor: const Color(0xFF475569),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        ),
                                        child: const Text('RESET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _activeRange = _tempRange;
                                            _activeRisk = _tempRisk;
                                            _activeChannel = _tempChannel;
                                            _activeStatus = _tempStatus;
                                            _currentPage = 1;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0F172A),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        ),
                                        child: const Text('Apply Filter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Table Card
                          Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                // Table Header Column Row
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                                  child: Row(
                                    children: const [
                                      Expanded(flex: 3, child: Text('Time', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold))),
                                      Expanded(flex: 3, child: Text('Transaction ID', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold))),
                                      Expanded(flex: 4, child: Text('Sender', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold))),
                                      Expanded(flex: 4, child: Text('Receiver', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold))),
                                      Expanded(flex: 3, child: Text('Amount', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold))),
                                      Expanded(flex: 2, child: Text('Channel', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold))),
                                      Expanded(flex: 3, child: Text('Risk Score', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold))),
                                      Expanded(flex: 1, child: Text('Action', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                                // Table Rows List
                                if (pageItems.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 60.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'No transactions match the selected filters.',
                                          style: TextStyle(color: Colors.grey, fontSize: 15),
                                        ),
                                      ],
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

                                      final timeStr = _formatTime(data['createdAt']);
                                      final dateStr = _formatDate(data['createdAt']);
                                      final accountFrom = data['accountFrom']?.toString() ?? '—';
                                      final accountTo = data['accountTo']?.toString() ?? '—';
                                      final amountVal = data['amount'] ?? 0;
                                      final String formattedAmt = '₹${amountVal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

                                      final probability = (data['probability'] as num?)?.toDouble() ?? 0.0;
                                      final String tier = (data['riskTier'] ?? 'LOW').toString();
                                      final String scoreStr = probability > 0 ? (probability * 100).round().toString() : '—';

                                      Color riskColor = Colors.green;
                                      if (tier.toUpperCase() == 'CRITICAL' || tier.toUpperCase() == 'HIGH') {
                                        riskColor = Colors.red;
                                      } else if (tier.toUpperCase() == 'MEDIUM') {
                                        riskColor = Colors.orange;
                                      }

                                      return InkWell(
                                        onTap: () {
                                          if (widget.onViewTxn != null) {
                                            widget.onViewTxn!(txnId);
                                          } else {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => AlertInfo(txnId: txnId),
                                              ),
                                            );
                                          }
                                        },
                                        child: TransactionInfoCard(
                                          time: timeStr,
                                          date: dateStr,
                                          txnID: txnId.length > 12 ? 'TXN-${txnId.substring(0, 8).toUpperCase()}' : txnId,
                                          sender: accountFrom,
                                          accNo: 'A/C ...${accountFrom.length > 4 ? accountFrom.substring(accountFrom.length - 4) : accountFrom}',
                                          receiver: accountTo,
                                          typeTransaction: 'External Transfer',
                                          amount: formattedAmt,
                                          icon: Icons.swap_horiz,
                                          typeTXN: 'UPI',
                                          riskScore: scoreStr,
                                          riskColor: riskColor,
                                          riskTier: tier,
                                          onViewDetails: () {
                                            if (widget.onViewTxn != null) {
                                              widget.onViewTxn!(txnId);
                                            } else {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => AlertInfo(txnId: txnId),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),

                                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                                // Pagination Controls
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Showing ${startIndex + 1} to ${endIndex.clamp(0, totalFiltered)} of $totalFiltered transactions',
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(color: const Color(0xFFE2E8F0)),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.chevron_left, size: 20),
                                                  onPressed: _currentPage > 1
                                                      ? () => setState(() => _currentPage--)
                                                      : null,
                                                  splashRadius: 20,
                                                ),
                                                Container(
                                                  height: 32,
                                                  width: 1,
                                                  color: const Color(0xFFE2E8F0),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                                  child: Text(
                                                    'Page $_currentPage of $totalPages',
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                                  ),
                                                ),
                                                Container(
                                                  height: 32,
                                                  width: 1,
                                                  color: const Color(0xFFE2E8F0),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.chevron_right, size: 20),
                                                  onPressed: _currentPage < totalPages
                                                      ? () => setState(() => _currentPage++)
                                                      : null,
                                                  splashRadius: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              icon: const Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF64748B)),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
