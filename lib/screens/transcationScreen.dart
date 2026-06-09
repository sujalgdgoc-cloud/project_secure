import 'package:flutter/material.dart';

import '../widgets/transcation_info_card.dart';

class TranscationScreen extends StatefulWidget {
  const TranscationScreen({super.key});

  @override
  State<TranscationScreen> createState() => _TranscationScreenState();
}

class _TranscationScreenState extends State<TranscationScreen> {
  @override
  Widget build(BuildContext context) {
    Color h1 = Colors.black;
    Color h2 = Colors.black45;
    Color text = Colors.black;
    Color bgColor = Colors.white70;
    Color buttonColor = Colors.blue;
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Transaction Ledger',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 21,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.05,
                          width: MediaQuery.of(context).size.width * 0.06,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade200,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                '1,240',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              Text(
                                'Total',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ), //main heading text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.greenAccent,
                          radius: 7,
                        ),
                      ),
                      SizedBox(width: 7),
                      Text(
                        "Real-time transaction syncing active",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w300,
                          fontSize: 17,
                        ), // sub heading text
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(width: 600), //big ass size box
              OutlinedButton.icon(
                onPressed: () {},
                label: Text('Save View'),
                icon: Icon(Icons.save_alt),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.grey,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FilledButton.icon(
                  onPressed: () {},
                  label: Text('Export CSV'),
                  icon: Icon(Icons.arrow_drop_up_outlined),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ), //top row of the page
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 4,
              color: Colors.white,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.1,
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Data range',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w300,
                            fontSize: 15,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border.all(
                              color: Colors.grey,
                            ),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: DropdownButton(
                            underline: const SizedBox(),
                            icon: Icon(Icons.arrow_drop_down),
                            items: [
                              DropdownMenuItem(
                                child: Text(
                                  'Last 24 Hours',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                            onChanged: (value) {},
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Risk Level',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w300,
                            fontSize: 15,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border.all(
                              color: Colors.grey,
                            ),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: DropdownButton(
                            underline: const SizedBox(),
                            icon: Icon(Icons.arrow_drop_down),
                            items: [
                              DropdownMenuItem(
                                child: Text(
                                  'All Levels',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                            onChanged: (value) {},
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Channel',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w300,
                            fontSize: 15,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50, // background color
                            border: Border.all(
                              color: Colors.grey,
                            ),
                            borderRadius: BorderRadius.circular(11), // circular corners
                          ),
                          child: DropdownButton(
                            underline: const SizedBox(),
                            icon: Icon(Icons.arrow_drop_down),
                            items: [
                              DropdownMenuItem(
                                child: Text(
                                  'All Channels',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                            onChanged: (value) {},
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Status',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w300,
                            fontSize: 15,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50, // background color
                            border: Border.all(
                              color: Colors.grey,
                            ),
                            borderRadius: BorderRadius.circular(11), // circular corners
                          ),
                          child: DropdownButton(
                            underline: const SizedBox(),
                            icon: Icon(Icons.arrow_drop_down),
                            items: [
                              DropdownMenuItem(
                                child: Text(
                                  'All Status',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                            onChanged: (value) {},
                          ),
                        ),
                      ],
                    ), //column of different category in 2nd row
                    SizedBox(width: 80,),
                    GestureDetector(
                      onTap: (){},
                      child: Container(

                        height: MediaQuery.of(context).size.height*0.07,
                        width: MediaQuery.of(context).size.width*0.06,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          color: Color(0xFFdbe2fe)
                        ),
                        child: Center(child: Text('RESET',style: TextStyle(color: Colors.grey),))
                      ),
                    ), //button no 1

                    GestureDetector(
                      onTap: (){},
                      child: Container(

                          height: MediaQuery.of(context).size.height*0.07,
                          width: MediaQuery.of(context).size.width*0.06,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(11),
                              color: Color(0xFF121b2c)
                          ),
                          child: Center(child: Text('Apply Filter',style: TextStyle(color: Colors.white),))
                      ),
                    ), //button no 1
                  ],
                ),
              ),
            ), //second row of the page
          ),
          SizedBox(height: 10,),
          Card(
            elevation: 4,
            color: Colors.white,
            child: Container(
              height: MediaQuery.of(context).size.height*0.7,
              width: MediaQuery.of(context).size.width*0.8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),

              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('Time', style: TextStyle(color: Colors.grey, fontSize: 18),),
                        Text('Transaction ID', style: TextStyle(color: Colors.grey,fontSize: 18),),
                        Text('Sender', style: TextStyle(color: Colors.grey,fontSize: 18),),
                        Text('Receiver', style: TextStyle(color: Colors.grey,fontSize: 18),),
                        Text('Amount', style: TextStyle(color: Colors.grey,fontSize: 18),),
                        Text('Channel', style: TextStyle(color: Colors.grey,fontSize: 18),),
                        Text('Risk Score', style: TextStyle(color: Colors.grey,fontSize: 18),),

                      ],
                    ),
                  ),
                  TransactionInfoCard(time: '10:45:22 AM', Date:'Oct 24, 2024', txnID: 'TXN-88294101', sender: 'Rahul S.sharma', ACCNO: 'XXXX-XXX917', typeTransaction: 'VPA:buy@crytopay', amount: '\$2000', icon: Icons.cell_tower, typeTXN: 'UPI', riskScore: '92', receiver: 'Global Crypto EXCh', riskColor: Colors.red,),
                  Divider(color: Colors.grey,),
                  TransactionInfoCard(time: '10:45:22 AM', Date:'Oct 24, 2024', txnID: 'TXN-88294101', sender: 'Rahul S.sharma', ACCNO: 'XXXX-XXX917', typeTransaction: 'VPA:buy@crytopay', amount: '\$2000', icon: Icons.cell_tower, typeTXN: 'UPI', riskScore: '92', receiver: 'Global Crypto EXCh', riskColor: Colors.red,),
                  Divider(color: Colors.grey,),
                  TransactionInfoCard(time: '10:45:22 AM', Date:'Oct 24, 2024', txnID: 'TXN-88294101', sender: 'Rahul S.sharma', ACCNO: 'XXXX-XXX917', typeTransaction: 'VPA:buy@crytopay', amount: '\$2000', icon: Icons.cell_tower, typeTXN: 'UPI', riskScore: '92', receiver: 'Global Crypto EXCh', riskColor: Colors.red,),
                  Divider(color: Colors.grey,),
                  TransactionInfoCard(time: '10:45:22 AM', Date:'Oct 24, 2024', txnID: 'TXN-88294101', sender: 'Rahul S.sharma', ACCNO: 'XXXX-XXX917', typeTransaction: 'VPA:buy@crytopay', amount: '\$2000', icon: Icons.cell_tower, typeTXN: 'UPI', riskScore: '92', receiver: 'Global Crypto EXCh', riskColor: Colors.red,),
                  Divider(color: Colors.grey,),
                  TransactionInfoCard(time: '10:45:22 AM', Date:'Oct 24, 2024', txnID: 'TXN-88294101', sender: 'Rahul S.sharma', ACCNO: 'XXXX-XXX917', typeTransaction: 'VPA:buy@crytopay', amount: '\$2000', icon: Icons.cell_tower, typeTXN: 'UPI', riskScore: '92', receiver: 'Global Crypto EXCh', riskColor: Colors.red,),
                  Divider(color: Colors.grey,),
                  TransactionInfoCard(time: '10:45:22 AM', Date:'Oct 24, 2024', txnID: 'TXN-88294101', sender: 'Rahul S.sharma', ACCNO: 'XXXX-XXX917', typeTransaction: 'VPA:buy@crytopay', amount: '\$2000', icon: Icons.cell_tower, typeTXN: 'UPI', riskScore: '92', receiver: 'Global Crypto EXCh', riskColor: Colors.red,),
                  Divider(color: Colors.grey,),
                  TransactionInfoCard(time: '10:45:22 AM', Date:'Oct 24, 2024', txnID: 'TXN-88294101', sender: 'Rahul S.sharma', ACCNO: 'XXXX-XXX917', typeTransaction: 'VPA:buy@crytopay', amount: '\$2000', icon: Icons.cell_tower, typeTXN: 'UPI', riskScore: '92', receiver: 'Global Crypto EXCh', riskColor: Colors.red,),
                  //pagination ap apke hwale
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
