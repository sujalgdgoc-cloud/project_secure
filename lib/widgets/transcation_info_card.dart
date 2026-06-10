import 'package:flutter/material.dart';

class TransactionInfoCard extends StatelessWidget {
  final String time;
  final String date;
  final String txnID;
  final String sender;
  final String accNo;
  final String receiver;
  final String typeTransaction;
  final String amount;
  final IconData icon;
  final String typeTXN;
  final String riskScore;
  final Color riskColor;
  final String riskTier;
  final VoidCallback onViewDetails;

  const TransactionInfoCard({
    super.key,
    required this.time,
    required this.date,
    required this.txnID,
    required this.sender,
    required this.accNo,
    required this.receiver,
    required this.typeTransaction,
    required this.amount,
    required this.icon,
    required this.typeTXN,
    required this.riskScore,
    required this.riskColor,
    required this.riskTier,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    // Styling values for the risk badges
    Color badgeBgColor = const Color(0xFFF3F4F6);
    Color badgeTextColor = const Color(0xFF4B5563);
    String badgeText = 'LOW';

    final String tier = riskTier.toUpperCase();
    if (tier == 'CRITICAL' || tier == 'HIGH') {
      badgeBgColor = const Color(0xFFFEE2E2);
      badgeTextColor = const Color(0xFFEF4444);
      badgeText = 'HIGH';
    } else if (tier == 'MEDIUM') {
      badgeBgColor = const Color(0xFFFEF3C7);
      badgeTextColor = const Color(0xFFD97706);
      badgeText = 'MEDIUM';
    } else if (tier == 'LOW') {
      badgeBgColor = const Color(0xFFDBEAFE);
      badgeTextColor = const Color(0xFF2563EB);
      badgeText = 'LOW';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
      child: Row(
        children: [
          // 1. Time / Date
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // 2. Transaction ID
          Expanded(
            flex: 3,
            child: Text(
              txnID,
              style: const TextStyle(
                color: Color(0xFF0074BD),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 3. Sender
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  sender,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  accNo,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // 4. Receiver
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  receiver,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  typeTransaction,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // 5. Amount
          Expanded(
            flex: 3,
            child: Text(
              amount,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 6. Channel
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  typeTXN,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 7. Risk Score Badge
          Expanded(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (riskScore != '—' && riskScore.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          '($riskScore)',
                          style: TextStyle(
                            color: badgeTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 8. Action (Eye icon)
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: Color(0xFF0074BD),
                  size: 20,
                ),
                onPressed: onViewDetails,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
