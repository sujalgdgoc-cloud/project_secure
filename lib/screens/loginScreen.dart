import 'package:flutter/material.dart';
import 'package:project_secure/screens/aiModelScreen.dart';
import 'package:project_secure/screens/alertScreen.dart';
import 'package:project_secure/screens/homepage.dart';
import 'package:project_secure/screens/transcationScreen.dart';
import 'package:project_secure/screens/alertinfoScreen.dart';
import 'package:project_secure/screens/muleAccountScreen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:project_secure/services/db_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _currentIndex = 0;
  bool _extended = false;
  String? _selectedTxnId;

  @override
  void initState() {
    super.initState();
    // Seed static data (signalDefinitions + config) and migrate old records once.
    DbService.seedStatics().catchError((_) {});
    DbService.migrateOldRecords().catchError((_) {});
  }

  List<Widget> get _pages => [
    Homepage(
      onViewAll: () => setState(() { _currentIndex = 2; _selectedTxnId = null; }),
      onViewTxn: (txnId) => setState(() => _selectedTxnId = txnId),
    ),
    AlertScreen(onViewTxn: (txnId) => setState(() => _selectedTxnId = txnId)),
    TranscationScreen(onViewTxn: (txnId) => setState(() => _selectedTxnId = txnId)),
    const AiModelScreen(),
    MuleAccountScreen(onViewTxn: (txnId) => setState(() => _selectedTxnId = txnId)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          Container(
            width: 260,
            color: const Color(0xFF071424), // premium dark navy
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 32, bottom: 32),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.asset('assets/logo.png', height: 40, width: 40),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'MuleTrace',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            'Institutional Security',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Main Navigation Options
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildMenuItem(0, Icons.grid_view_rounded, 'Dashboard'),
                      _buildMenuItem(1, Icons.crisis_alert_sharp, 'Alerts', showBadge: true),
                      _buildMenuItem(2, Icons.receipt_long_rounded, 'Transactions'),
                      _buildMenuItem(3, Icons.model_training_rounded, 'AI Model'),
                      _buildMenuItem(4, Icons.manage_accounts_rounded, 'Mule Accounts'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Expanded(
            child: _selectedTxnId != null
                ? AlertInfo(
                    txnId: _selectedTxnId,
                    onBack: () => setState(() => _selectedTxnId = null),
                  )
                : _pages[_currentIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title, {bool showBadge = false}) {
    final isSelected = _currentIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0074BD) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        trailing: showBadge
            ? StreamBuilder<DatabaseEvent>(
                stream: DbService.alerts.onValue,
                builder: (context, snapshot) {
                  int count = 0;
                  if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                    final val = snapshot.data!.snapshot.value;
                    if (val is Map) {
                      count = val.length;
                    }
                  }
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              )
            : null,
        onTap: () {
          setState(() {
            _currentIndex = index;
            _selectedTxnId = null;
          });
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        dense: true,
      ),
    );
  }
}
