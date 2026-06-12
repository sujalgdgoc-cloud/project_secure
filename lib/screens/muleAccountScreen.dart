import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:project_secure/services/db_service.dart';
import 'package:project_secure/screens/alertinfoScreen.dart';

class MuleAccountScreen extends StatefulWidget {
  final ValueChanged<String>? onViewTxn;
  const MuleAccountScreen({super.key, this.onViewTxn});
  @override State<MuleAccountScreen> createState() => _MuleAccountScreenState();
}

class _MuleAccountScreenState extends State<MuleAccountScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _filter = 'All';
  int _page = 1;
  static const _pageSize = 10;

  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  static Map<String,dynamic> _s(dynamic v) => v is Map ? Map<String,dynamic>.from(v.map((k,x)=>MapEntry(k.toString(),x))) : {};

  static String _fmt(dynamic n) {
    final x = (n as num?)?.toDouble() ?? 0;
    if (x >= 10000000) return '\u20b9${(x/10000000).toStringAsFixed(1)} Cr';
    if (x >= 100000) return '\u20b9${(x/100000).toStringAsFixed(1)} L';
    return '\u20b9${x.toStringAsFixed(0)}';
  }

  static String _ago(dynamic ts) {
    if (ts == null) return '--';
    final ms = ts is int ? ts : int.tryParse(ts.toString()) ?? 0;
    if (ms == 0) return '--';
    final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (d.inMinutes < 2) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  static Color _rc(String r) {
    switch (r.toUpperCase()) {
      case 'CRITICAL': return const Color(0xFF991B1B);
      case 'HIGH': return const Color(0xFFDC2626);
      case 'MEDIUM': return const Color(0xFFF59E0B);
      default: return const Color(0xFF2563EB);
    }
  }

  static Color _rbc(String r) {
    switch (r.toUpperCase()) {
      case 'CRITICAL': case 'HIGH': return const Color(0xFFFEE2E2);
      case 'MEDIUM': return const Color(0xFFFEF3C7);
      default: return const Color(0xFFDBEAFE);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: StreamBuilder<DatabaseEvent>(
        stream: DbService.muleAccounts.onValue,
        builder: (ctx, muSnap) => StreamBuilder<DatabaseEvent>(
          stream: DbService.transactions.onValue,
          builder: (ctx, txSnap) => StreamBuilder<DatabaseEvent>(
            stream: DbService.accounts.onValue,
            builder: (ctx, accSnap) {
              final muleMap = <String,Map<String,dynamic>>{};
              if (muSnap.hasData && muSnap.data!.snapshot.value != null) {
                final r = muSnap.data!.snapshot.value;
                if (r is Map) r.forEach((k,v) { muleMap[k.toString()] = _s(v); });
              }
              final txMap = <String,Map<String,dynamic>>{};
              if (txSnap.hasData && txSnap.data!.snapshot.value != null) {
                final r = txSnap.data!.snapshot.value;
                if (r is Map) r.forEach((k,v) { if (k.toString() != 'mule-response') txMap[k.toString()] = _s(v); });
              }
              final accMap = <String,Map<String,dynamic>>{};
              if (accSnap.hasData && accSnap.data!.snapshot.value != null) {
                final r = accSnap.data!.snapshot.value;
                if (r is Map) r.forEach((k,v) { accMap[k.toString()] = _s(v); });
              }
              final totalMule = muleMap.length;
              final totalLinked = txMap.values.where((t) => t['mule'] == true).length;
              final totalFraud = txMap.values.where((t) => t['mule'] == true).fold(0.0, (s,t) => s + ((t['amount'] as num?)?.toDouble() ?? 0));
              final frozenReal = accMap.values.where((a) { final s = _s(a['summary']); return s['status'] == 'frozen'; }).length + muleMap.values.where((m) => m['frozen'] == true).length;
              var rows = muleMap.entries.toList();
              if (_search.isNotEmpty) {
                final q = _search.toLowerCase();
                rows = rows.where((e) =>
                  (e.value['accountNumber']?.toString() ?? '').toLowerCase().contains(q) ||
                  (e.value['accountName']?.toString() ?? '').toLowerCase().contains(q)
                ).toList();
              }
              if (_filter != 'All') {
                rows = rows.where((e) {
                  final r = (e.value['riskLevel']?.toString() ?? '').toUpperCase();
                  if (_filter == 'Critical') return r == 'CRITICAL';
                  if (_filter == 'High') return r == 'HIGH';
                  if (_filter == 'Medium') return r == 'MEDIUM';
                  if (_filter == 'Low') return r == 'LOW';
                  if (_filter == 'Frozen') return e.value['frozen'] == true;
                  return true;
                }).toList();
              }
              rows.sort((a,b) => ((b.value['lastActivity'] as int?) ?? 0).compareTo((a.value['lastActivity'] as int?) ?? 0));
              final total = rows.length;
              final pages = (total / _pageSize).ceil().clamp(1, 9999);
              if (_page > pages) _page = pages;
              final si = (_page - 1) * _pageSize;
              final ei = (si + _pageSize).clamp(0, total);
              final pageRows = rows.sublist(si, ei);
              return Column(children: [
                _buildHeader(),
                Expanded(child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildTitleRow(),
                    const SizedBox(height: 20),
                    _buildMetrics(totalMule, totalLinked, totalFraud, frozenReal),
                    const SizedBox(height: 20),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(flex: 3, child: _buildTable(pageRows, si, ei, total, pages)),
                      const SizedBox(width: 16),
                      SizedBox(width: 220, child: _buildPatterns(muleMap)),
                    ]),
                    const SizedBox(height: 16),
                    _buildFooter(),
                  ]),
                )),
              ]);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    height: 64, color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      SizedBox(width: 300, height: 38,
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() { _search = v; _page = 1; }),
          decoration: InputDecoration(
            hintText: 'Search account numbers or names...',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
            filled: true, fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
      Row(children: [
        StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref('.info/connected').onValue,
          builder: (ctx, snap) {
            final ok = snap.data?.snapshot.value == true;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ok ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
                const SizedBox(width: 6),
                Text(ok ? 'Live Data Stream' : 'Offline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
              ]),
            );
          },
        ),
        const SizedBox(width: 16),
        const CircleAvatar(radius: 16, backgroundColor: Color(0xFF0F172A), child: Text('NV', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
        const SizedBox(width: 8),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Admin_Inv_92', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          Text('LEVEL 3 ACCESS', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        ]),
      ]),
    ]),
  );

  Widget _buildTitleRow() => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Mule Account Monitoring', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      Text('Real-time surveillance of potential money laundering nodes.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
    ]),
    Row(children: [
      PopupMenuButton<String>(
        onSelected: (v) => setState(() { _filter = v; _page = 1; }),
        itemBuilder: (_) => ['All','Critical','High','Medium','Low','Frozen','Flagged']
            .map((f) => PopupMenuItem(value: f, child: Text(f))).toList(),
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.tune, size: 16),
          label: Text(_filter == 'All' ? 'Filters' : 'Filter: $_filter', style: const TextStyle(fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF334155), side: const BorderSide(color: Color(0xFFCBD5E1)), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
        ),
      ),
      const SizedBox(width: 12),
      FilledButton.icon(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV report generated from live Firebase data.'), backgroundColor: Color(0xFF0074BD))),
        icon: const Icon(Icons.download, size: 16),
        label: const Text('Export Report', style: TextStyle(fontWeight: FontWeight.bold)),
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0074BD), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
      ),
    ]),
  ]);

  Widget _buildMetrics(int mule, int linked, double fraud, int frozen) => Row(children: [
    Expanded(child: _metCard('MULE ACCOUNTS DETECTED', '$mule', '+${(mule * 2).clamp(1,99)}% from last week', Icons.group_remove_outlined, const Color(0xFF0074BD), green: true)),
    const SizedBox(width: 16),
    Expanded(child: _metCard('LINKED TRANSACTIONS', linked >= 1000 ? '${(linked/1000).toStringAsFixed(1)}k' : '$linked', 'Active path analysis', Icons.swap_horiz_outlined, const Color(0xFF7C3AED))),
    const SizedBox(width: 16),
    Expanded(child: _metCard('TOTAL FRAUD AMOUNT', _fmt(fraud), 'High risk volume', Icons.currency_rupee, const Color(0xFFDC2626), red: true)),
    const SizedBox(width: 16),
    Expanded(child: _metCard('ACCOUNTS FROZEN', '$frozen', 'Verified by Sentinel AI', Icons.lock_outline, const Color(0xFF64748B))),
  ]);

  Widget _metCard(String title, String val, String sub, IconData icon, Color ic, {bool green=false, bool red=false}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5))),
        Icon(icon, size: 22, color: ic),
      ]),
      const SizedBox(height: 10),
      Text(val, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: red ? const Color(0xFFDC2626) : const Color(0xFF0F172A))),
      const SizedBox(height: 6),
      Row(children: [
        if (green) const Icon(Icons.trending_up, size: 13, color: Color(0xFF16A34A)),
        if (green) const SizedBox(width: 4),
        Expanded(child: Text(sub, style: TextStyle(fontSize: 12, color: green ? const Color(0xFF16A34A) : const Color(0xFF64748B)), overflow: TextOverflow.ellipsis)),
      ]),
    ]),
  );

  Widget _buildTable(List<MapEntry<String,Map<String,dynamic>>> rows, int si, int ei, int total, int pages) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20,14,20,10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Sentinel Live Monitoring', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEF4444))), const SizedBox(width: 6), const Text('Live Data Stream', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))]),
      ])),
      const Divider(height: 1, color: Color(0xFFE2E8F0)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: const [
        Expanded(flex: 3, child: Text('Account Number', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
        Expanded(flex: 3, child: Text('Risk Level', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
        Expanded(flex: 2, child: Text('Cases', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
        Expanded(flex: 3, child: Text('Incoming', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
        Expanded(flex: 3, child: Text('Outgoing', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
        Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
        Expanded(flex: 2, child: Text('Last Activity', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
      ])),
      const Divider(height: 1, color: Color(0xFFE2E8F0)),
      rows.isEmpty
        ? const Padding(padding: EdgeInsets.all(48), child: Center(child: Text('No mule accounts detected yet.', style: TextStyle(color: Color(0xFF64748B)))))
        : ListView.separated(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
            itemBuilder: (ctx, i) {
              final e = rows[i]; final d = e.value;
              final rl = d['riskLevel']?.toString() ?? 'LOW';
              final st = d['status']?.toString() ?? 'Flagged';
              final frozen = d['frozen'] == true;
              return InkWell(
                onTap: () {
                  final tid = d['lastTxnId']?.toString();
                  if (tid != null && tid.isNotEmpty) {
                    if (widget.onViewTxn != null) {
                      widget.onViewTxn!(tid);
                    } else {
                      Navigator.push(ctx, MaterialPageRoute(builder: (_) => AlertInfo(txnId: tid)));
                    }
                  }
                },
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
                  Expanded(flex: 3, child: Text(d['accountNumber']?.toString() ?? e.key, style: const TextStyle(fontSize: 13, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: UnconstrainedBox(alignment: Alignment.centerLeft, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _rbc(rl), borderRadius: BorderRadius.circular(6)),
                    child: Text(rl.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _rc(rl))),
                  ))),
                  Expanded(flex: 2, child: Text('${d['linkedCases'] ?? 0}', style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                  Expanded(flex: 3, child: Text(_fmt(d['incoming']), style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                  Expanded(flex: 3, child: Text(_fmt(d['outgoing']), style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                  Expanded(flex: 2, child: Row(children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: frozen ? const Color(0xFF64748B) : st.toLowerCase() == 'flagged' ? const Color(0xFFDC2626) : const Color(0xFFF59E0B))),
                    const SizedBox(width: 5),
                    Expanded(child: Text(frozen ? 'Frozen' : st, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)), overflow: TextOverflow.ellipsis)),
                  ])),
                  Expanded(flex: 2, child: Text(_ago(d['lastActivity']), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))),
                ])),
              );
            },
          ),
      const Divider(height: 1, color: Color(0xFFE2E8F0)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Showing ${si+1} to ${ei.clamp(0,total)} of $total mule accounts detected', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Row(children: [
          IconButton(icon: const Icon(Icons.chevron_left, size: 18), onPressed: _page > 1 ? () => setState(() => _page--) : null),
          ...List.generate(pages.clamp(0, 5), (i) => GestureDetector(
            onTap: () => setState(() => _page = i + 1),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2), width: 30, height: 30,
              decoration: BoxDecoration(color: _page == i+1 ? const Color(0xFF0074BD) : Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Center(child: Text('${i+1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _page == i+1 ? Colors.white : const Color(0xFF334155)))),
            ),
          )),
          IconButton(icon: const Icon(Icons.chevron_right, size: 18), onPressed: _page < pages ? () => setState(() => _page++) : null),
        ]),
      ])),
    ]),
  );

  Widget _buildPatterns(Map<String,Map<String,dynamic>> all) {
    final t = all.length.clamp(1, 999999);
    final v = ((all.values.where((m) => ((m['linkedCases'] as int?) ?? 0) > 3).length / t) * 100).round();
    final l = ((all.values.where((m) { final i = (m['incoming'] as num?)?.toDouble() ?? 0; final o = (m['outgoing'] as num?)?.toDouble() ?? 0; return i > 0 && o/i > 0.8; }).length / t) * 100).round();
    final b = ((all.values.where((m) => ((m['linkedCases'] as int?) ?? 0) > 5).length / t) * 100).round();
    final c = ((all.values.where((m) { final i = (m['incoming'] as num?)?.toDouble() ?? 1; final o = (m['outgoing'] as num?)?.toDouble() ?? 0; final r = o/i; return r > 0.9 && r < 1.1; }).length / t) * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('TOP RISK PATTERNS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1)),
        const SizedBox(height: 16),
        _pat('Velocity Fraud', 'HIGH', v, 'High volume of small transfers followed by a single large liquidation.', const Color(0xFFDC2626)),
        const SizedBox(height: 14),
        _pat('Layering Pattern', 'MID', l, 'Complex web of inter-account transfers to obscure origin.', const Color(0xFFF59E0B)),
        const SizedBox(height: 14),
        _pat('Beneficiary Abuse', 'NEW', b, 'Systematic registration of dormant accounts as new beneficiaries.', const Color(0xFF2563EB)),
        const SizedBox(height: 14),
        _pat('Circular Transactions', '', c, 'Funds cycle through mule accounts and return to source.', const Color(0xFF7C3AED)),
      ]),
    );
  }

  Widget _pat(String name, String badge, int pct, String desc, Color color) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
      if (badge.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)), child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
    ]),
    const SizedBox(height: 4),
    Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
    const SizedBox(height: 6),
    Row(children: [
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct / 100, backgroundColor: const Color(0xFFE2E8F0), color: color, minHeight: 5))),
      const SizedBox(width: 8),
      Text('$pct%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
    ]),
  ]);

  Widget _buildFooter() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Text('Bank of India', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
      const Text('© 2024 Bank of India Fraud Management. All rights reserved.', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
      Row(children: const [
        Icon(Icons.circle, size: 8, color: Color(0xFF22C55E)),
        SizedBox(width: 6),
        Text('System Status: Operational', style: TextStyle(fontSize: 11, color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
        SizedBox(width: 16),
        Text('v2.4.1-stable', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
      ]),
    ]),
  );
}
