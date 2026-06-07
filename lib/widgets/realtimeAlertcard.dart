import 'package:flutter/material.dart';

class RealTimeCard extends StatelessWidget {
  const RealTimeCard({super.key, required this.text, required this.number, required this.icon, required this.icon_color});
  final String text;
  final String number;
  final IconData icon;
  final Color icon_color;
  @override
  Widget build(BuildContext context) {

    return Card(
      elevation: 4,
      color: Colors.white,
      child: Container(
        height: MediaQuery.of(context).size.height*0.15,
        width: MediaQuery.of(context).size.width*0.2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: icon_color.withValues(alpha: 90)
              ),
                child: Icon(icon, color: icon_color,)),
            SizedBox(width: 10,),
            Column(
              children: [
                SizedBox(height: 40,),
                Text(text),
                Text(number)
              ],
            )
          ],
        ),
      ),
    );
  }
}
