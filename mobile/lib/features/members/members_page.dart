import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/constants/api_config.dart';
import 'package:pbn/core/providers/member_provider.dart';
import 'package:pbn/models/member.dart';
import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  List<Member> _filtered = [];
  String _search = '';
  String? _selectedIndustry;
  String? _selectedChapter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MemberProvider>();
      if (provider.members.isEmpty) {
        provider.fetchMembers();
      } else {
        provider.fetchMembers(background: true);
      }
    });
  }

  List<Member> _getFilteredMembers(List<Member> members) {
    return members.where((m) {
      // Search Filter
      final matchesSearch = _search.isEmpty || 
          m.fullName.toLowerCase().contains(_search.toLowerCase()) ||
          m.industry.toLowerCase().contains(_search.toLowerCase()) ||
          m.company.toLowerCase().contains(_search.toLowerCase());

      // Industry Filter
      final matchesIndustry = _selectedIndustry == null || m.industry == _selectedIndustry;

      // Chapter Filter
      final matchesChapter = _selectedChapter == null || m.chapterName == _selectedChapter;

      return matchesSearch && matchesIndustry && matchesChapter;
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() => _search = query);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemberProvider>();
    final members = provider.members;
    
    final myChapterMembers = members.where((m) => m.isSameChapter).toList();
    final globalMembers = members.where((m) => !m.isSameChapter).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              'Network directory', 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -0.5)
            ),
          ],
        ),
        actions: const [
          PbnAppBarActions(),
        ],
        bottom: const TabBar(
          tabs: [
            Tab(text: 'My Chapter'),
            Tab(text: 'Global'),
          ],
          labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorWeight: 3,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      prefixIcon: const Icon(TablerIcons.search, size: 20, color: AppColors.primary),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(20),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _showFilterBottomSheet(members),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (_selectedIndustry != null || _selectedChapter != null) ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Icon(
                      TablerIcons.adjustments_horizontal, 
                      color: (_selectedIndustry != null || _selectedChapter != null) ? Colors.white : AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_selectedIndustry != null || _selectedChapter != null)
            _buildActiveFiltersRow(),
          Expanded(
            child: TabBarView(
              children: [
                _buildMemberList(provider, myChapterMembers),
                _buildMemberList(provider, globalMembers),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildMemberList(MemberProvider provider, List<Member> members) {
    final displayList = _getFilteredMembers(members);

    if (provider.loading && members.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (provider.error != null && members.isEmpty) {
      return _buildErrorState(provider.error!);
    }
    if (displayList.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: () => provider.fetchMembers(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: displayList.length,
        itemBuilder: (context, i) => _buildModernMemberCard(displayList[i]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Icon(TablerIcons.users_group, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _search.isEmpty ? 'No members found' : 'No results for "$_search"', 
            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w700)
          ),
        ]
      )
    );
  }

  Widget _buildModernMemberCard(Member member) {
    return GestureDetector(
      onTap: () => _showMemberDetailBottomSheet(member),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP HEADER: Dark Gradient
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A2540), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: (member.profilePhoto != null && member.profilePhoto!.isNotEmpty)
                            ? '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}${member.profilePhoto}'
                            : '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade100,
                          child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFF1E3A8A),
                          child: Center(
                            child: Text(member.initials,
                                style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white, letterSpacing: -0.3)),
                        const SizedBox(height: 4),
                        const SizedBox(height: 4),
                        Text(member.company,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.7))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // BOTTOM CONTENT: White Background
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(member.industry.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 0.5)),
                  ),
                  if (member.chapterName != null && member.chapterName!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(member.chapterName!.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange, letterSpacing: 0.5)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(List<Member> members) {
    final industries = members.map((m) => m.industry).toSet().toList()..sort();
    final chapters = members.where((m) => m.chapterName != null).map((m) => m.chapterName!).toSet().toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filters', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.text)),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndustry = null;
                      _selectedChapter = null;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Reset All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                )
              ],
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Industry'),
                    const SizedBox(height: 12),
                    _buildFilterList(industries, _selectedIndustry, (val) {
                      setState(() => _selectedIndustry = val);
                    }),
                    const SizedBox(height: 30),
                    if (chapters.isNotEmpty) ...[
                      _sectionTitle('Chapter'),
                      const SizedBox(height: 12),
                      _buildFilterList(chapters, _selectedChapter, (val) {
                        setState(() => _selectedChapter = val);
                      }),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title.toUpperCase(), 
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.5)
    );
  }

  Widget _buildFilterList(List<String> items, String? selected, Function(String?) onSelect) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        final isSelected = selected == item;
        return InkWell(
          onTap: () => onSelect(isSelected ? null : item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade100, width: 1.5),
            ),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 13, 
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textSecondary
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActiveFiltersRow() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 10, left: 20),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_selectedIndustry != null)
            _filterChip(_selectedIndustry!, () {
              setState(() => _selectedIndustry = null);
            }),
          if (_selectedChapter != null)
            _filterChip(_selectedChapter!, () {
              setState(() => _selectedChapter = null);
            }),
        ],
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          InkWell(
            onTap: onRemove,
            child: const Icon(TablerIcons.x, color: Colors.white, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            const Icon(TablerIcons.alert_circle, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<MemberProvider>().fetchMembers(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Try Again'),
            )
          ],
        ),
      ),
    );
  }

  void _showMemberDetailBottomSheet(Member member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(30, 24, 30, 24 + MediaQuery.of(context).padding.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profile Photo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 3),
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 20)],
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: (member.profilePhoto != null && member.profilePhoto!.isNotEmpty)
                              ? '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}${member.profilePhoto}'
                              : '',
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Center(
                            child: Text(member.initials, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(member.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.text)),
                    const SizedBox(height: 4),
                    Text(member.company, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(child: _detailRow(TablerIcons.building_store, "Chapter", member.chapterName ?? "Unknown")),
                        const SizedBox(width: 12),
                        Expanded(child: _detailRow(TablerIcons.category, "Industry", member.industry)),
                      ],
                    ),
                    
                    if (member.isSameChapter) ...[
                      const Divider(height: 30),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("CONTACT DETAILS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.5)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _detailRow(TablerIcons.mail, "Email", member.email ?? "-")),
                          const SizedBox(width: 12),
                          Expanded(child: _detailRow(TablerIcons.phone, "Phone", member.phoneNumber ?? "-")),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _contactButton(TablerIcons.phone, "Call", () {
                              if (member.phoneNumber != null) {
                                launchUrl(Uri.parse('tel:${member.phoneNumber}'));
                              }
                            }),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _contactButton(TablerIcons.brand_whatsapp, "WA", () {
                              if (member.phoneNumber != null) {
                                final phone = member.phoneNumber!.replaceAll(RegExp(r'\D'), '');
                                launchUrl(Uri.parse('https://wa.me/$phone'), mode: LaunchMode.externalApplication);
                              }
                            }),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _contactButton(TablerIcons.mail, "Email", () {
                               if (member.email != null) {
                                launchUrl(Uri.parse('mailto:${member.email}'));
                              }
                            }),
                          ),
                        ],
                      ),
                    ] else ...[
                       const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(TablerIcons.lock, color: AppColors.textSecondary, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Contact details are only visible to chapter members.",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.textSecondary)),
                Text(value, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactButton(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}
