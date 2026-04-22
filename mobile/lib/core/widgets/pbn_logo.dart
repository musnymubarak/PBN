import 'package:flutter/material.dart';
import 'package:pbn/core/constants/app_colors.dart';

class PbnLogo extends StatelessWidget {
  final double size;
  const PbnLogo({super.key, this.size = 110});

  @override
  Widget build(BuildContext context) {
    final double fontSize = size * 0.45;
    final TextStyle letterStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      fontFamily: 'Montserrat',
      letterSpacing: -2,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('P', style: letterStyle),
            Text(
              'B',
              style: letterStyle.copyWith(color: AppColors.accent),
            ),
            Text('N', style: letterStyle),
          ],
        ),
      ),
    );
  }
}
