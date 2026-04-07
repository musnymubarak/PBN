import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'dart:async';
import 'dart:ui';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  Timer? _bgTimer;
  Timer? _pageTimer;
  int _currentPage = 0;
  int _bgImageIndex = 0;

  // -- ULTRA-HD CRYSTAL CLEAR IMAGE ROTATION --
  final List<String> _bgImages = [
    'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80&w=1200', // Modern Skyscraper
    'https://images.unsplash.com/photo-1542744173-8e7e53415bb0?auto=format&fit=crop&q=80&w=1200', // Professional Meeting
    'https://images.unsplash.com/photo-1504384308090-c894fd31f16c?auto=format&fit=crop&q=80&w=1200', // Tech Workspace
    'https://images.unsplash.com/photo-1557804506-669a67965ba0?auto=format&fit=crop&q=80&w=1200', // Network Networking
    'https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&q=80&w=1200', // Modern Collaboration
    'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&q=80&w=1200', // Shared Office
  ];

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'GLOBAL BUSINESS\nNETWORK',
      'subtitle': 'Connect with elite professionals and scale your business effortlessly across the globe.',
      'icon': TablerIcons.world_up,
      'color': const Color(0xFF3B82F6),
    },
    {
      'title': 'TRUSTED\nREFERRALS',
      'subtitle': 'Share quality business referrals with a trusted community and grow together.',
      'icon': TablerIcons.users_group,
      'color': const Color(0xFF10B981),
    },
    {
      'title': 'ELITE\nREWARDS',
      'subtitle': 'Unlock exclusive business perks, awards, and points as you thrive in our ecosystem.',
      'icon': TablerIcons.award,
      'color': const Color(0xFFF59E0B),
    },
  ];

  @override
  void initState() {
    super.initState();
    // Continuous Background Animation Loop (Every 5s)
    _bgTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() => _bgImageIndex = (_bgImageIndex + 1) % _bgImages.length);
      }
    });

    // Main Content Auto-Play (Every 7s)
    _pageTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (mounted && _currentPage < _onboardingData.length - 1) {
        _pageController.nextPage(duration: const Duration(milliseconds: 1000), curve: Curves.easeInOutCubic);
      }
    });
  }

  @override
  void dispose() {
    _bgTimer?.cancel();
    _pageTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Dynamic Background Image with Smooth Cross-Fade (CONTINUOUS)
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 2000), // Longer, cinematic cross-fade
              child: SizedBox.expand(
                key: ValueKey(_bgImages[_bgImageIndex]),
                child: Image.network(
                  _bgImages[_bgImageIndex],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF0F172A)),
                ),
              ),
            ),
          ),
          
          // Heavy Bottom Scrim for Readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.95),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          // Page Content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (value) => setState(() => _currentPage = value),
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              final item = _onboardingData[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 200), // Pushes content to bottom
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: item['color'].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: item['color'].withOpacity(0.3)),
                      ),
                      child: Icon(item['icon'], color: item['color'], size: 30),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      item['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item['subtitle'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 15,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Bottom Navigation & Actions
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 4,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: const Text('GET STARTED', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: 'Already a member? ', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                          const TextSpan(text: 'Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
