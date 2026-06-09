import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:project_secure/screens/aiModelScreen.dart';
import 'package:project_secure/screens/alertScreen.dart';
import 'package:project_secure/screens/homepage.dart';
import 'package:project_secure/screens/transcationScreen.dart';
import 'package:project_secure/widgets/info_card.dart';

import '../widgets/alert_card.dart';
import '../widgets/custom_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Color h1 = Colors.black;
  Color h2 = Colors.black45;
  Color text = Colors.black;
  Color bgColor = Colors.white70;
  Color buttonColor = Colors.blue;
  int _currentIndex = 0;
  bool _extended = false;
  List<Widget> _pages = [
    Homepage(),
    AlertScreen(),
    TranscationScreen(),
    AiModelScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          NavigationRail(
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: MediaQuery.of(context).size.height*0.15,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //long ass image fetch
                        Image.network('data:image/png;base64,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', height: MediaQuery.of(context).size.height*0.05, width:  MediaQuery.of(context).size.width*0.05,),

                        Text('BANK OF INDIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white70),),
                      ],
                    ),
                    SizedBox(height: 10,),
                    Text('FraudWatch AI', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFd0e1f9)),),
                    Text('Instituational Security',style: TextStyle(fontWeight: FontWeight.w200, fontSize: 11, color: Color(0xFFd0e1f9)),)

                  ],
                ),
              ),
            ),
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined, color: Colors.white),
                label: Text("Dashboard", style: TextStyle(color: Colors.white)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.crisis_alert_sharp, color: Colors.white),
                label: Text("Alerts", style: TextStyle(color: Colors.white)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt, color: Colors.white),
                label: Text(
                  'Transactions',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.model_training_rounded, color: Colors.white),
                label: Text(
                  'AI Model',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
            selectedIndex: _currentIndex,
            onDestinationSelected: (value) {
              setState(() {
                _currentIndex = value;
                _extended = true;
              });
            },
            backgroundColor: Color(0xFF011d35),
            indicatorColor: Color(0xFF0074bd),
            extended: _extended,
          ),
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
    );
  }
}
