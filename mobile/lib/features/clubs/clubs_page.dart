import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/club_provider.dart';
import 'package:pbn/models/horizontal_club.dart';
import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';

class ClubsPage extends StatefulWidget {
  const ClubsPage({super.key});

  @override
  State<ClubsPage> createState() => _ClubsPageState();
}

class _ClubsPageState extends State<ClubsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClubProvider>().fetchClubs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClubProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Horizontal Clubs',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    letterSpacing: -0.5)),
          ],
        ),
        actions: const [
          PbnAppBarActions(),
        ],
      ),
      body: provider.loading && provider.clubs.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => provider.fetchClubs(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Clubs Intro Card ──────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF334155)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CROSS-INDUSTRY COLLABORATION',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        const Text('Horizontal Clubs',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 8),
                        const Text(
                          'Join clubs based on industry verticals to collaborate with members across all chapters.',
                          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text('Active Clubs', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const SizedBox(height: 16),

                  if (provider.clubs.isEmpty)
                    _buildEmptyState()
                  else
                    ...provider.clubs.map((club) => _buildClubCard(club, provider)),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(TablerIcons.layers_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No clubs available yet', 
              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildClubCard(HorizontalClub club, ClubProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                child: const Icon(TablerIcons.layers_linked, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(club.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.text, letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Text(club.industries.join(', '), 
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 0.5)),
                  ],
                ),
              ),
              if (club.isMember)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('JOINED', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w900)),
                ),
            ],
          ),
          if (club.description != null) ...[
            const SizedBox(height: 12),
            Text(club.description!, 
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary, height: 1.4),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${club.minMembers}+ members required', 
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade400)),
              ElevatedButton(
                onPressed: (club.isMember || club.isEligible) ? () => provider.toggleMembership(club) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: club.isMember ? Colors.grey.shade100 : (club.isEligible ? AppColors.primary : Colors.grey.shade200),
                  foregroundColor: club.isMember ? AppColors.text : (club.isEligible ? Colors.white : Colors.grey.shade400),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(club.isMember ? 'Leave' : (club.isEligible ? 'Join Club' : 'Ineligible'), 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
