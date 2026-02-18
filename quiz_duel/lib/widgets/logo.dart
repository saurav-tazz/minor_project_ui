import 'package:flutter/material.dart';


class Logo extends StatelessWidget {
  final double size;
  const Logo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow:[BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0,4),
          ),]
        ),
      child: Icon(
        Icons.flash_on,
        color: Colors.blueAccent,
        size: size* 0.5 ,
      ),

    );
  }
}
