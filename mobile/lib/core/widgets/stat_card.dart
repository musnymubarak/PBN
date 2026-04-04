import 'package:flutter/material.dart';
import 'package:pbn/core/constants/app_colors.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final List<Color>? gradient;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final hasGradient = gradient != null && gradient!.length >= 2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: hasGradient
            ? LinearGradient(colors: gradient!, begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        color: hasGradient ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (hasGradient ? gradient!.first : Colors.black).withOpacity(hasGradient ? 0.25 : 0.04),
            blurRadius: hasGradient ? 16 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(hasGradient ? 0.2 : 0.0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: hasGradient ? Colors.white : color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: hasGradient ? Colors.white.withOpacity(0.8) : AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: hasGradient ? Colors.white : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
