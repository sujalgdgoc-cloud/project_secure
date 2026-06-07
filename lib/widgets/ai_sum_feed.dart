import 'package:flutter/material.dart';

class AiSumCard extends StatelessWidget {
  const AiSumCard({
    super.key,
    required this.box_color,
    required this.ctgy,
    required this.Score,
    required this.acc_no,
    required this.duration,
    required this.location,
    required this.summary,
  });

  final Color box_color;
  final String ctgy;
  final String Score;
  final String acc_no;
  final String duration;
  final String location;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 4,
        color: Colors.white,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.05,
          width: MediaQuery.of(context).size.width * 0.3,
          decoration: BoxDecoration(
            color: Colors.white70,
            borderRadius: BorderRadius.circular(21),
            border: Border(top: BorderSide(color: box_color, width: 3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(decoration: BoxDecoration(
                      color: box_color.withValues(alpha: 90),
                      borderRadius: BorderRadius.circular(11)
                    ),
                      height: 50,
                      width: 50,

                      child: Center(child: Text(ctgy)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 50,
                      width: 80,
                      decoration: BoxDecoration(
                        color: box_color.withValues(alpha: 80),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Text(Score), Text('Score')],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('ACC:'),
                      ),

                      Text(
                        acc_no,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 21,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(Icons.alarm_outlined),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(duration),
                      ),
                      Text('•'),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(location),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: Colors.black12,
                  ),
                  height: MediaQuery.of(context).size.height * 0.3,
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: Center(child: Text(summary)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FilledButton.icon(
                        onPressed: () {},
                        style: FilledButton.styleFrom(backgroundColor: Colors.lightBlueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                        label: Text('Review'),
                        icon:Icon( Icons.search),

                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FilledButton.icon(
                        onPressed: () {},
                        style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(11))),
                        label: Text('Freeze'),
                        icon:Icon( Icons.severe_cold),

                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        style: FilledButton.styleFrom(backgroundColor: Colors.white, shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(11))),
                        label: Text('Escalate', style: TextStyle(color: Colors.black),),
                        icon:Icon( Icons.noise_aware, color: Colors.black,),

                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        style: FilledButton.styleFrom(backgroundColor: Colors.white, shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(11))),
                        label: Text('Dismiss', style: TextStyle(color: Colors.black),),
                        icon:Icon( Icons.not_interested, color: Colors.black,),

                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
