import 'package:flutter/material.dart';

class TransactionInfoCard extends StatelessWidget {
  final String time;
  final String Date;
  final String txnID;
  final String sender;
  final String ACCNO;
  final String receiver;
  final String typeTransaction;
  final String amount;
  final IconData icon;
  final String typeTXN;
  final String riskScore;
  final Color riskColor;

  const TransactionInfoCard({super.key, required this.time, required this.Date, required this.txnID, required this.sender, required this.ACCNO, required this.typeTransaction, required this.amount, required this.icon, required this.typeTXN, required this.riskScore, required this.receiver, required this.riskColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Text(time, style: TextStyle(color: Colors.black, fontSize: 18),),
            Text(Date, style: TextStyle(color: Colors.grey, fontSize: 15),)
          ],
        ),
        Text(txnID, style: TextStyle(color: Colors.blue, fontSize: 18),),
        Column(
          children: [
            Text(sender, style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),),
            Text(ACCNO, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w300, fontSize: 15),),
          ],
        ),
        Column(
          children: [
            Text(receiver, style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),),
            Text(typeTransaction, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w300, fontSize: 15),),
          ],
        ),
        Text(amount, style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey,),
            Text(typeTXN, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w300, fontSize: 15),),

          ],
        ),
        Text(riskScore, style: TextStyle(color: riskColor, fontSize: 15, fontWeight: FontWeight.w300),)
      ],
    );
  }
}
