import 'package:flutter/material.dart';
import 'package:pbn/core/constants/app_colors.dart';

class AnimatedPbnLogo extends StatefulWidget {
  final double size;
  const AnimatedPbnLogo({super.key, this.size = 180});

  @override
  State<AnimatedPbnLogo> createState() => _AnimatedPbnLogoState();
}

class _AnimatedPbnLogoState extends State<AnimatedPbnLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Outer components P and N
  late Animation<double> _pOpacity;
  late Animation<double> _nOpacity;
  late Animation<Offset> _pSlide;
  late Animation<Offset> _nSlide;
  
  // Middle component B
  late Animation<double> _bScale;
  late Animation<double> _bGlow;
  late Animation<double> _bOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 1. P and N Fade in (0.0 to 0.4)
    _pOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    _nOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    // 2. B Scales and Glows in the middle (0.4 to 0.8)
    _bScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8, curve: Curves.elasticOut)),
    );
    _bOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.6, curve: Curves.easeIn)),
    );
    _bGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.9, curve: Curves.easeInOut)),
    );

    // 3. P and N slide together to close the gap (0.7 to 1.0)
    _pSlide = Tween<Offset>(begin: const Offset(-0.3, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0, curve: Curves.easeInOutBack)),
    );
    _nSlide = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0, curve: Curves.easeInOutBack)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double fontSize = 72;
    const TextStyle letterStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      fontFamily: 'Montserrat', // Falling back to system sans-serif if not found
      letterSpacing: -2,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A), // Matches the dark container in the user image
            borderRadius: BorderRadius.circular(widget.size * 0.15),
            boxShadow: [
              // Subtle glow for the B
              BoxShadow(
                color: AppColors.accent.withOpacity(0.3 * _bGlow.value),
                blurRadius: 30 * _bGlow.value,
                spreadRadius: 2 * _bGlow.value,
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // P
                Transform.translate(
                  offset: _pSlide.value * 80,
                  child: Opacity(
                    opacity: _pOpacity.value,
                    child: const Text('P', style: letterStyle),
                  ),
                ),
                
                // B (Center)
                SizedBox(
                  width: fontSize * 0.7, // Width of B
                  child: Center(
                    child: Transform.scale(
                      scale: _bScale.value,
                      child: Opacity(
                        opacity: _bOpacity.value,
                        child: Text(
                          'B', 
                          style: letterStyle.copyWith(color: AppColors.accent)
                        ),
                      ),
                    ),
                  ),
                ),

                // N
                Transform.translate(
                  offset: _nSlide.value * 80,
                  child: Opacity(
                    opacity: _nOpacity.value,
                    child: const Text('N', style: letterStyle),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
