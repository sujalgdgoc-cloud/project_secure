import 'package:flutter/material.dart';

class AlertInfo extends StatefulWidget {
  const AlertInfo({super.key});

  @override
  State<AlertInfo> createState() => _AlertInfoState();
}

class _AlertInfoState extends State<AlertInfo> {
  Color bgColor = Colors.white70;
  @override
  //alert: iss wale page pr block wise kaam kiya hai koi custom widget nhi have but sarre returned value ko comment de diya to easily finding and editing the value
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Column(
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(onPressed: (){
                      Navigator.pop(context);
                    }, icon: Icon(Icons.arrow_back_ios_new, color: Colors.blue,)),
                    SizedBox(width: 100,),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 50.0,
                            top: 15,
                          ),
                          child: Text(
                            'TXN-982341',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ), //ye change krlena :)
                        ),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 5,
                              backgroundColor: Colors.greenAccent,
                            ),
                            Text('Transaction Analysis Detail'),
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
                    SizedBox(width: 100,),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.notifications_active_outlined),
                    ),
                    SizedBox(width: 30,),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.settings_outlined),
                    ),
                    SizedBox(width: 100,),
                    VerticalDivider(width: 0.2, color: Color(0xFFcacfd6)),
                    SizedBox(width: 50,),
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        color: Colors.white,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(21),
                          ),
                          height: MediaQuery.of(context).size.height * 0.4,
                          width: MediaQuery.of(context).size.width * 0.2,
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Core Transaction',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                'Amount',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '₹85,000.00', //put the returned amount value here
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 20,
                                ),
                              ),
                              Divider(color: Colors.grey, indent: 20, endIndent: 20),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Type',
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ),
                              Text(
                                'IMPS/External Transfer',
                                style: TextStyle(color: Colors.black, fontSize: 18),
                              ),

                              // put the returned type here
                              Text(
                                'Device Fingerprint',
                                style: TextStyle(color: Colors.grey, fontSize: 18),
                              ),

                              Text(
                                'DV-992-AXL-01',
                                style: TextStyle(color: Colors.black, fontSize: 18),
                              ),

                              // put the actual fingerprint there
                              Text(
                                'Network Identity',
                                style: TextStyle(color: Colors.grey, fontSize: 15),
                              ),

                              Text(
                                '192.168.145',
                                style: TextStyle(color: Colors.black, fontSize: 19),
                              ),

                              //put the actual network identity here
                              Text(
                                'Mumbai, MH',
                                style: TextStyle(color: Colors.grey, fontSize: 15),
                              ),

                              //put the actual location here
                            ],
                          ),
                        ),
                      ),
                    ), //container for core transaction
                    Card(
                      elevation: 4,
                      color: Colors.white,
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.3,
                        width: MediaQuery.of(context).size.width * 0.2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(21),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Entities',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.orangeAccent,
                                  radius: 15,
                                ),
                                SizedBox(width: 10),
                                Column(
                                  children: [
                                    Text(
                                      'Neil Verma', //put the real name
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          'Sender',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          '•',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          'A/C',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          '...8821',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 15,
                                          ),
                                        ),
                                        //account number goes here
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 15),
                            Icon(Icons.arrow_downward_outlined, color: Colors.black),
                            SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(backgroundColor: Colors.red, radius: 15),
                                SizedBox(width: 10),
                                Column(
                                  children: [
                                    Text(
                                      'Neil Verma',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    //put the real name
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          'Sender',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          '•',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          'A/C',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          '...8821',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 15,
                                          ),
                                        ),
                                        //account number goes here
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.2,
                        width: MediaQuery.of(context).size.width * 0.2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(21),
                          child: Image.network(
                            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTwArKOEKwNBTPJmVjHIPLhkCGoF0UVurq2uA&s',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ), // image for neural networking graph
                  ],
                ),
                Card(
                  elevation: 4,
                  color: Colors.white,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    width: MediaQuery.of(context).size.width * 0.4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 50),
                        // is container me graph add hoga
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.3,
                            width: MediaQuery.of(context).size.width * 0.25,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(21),
                              border: Border.all()
                            ),
                            child: Center(child: Text('To apply Bar chart')),
                          ),
                        ),
                        SizedBox(height: 70),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Confidence',
                                  style: TextStyle(color: Colors.black, fontSize: 20),
                                ),
                                Text(
                                  '94.2%',
                                  style: TextStyle(color: Colors.blue, fontSize: 20),
                                ),
                                //put confidence here :)
                              ],
                            ),
                            VerticalDivider(
                              color: Colors.grey,
                              endIndent: 10,
                              indent: 10,
                            ),
                            Column(
                              children: [
                                Text(
                                  'Processing',
                                  style: TextStyle(color: Colors.black, fontSize: 20),
                                ),
                                Text(
                                  '12ms',
                                  style: TextStyle(color: Colors.blue, fontSize: 20),
                                ),
                                //put real latency here
                              ],
                            ),
                            VerticalDivider(
                              color: Colors.grey,
                              endIndent: 10,
                              indent: 10,
                            ),
                            Column(
                              children: [
                                Text(
                                  'Data points',
                                  style: TextStyle(color: Colors.black, fontSize: 20),
                                ),
                                Text(
                                  '1,402',
                                  style: TextStyle(color: Colors.blue, fontSize: 20),
                                ),
                                //put real datapoints here
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        color: Colors.white,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3FF),
                            borderRadius: BorderRadius.circular(21),
                          ),
                          height: MediaQuery.of(context).size.height * 0.55,
                          width: MediaQuery.of(context).size.width * 0.3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              const Row(
                                children: [
                                  Icon(Icons.psychology, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    "AI Reasoning",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [

                                      Row(
                                        children: const [
                                          Icon(Icons.link_off, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text(
                                            "Rapid Transfer Chain",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      const Text(
                                        "Funds moved across multiple linked accounts within a short time window, indicating possible layering activity.",
                                      ),

                                      const Divider(height: 24),

                                      Row(
                                        children: const [
                                          Icon(Icons.person_remove, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text(
                                            "Flagged Beneficiary",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      const Text(
                                        "Destination account has historical associations with previously reviewed suspicious transactions.",
                                      ),

                                      const Divider(height: 24),

                                      Row(
                                        children: const [
                                          Icon(Icons.timer_sharp, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text(
                                            "Abnormal Timing",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      const Text(
                                        "Transaction occurred outside the account holder's normal activity hours and deviates from established behaviour patterns.",
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),//yaha ai use kra tha as text acche nhi lgrhe the
                    ),
                    Card(
                      elevation: 4,
                      color: Colors.white,
                      child: Container(
                        height: MediaQuery.of(context).size.height*0.2,
                        width:  MediaQuery.of(context).size.width*0.3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(21),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Investigative Log', style: TextStyle(
                                color: Colors.blue, fontWeight: FontWeight.bold , fontSize: 20
                              ),),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('14:22', style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w300),),
                                SizedBox(width: 8,),
                                Text('Alert triggered by real time engine',style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w300),)
                              ],
                            ),
                            SizedBox(height: 8,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('14:23', style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w300),),
                                SizedBox(width: 8,),
                                Text('Cross-entity graph analyzed(12 nodes)',style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w300),)
                              ],
                            ),
                            SizedBox(height: 5,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('14:25', style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w300),),
                                SizedBox(width: 8,),
                                Text('Case assigned to high-priority queue',style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w300),)
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
            Card(
              elevation: 4,
              color: Colors.white,
              child: Container(
                decoration: BoxDecoration(
                ),
                height: MediaQuery.of(context).size.height * 0.12,
                width: MediaQuery.of(context).size.width,
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: SizedBox(
                          height: 55,
                          child: FilledButton.icon(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            icon: const Icon(Icons.not_interested_outlined),
                            label: const Text('Freeze Account'),
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: SizedBox(
                          height: 55,
                          child: FilledButton.icon(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              shape: RoundedSuperellipseBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            icon: const Icon(Icons.pause),
                            label: const Text('Hold Transaction'),
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: SizedBox(
                          height: 55,
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              shape: RoundedSuperellipseBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            icon: const Icon(
                              Icons.noise_aware,
                              color: Colors.black,
                            ),
                            label: const Text(
                              'Escalate',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: SizedBox(
                          height: 55,
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              shape: RoundedSuperellipseBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            icon: const Icon(
                              Icons.check,
                              color: Colors.black,
                            ),
                            label: const Text(
                              'Mark as safe',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )// yaha pr ai use kra tha filled button ase hi acche nhi lg rhe the
          ],
        ),
      ),
    );
  }
}
