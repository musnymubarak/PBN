import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:nexconnect/core/constants/app_colors.dart';
import 'package:nexconnect/models/member.dart';
import 'package:nexconnect/features/members/member_card.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final List<Member> _allMembers = Member.mockMembers;
  List<Member> _filteredMembers = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredMembers = _allMembers;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredMembers = _allMembers
          .where((member) =>
              member.name.toLowerCase().contains(query.toLowerCase()) ||
              member.industry.toLowerCase().contains(query.toLowerCase()) ||
              member.company.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Member Directory', style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(TablerIcons.adjustments_horizontal)),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search industry, name or company...',
                prefixIcon: const Icon(TablerIcons.search),
                fillColor: AppColors.background.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _filteredMembers.length,
              itemBuilder: (context, index) {
                return MemberCard(member: _filteredMembers[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
