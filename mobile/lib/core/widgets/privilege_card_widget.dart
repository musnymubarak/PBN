import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/models/reward.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

class PrivilegeCardWidget extends StatefulWidget {
  final PrivilegeCard card;
  const PrivilegeCardWidget({super.key, required this.card});

  @override
  State<PrivilegeCardWidget> createState() => _PrivilegeCardWidgetState();
}

class _PrivilegeCardWidgetState extends State<PrivilegeCardWidget> with SingleTickerProviderStateMixin {
  bool _isFlipped = false;
  bool _showHint = true;

  @override
  void initState() {
    super.initState();
    // Hide hint after 3 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  void _toggleFlip() {
    setState(() {
      _isFlipped = !_isFlipped;
      _showHint = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.586,
          child: GestureDetector(
            onTap: _toggleFlip,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _isFlipped ? pi : 0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutBack,
              builder: (context, angle, _) {
                final isFront = angle < pi / 2;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateY(angle),
                  child: isFront 
                    ? _buildFront() 
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: _buildBack(),
                      ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedOpacity(
          opacity: _showHint ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(TablerIcons.rotate_3d, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                'Tap card to flip',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFront() {
    return Container(
      decoration: _cardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            _buildBackgroundPattern(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          children: [
                            const TextSpan(text: 'Prime '),
                            TextSpan(
                              text: 'Business',
                              style: TextStyle(color: Colors.amber.shade400),
                            ),
                            const TextSpan(text: ' Network'),
                          ],
                        ),
                      ),
                      _buildChip(),
                    ],
                  ),
                  const Spacer(),
                  // Real Card Number
                  Row(
                    children: [
                      Text(
                        widget.card.cardNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          fontFamily: 'Monospace',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (widget.card.tier == 'charter' ? 'CHARTER MEMBER' : 'PREMIUM MEMBER').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.card.memberName ?? 'Musni',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildTierBadge(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: _cardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            _buildBackgroundPattern(),
            Column(
              children: [
                const SizedBox(height: 24),
                // Magnetic Strip
                Container(
                  height: 40,
                  width: double.infinity,
                  color: Colors.black,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('MEMBER SINCE', widget.card.issuedAt != null ? DateFormat('MMM yyyy').format(widget.card.issuedAt!) : '—'),
                              _buildInfoRow('CHAPTER', widget.card.chapterName ?? 'Global'),
                              _buildInfoRow('BUSINESS', widget.card.businessName ?? '—'),
                              _buildInfoRow('INDUSTRY', widget.card.industryName ?? '—'),
                              const Spacer(),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('VERSION', style: TextStyle(color: Colors.white38, fontSize: 7, fontWeight: FontWeight.w800)),
                                      Text('v${widget.card.cardVersion}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const VerticalDivider(color: Colors.white10, indent: 10, endIndent: 10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.card.qrCodeData != null)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: QrImageView(
                                    data: widget.card.qrCodeData!,
                                    version: QrVersions.auto,
                                    size: 70.0,
                                    gapless: false,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              const Text(
                                'primebusiness.network',
                                style: TextStyle(color: Colors.white24, fontSize: 7, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 7, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          Text(value, 
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 30,
          offset: const Offset(0, 15),
        ),
      ],
    );
  }

  Widget _buildBackgroundPattern() {
    return Stack(
      children: [
        // Glow behind chip (top-right)
        Positioned(
          right: -40,
          top: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Subtle Logo watermark
        Opacity(
          opacity: 0.05,
          child: Center(
            child: Icon(TablerIcons.square_rotated, size: 400, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildTierBadge() {
    String label = widget.card.tier.toUpperCase();
    if (label == 'CHARTER') label = 'FOUNDING';
    if (label == 'STANDARD' || label == 'NONE') label = 'MEMBER';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade400,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildChip() {
    return Container(
      width: 44,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade200, Colors.amber.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          Center(child: Icon(TablerIcons.border_all, color: Colors.black.withValues(alpha: 0.2), size: 20)),
        ],
      ),
    );
  }
}
