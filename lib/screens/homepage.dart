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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Column(
        children: [
          //custom appbar
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFcacfd6))),
              ),
              height: MediaQuery.of(context).size.height * 0.09,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 50.0,
                          top: 15,
                        ),
                        child: Text(
                          'Good Morning, Team BOI',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ), // ye change hogay ky according to date?
                      ),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 5,
                            backgroundColor: Colors.greenAccent,
                          ),
                          Text('System Active'),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: "Search for mule accounts",
                        labelStyle: TextStyle(color: Colors.black),
                        icon: Icon(Icons.search),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: Color(0xFFcacfd6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.notifications_active_outlined),
                  ),

                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.settings_outlined),
                  ),
                  VerticalDivider(width: 0.2, color: Color(0xFFcacfd6)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.black,
                        radius: 15,
                      ),
                      SizedBox(width: 10),

                      Text('Investigator Neil verma'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // custom card widget start from here :)
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 30,
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.25,
                  width: MediaQuery.of(context).size.width * 0.17,
                  child: CardWidget(
                    title: "Total Transactions",
                    subtitle: "1.2M",
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: Colors.blue,
                    headingColor: Colors.grey,
                    subTitleColor: Colors.black,
                    stonksIcon: Icons.trending_up,
                    stonksColor: Colors.green,
                    stonksString: '12%',
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.height * 0.25,
                  width: MediaQuery.of(context).size.width * 0.17,
                  child: CardWidget(
                    title: "High Risk Alerts",
                    subtitle: "142",
                    icon: Icons.warning_amber,
                    iconColor: Colors.red,
                    headingColor: Colors.grey,
                    subTitleColor: Colors.black,
                    stonksIcon: Icons.trending_up,
                    stonksColor: Colors.red,
                    stonksString: '5%',
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.height * 0.25,
                  width: MediaQuery.of(context).size.width * 0.17,
                  child: CardWidget(
                    title: "Mule Accounts",
                    subtitle: "48",
                    icon: Icons.no_accounts,
                    iconColor: Colors.deepOrangeAccent,
                    headingColor: Colors.grey,
                    subTitleColor: Colors.black,
                    stonksIcon: Icons.trending_down,
                    stonksColor: Colors.deepOrangeAccent,
                    stonksString: '2%',
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.height * 0.25,
                  width: MediaQuery.of(context).size.width * 0.17,
                  child: CardWidget(
                    title: "Under Review",
                    subtitle: "215",
                    icon: Icons.assignment,
                    iconColor: Colors.blue,
                    headingColor: Colors.grey,
                    subTitleColor: Colors.black,
                    stonksIcon: Icons.gpp_good,
                    stonksColor: Colors.grey,
                    stonksString: 'stable',
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: EdgeInsets.all(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Live transation feed start from here
              Container(
                width: MediaQuery.sizeOf(context).width * 0.45,
                height: MediaQuery.sizeOf(context).height * 0.6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: Color(0xFFcacfd6)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Live Transaction Feed',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 21,
                              color: Colors.black,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text('View All →'),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Color(0xFFcacfd6)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          'Time',
                          style: TextStyle(
                            fontWeight: FontWeight.w300,

                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Transaction ID',
                          style: TextStyle(
                            fontWeight: FontWeight.w300,

                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Sender',
                          style: TextStyle(
                            fontWeight: FontWeight.w300,

                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Amount',
                          style: TextStyle(
                            fontWeight: FontWeight.w300,

                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Risk',
                          style: TextStyle(
                            fontWeight: FontWeight.w300,

                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Action',
                          style: TextStyle(
                            fontWeight: FontWeight.w300,

                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    Divider(color:Color(0xFFcacfd6)),
                    //ye wale ka mene custom widget bana liya but koi fida nhi hua :)
                    Column(
                      children: [
                        Feed_Card(
                          time: '10:42:15 Am',
                          ID: 'Dummmy_ID',
                          snd_name: 'Neil',
                          Amount: '\$2000',
                          rsk_type: 'High Risk',
                          rsk_color: Colors.redAccent,
                        ),
                        Divider(color: Color(0xFFcacfd6)),
                        Feed_Card(
                          time: '10:42:15 Am',
                          ID: 'Dummmy_ID',
                          snd_name: 'Neil',
                          Amount: '\$200',
                          rsk_type: 'Low Risk',
                          rsk_color: Colors.blue,
                        ),
                        Divider(color: Color(0xFFcacfd6)),
                        Feed_Card(
                          time: '10:42:15 Am',
                          ID: 'Dummmy_ID',
                          snd_name: 'Neil',
                          Amount: '\$1400',
                          rsk_type: 'Medium Risk',
                          rsk_color: Colors.deepOrangeAccent,
                        ),
                        Divider(color: Color(0xFFcacfd6)),
                        Feed_Card(
                          time: '10:42:15 Am',
                          ID: 'Dummmy_ID',
                          snd_name: 'Neil',
                          Amount: '\$2000',
                          rsk_type: 'High Risk',
                          rsk_color: Colors.redAccent,
                        ),
                        Divider(color: Color(0xFFcacfd6)),
                        Feed_Card(
                          time: '10:42:15 Am',
                          ID: 'Dummmy_ID',
                          snd_name: 'Neil',
                          Amount: '\$2000',
                          rsk_type: 'High Risk',
                          rsk_color: Colors.redAccent,
                        ),
                        Divider(color: Color(0xFFcacfd6)),
                        Feed_Card(
                          time: '10:42:15 Am',
                          ID: 'Dummmy_ID',
                          snd_name: 'Neil',
                          Amount: '\$2000',
                          rsk_type: 'High Risk',
                          rsk_color: Colors.redAccent,
                        ),
                        Divider(color: Color(0xFFcacfd6)),
                      ], // Implementation of pagination - ye krna hai abhi video dekni hogi
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(21),
                      border: Border.all(color:Color(0xFFcacfd6)),
                    ),
                    height: MediaQuery.of(context).size.height * 0.3,
                    width:
                    MediaQuery.of(context).size.width *
                        0.2, // of graph
                    child: Center(child: Text('To apply graph')),
                  ),
                  SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(21),
                      border: Border.all(color: Color(0xFFcacfd6)),
                    ),
                    height: MediaQuery.of(context).size.height * 0.3,
                    width:
                    MediaQuery.of(context).size.width *
                        0.2, //of alerts
                    child: Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                            children: [Text('Recent Alerts')],
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  AlertCard(
                                    heading: 'high-risk mule pattern',
                                    description:
                                    'lusmesmen tansen ulamte skdbal skikdii ajdnela djadmdk',
                                    timeDuration: '2min ago',
                                    icon: Icons.gpp_bad,
                                    icon_color: Colors.redAccent,
                                  ),
                                  AlertCard(
                                    heading: 'high-risk mule pattern',
                                    description:
                                    'lusmesmen tansen ulamte skdbal skikdii ajdnela djadmdk',
                                    timeDuration: '2min ago',
                                    icon: Icons.gpp_bad,
                                    icon_color: Colors.redAccent,
                                  ),
                                  AlertCard(
                                    heading: 'high-risk mule pattern',
                                    description:
                                    'lusmesmen tansen ulamte skdbal skikdii ajdnela djadmdk',
                                    timeDuration: '2min ago',
                                    icon: Icons.gpp_bad,
                                    icon_color: Colors.redAccent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
