import 'dart:ui';
import 'package:flutter/material.dart';

class CardWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String subtitle;
  final Color headingColor;
  final Color subTitleColor;
  final IconData stonksIcon;
  final Color stonksColor;
  final String stonksString;

  const CardWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.iconColor,
    required this.headingColor,
    required this.subTitleColor, required this.stonksIcon, required this.stonksColor, required this.stonksString,

  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: iconColor),
                Row(children: [
                  Icon(stonksIcon, color: stonksColor,),
                  Text(stonksString, style: TextStyle(color: stonksColor),)
                ],)
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0),
            child: Text(
              title,
              style: TextStyle(color: headingColor, fontSize: 18),
            ),
          ),
          SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8),
            child: Text(
              subtitle,
              style: TextStyle(
                color: subTitleColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
