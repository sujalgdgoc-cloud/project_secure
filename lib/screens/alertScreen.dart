import 'package:flutter/material.dart';
import 'package:project_secure/screens/alertinfoScreen.dart';
import 'package:project_secure/widgets/ai_sum_feed.dart';
import 'package:project_secure/widgets/realtimeAlertcard.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  @override
  Widget build(BuildContext context) {
    Color h1 = Colors.black;
    Color h2 = Colors.black45;
    Color text = Colors.black;
    Color bgColor = Colors.white70;
    Color buttonColor = Colors.blue;
    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Real-time Alert Center',
                        style: TextStyle(
                          color: text,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Monitoring active transaction patters',
                      style: TextStyle(
                        color: text,
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Color(0xFF011d35),
                    ),
                    onPressed: () {},
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.white),
        
                        Text(
                          'Live Refresh',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                //wase to yaha pr bhi custom card ki zarurt nhi thi but de diye
                RealTimeCard(
                  text: 'Critical Alerts',
                  number: '12',
                  icon: Icons.not_interested_outlined,
                  icon_color: Colors.red,
                ),
                RealTimeCard(
                  text: 'Active In- Progress',
                  number: '84',
                  icon: Icons.auto_graph,
                  icon_color: Colors.orangeAccent,
                ),
                RealTimeCard(
                  text: 'Escalated Priority',
                  number: '5',
                  icon: Icons.shield_moon_outlined,
                  icon_color: Colors.lightBlueAccent,
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Live Investigation Feed",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    //iska kud se kr lena mere ko smja nhi wase bhi puri value di nhi thi tune :)
                    DropdownButton(items: [
        
                    ], onChanged: null),
                    DropdownButton(items: [
        
                    ], onChanged: null)
                  ],
                )
              ],
            ),
            SizedBox(height: 10,),
            GridView(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.1),
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),

            children: [
              GestureDetector(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: ((context) => AlertInfo())));
                },
                  child: AiSumCard(box_color: Colors.red, ctgy: 'High', Score: '98', acc_no: '7293XXXX0373', duration: '2min ago', location: 'Mumbai IN', summary: 'losem zomen bursom horsesemne')),
              AiSumCard(box_color: Colors.blue, ctgy: 'Low', Score: '34', acc_no: '83782XXX9433', duration: '3min ago', location: 'Delhi IN', summary: 'losem zomen bursom horsesemne'),
              AiSumCard(box_color: Colors.orangeAccent, ctgy: 'Med', Score: '45', acc_no: '7663XXXX0274', duration: '2hrs ago', location: 'Lahore PK', summary: 'losem zomen bursom horsesemne'),
              AiSumCard(box_color: Colors.red, ctgy: 'High', Score: '98', acc_no: '1393XXXX4593', duration: '5hrs ago', location: 'Texas US', summary: 'losem zomen bursom horsesemne'),

            ],)
          ],
        ),
      ),
    );
  }
}
