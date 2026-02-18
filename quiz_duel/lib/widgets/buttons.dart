import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final double radius;
  final double fontSize;
  final double width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = const Color(0xFF42A5F5),   // default color
    this.radius = 16,// default radius
    this.fontSize = 16,
    this.width = double.infinity,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        minimumSize: Size(width, height), // full width
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(color: Colors.white,fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
    );
  }
}