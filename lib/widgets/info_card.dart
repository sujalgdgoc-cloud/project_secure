import 'package:flutter/material.dart';

class Feed_Card extends StatelessWidget {
  const Feed_Card({
    super.key,
    required this.time,
    required this.ID,
    required this.snd_name,
    required this.Amount,
    required this.rsk_type,
    required this.rsk_color,
  });

  final String time;
  final String ID;
  final String snd_name;
  final String Amount;
  final String rsk_type;
  final Color rsk_color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(time), //time
        SizedBox(width: 10),
        Text(ID), //ID
        SizedBox(width: 10),
        Text(snd_name), //sender name
        SizedBox(width: 10),
        Text(Amount, style: TextStyle(fontWeight: FontWeight.bold),), //Amount,
        SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: rsk_color,
          ),
          height: MediaQuery.of(context).size.height * 0.05,
          width: MediaQuery.of(context).size.width * 0.05, //isko matt chedna :)

          child: Center(child: Text(rsk_type, style: TextStyle(fontSize: 12,color: Colors.black),)),
        ),
        SizedBox(width: 10),
        IconButton(onPressed: (){}, icon: Icon(Icons.visibility_outlined, color: Colors.blueAccent),)
      ],
    );
  }
}
