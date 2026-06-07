import 'package:flutter/material.dart';

class AlertInfo extends StatefulWidget {
  const AlertInfo({super.key});

  @override
  State<AlertInfo> createState() => _AlertInfoState();
}

class _AlertInfoState extends State<AlertInfo> {
  @override
  //alert: iss wale page pr block wise kaam kiya hai koi custom widget nhi have but sarre returned value ko comment de diya to easily finding and editing the value
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(),
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
              ), //container for core transaction
              Container(

                height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width * 0.2,
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Entities',
                        style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.orangeAccent,
                          radius: 15,
                        ),
                        SizedBox(width: 10,),
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
                                Text('Sender', style: TextStyle(color: Colors.grey, fontSize: 15),),
                                Text('•', style: TextStyle(color: Colors.grey, fontSize: 15),),
                                Text('A/C', style: TextStyle(color: Colors.grey, fontSize: 15),),
                                Text('...8821', style: TextStyle(color: Colors.grey, fontSize: 15),) //account number goes here
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Icon(
                      Icons.arrow_downward_outlined,
                      color: Colors.black,
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.red,
                          radius: 15,

                        ),
                        SizedBox(width: 10,),
                        Column(
                          children: [
                            Text('Neil Verma', style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),),//put the real name
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text('Sender', style: TextStyle(color: Colors.grey, fontSize: 15),),
                                Text('•', style: TextStyle(color: Colors.grey, fontSize: 15),),
                                Text('A/C', style: TextStyle(color: Colors.grey, fontSize: 15),),
                                Text('...8821', style: TextStyle(color: Colors.grey, fontSize: 15),) //account number goes here
                              ],
                            )
                          ],
                        ),
                        
                      ],
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: MediaQuery.of(context).size.height*0.2,
                  width: MediaQuery.of(context).size.width*0.2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all()
                  ),
                  child: ClipRRect(

                    borderRadius: BorderRadius.circular(21),
                      child: Image.network('https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTwArKOEKwNBTPJmVjHIPLhkCGoF0UVurq2uA&s', fit: BoxFit.cover,)),
                ),
              )// image for neural networking graph
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Container(
            height: MediaQuery.of(context).size.height*0.7,
            width: MediaQuery.of(context).size.width*0.4,
            decoration: BoxDecoration(
              border: Border.all(),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Column(
              children: [
                Center(child: Text('To apply Bar chart')),
              ],
            ),
          )
        ],
      ),
    );
  }
}
