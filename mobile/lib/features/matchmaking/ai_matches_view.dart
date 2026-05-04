import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/constants/api_config.dart';
import 'package:pbn/core/widgets/cached_avatar.dart';
import 'package:pbn/core/services/matchmaking_service.dart';
import 'package:pbn/models/matchmaking.dart';

class AiMatchesView extends StatefulWidget {
  const AiMatchesView({super.key});

  @override
  State<AiMatchesView> createState() => _AiMatchesViewState();
}

class _AiMatchesViewState extends State<AiMatchesView> {
  final _service = MatchmakingService();
  List<MatchSuggestion> _matches = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() { _loading = true; _error = null; });
    try {
      final matches = await _service.getSuggestions();
      if (mounted) setState(() { _matches = matches; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load matches'; _loading = false; });
    }
  }

  Future<void> _computeMatches() async {
    setState(() { _loading = true; });
    try {
      await _service.computeMatches();
      await _loadMatches();
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to recompute matches'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _matches.isEmpty) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    
    if (_error != null && _matches.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(TablerIcons.sparkles, size: 48, color: Colors.grey),
        const SizedBox(height: 16),
        Text(_error!, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _loadMatches, child: const Text('RETRY')),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOP RECOMMENDATIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.5)),
              if (!_loading)
                IconButton(
                  onPressed: _computeMatches, 
                  icon: const Icon(TablerIcons.refresh, size: 16, color: AppColors.primary),
                  tooltip: 'Recompute Matches',
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_matches.isEmpty)
            _buildEmptyState()
          else
            ..._matches.map((m) => _buildMatchCard(m)),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(TablerIcons.sparkles, color: AppColors.accent, size: 32),
          const SizedBox(height: 16),
          const Text('AI Business Matchmaking', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'We analyze the network to find members who can generate the most business value with you.',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(children: [
        Icon(TablerIcons.users_group, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 24),
        const Text('No matches yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 8),
        Text('Complete your business profile or invite more members to see recommendations.', 
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        const SizedBox(height: 32),
        ElevatedButton(onPressed: _computeMatches, child: const Text('GENERATE MATCHES')),
      ]),
    );
  }

  Widget _buildMatchCard(MatchSuggestion match) {
    final percentage = (match.score * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CachedAvatar(
                  imageUrl: match.matchedUserPhoto,
                  initials: (match.matchedUserName ?? '?')[0].toUpperCase(),
                  size: 50,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(match.matchedUserName ?? 'Unknown Member', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.text)),
                      const SizedBox(height: 2),
                      Text(match.matchedUserIndustry ?? 'Member', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary.withOpacity(0.7))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('$percentage% Match', style: const TextStyle(color: Color(0xFFB45309), fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          if (match.explanation != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey.shade50,
              child: Text(match.explanation!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _showMatchDetails(match),
                    child: const Text('VIEW STRATEGY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {}, // TODO: Connect logic
                    style: ElevatedButton.styleFrom(elevation: 0, padding: const EdgeInsets.symmetric(vertical: 10)),
                    child: const Text('CONNECT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  void _showMatchDetails(MatchSuggestion match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MatchDetailSheet(match: match, service: _service),
    );
  }
}

class _MatchDetailSheet extends StatefulWidget {
  final MatchSuggestion match;
  final MatchmakingService service;
  const _MatchDetailSheet({required this.match, required this.service});

  @override
  State<_MatchDetailSheet> createState() => _MatchDetailSheetState();
}

class _MatchDetailSheetState extends State<_MatchDetailSheet> {
  String? _strategy;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _strategy = widget.match.partnershipStrategy;
    if (_strategy == null) _loadStrategy();
  }

  Future<void> _loadStrategy() async {
    setState(() { _loading = true; });
    try {
      final strategy = await widget.service.getAiStrategy(widget.match.id);
      if (mounted) setState(() { _strategy = strategy; _loading = false; });
    } catch (e) {
      debugPrint("Error loading AI strategy: $e");
      if (mounted) setState(() { 
        _strategy = "Error loading strategy: $e"; 
        _loading = false; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          const Row(children: [
            Icon(TablerIcons.sparkles, color: AppColors.accent, size: 24),
            SizedBox(width: 12),
            Text('Partnership Strategy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.text)),
          ]),
          const SizedBox(height: 24),
          Text('HOW TO CREATE BUSINESS TOGETHER:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Text(
                    _strategy ?? 'No strategy generated yet.',
                    style: const TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w500, color: AppColors.text),
                  ),
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('GOT IT', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}
