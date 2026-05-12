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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PRECISION BUSINESS NETWORK',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      _buildTierBadge(),
                    ],
                  ),
                  const Spacer(),
                  _buildChip(),
                  const SizedBox(height: 14),
                  Text(
                    widget.card.cardNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      fontFamily: 'Monospace',
                    ),
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
                              (widget.card.memberName ?? 'MEMBER').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.card.businessName ?? "PBN Member"} • ${widget.card.chapterName ?? "Network"}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(TablerIcons.access_point, color: Colors.white38, size: 24),
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
        Positioned(
          right: -50,
          top: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.04),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Opacity(
          opacity: 0.1,
          child: Center(
            child: Icon(TablerIcons.square_rotated, size: 400, color: Colors.white.withValues(alpha: 0.3)),
          ),
        ),
      ],
    );
  }

  Widget _buildTierBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        widget.card.tier.toUpperCase(),
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
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
