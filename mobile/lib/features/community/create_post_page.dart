import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/community_service.dart';
import 'package:pbn/core/services/application_service.dart';
import 'package:pbn/core/services/club_service.dart';
import 'package:pbn/models/chapter.dart';
import 'package:pbn/models/horizontal_club.dart';
import 'package:pbn/core/widgets/custom_button.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _service = CommunityService();
  final _appService = ApplicationService();
  final _clubService = ClubService();
  
  final _controller = TextEditingController();
  final _budgetController = TextEditingController();
  
  String _postType = 'general';
  String _visibility = 'chapter';
  DateTime? _deadline;
  String? _selectedIndustryId;
  String? _selectedClubId;
  
  List<IndustryCategory> _industries = [];
  List<HorizontalClub> _clubs = [];
  bool _loading = false;
  bool _fetchingData = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _appService.getIndustryCategories(),
        _clubService.listClubs(),
      ]);
      if (mounted) {
        setState(() {
          _industries = results[0] as List<IndustryCategory>;
          _clubs = results[1] as List<HorizontalClub>;
          _fetchingData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _fetchingData = false);
    }
  }

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _loading = true);
    try {
      final newPost = await _service.createPost(
        content,
        postType: _postType,
        visibility: _visibility,
        budgetRange: _postType != 'general' ? _budgetController.text : null,
        deadline: _postType != 'general' ? _deadline : null,
        targetIndustryId: _postType != 'general' ? _selectedIndustryId : null,
        targetClubId: _visibility == 'club' ? _selectedClubId : null,
      );
      if (mounted) {
        Navigator.pop(context, newPost);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share post')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('New Post', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          _loading 
            ? const Center(child: Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
            : TextButton(
                onPressed: _submit,
                child: const Text('POST', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
              ),
        ],
      ),
      body: _fetchingData 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post Type Selector
                const Text('POST CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTypeChip('General', 'general', TablerIcons.news),
                    const SizedBox(width: 8),
                    _buildTypeChip('Lead', 'lead', TablerIcons.flame),
                    const SizedBox(width: 8),
                    _buildTypeChip('RFP', 'rfp', TablerIcons.clipboard_list),
                  ],
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _controller,
                  maxLines: 6,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: _postType == 'general' ? "What's on your mind?" : "Describe the business opportunity...",
                    border: InputBorder.none,
                  ),
                ),
                
                if (_postType != 'general') ...[
                  const Divider(height: 40),
                  const Text('OPPORTUNITY DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                  const SizedBox(height: 16),
                  
                  // Budget Range
                  _buildSectionLabel('Budget / Value Range'),
                  TextField(
                    controller: _budgetController,
                    decoration: InputDecoration(
                      hintText: "e.g. LKR 50,000 - 150,000",
                      prefixIcon: const Icon(TablerIcons.coin, size: 20),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Deadline
                  _buildSectionLabel('Deadline'),
                  InkWell(
                    onTap: _selectDeadline,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(TablerIcons.calendar_event, size: 20, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Text(
                            _deadline == null ? 'Select Deadline' : DateFormat('MMM dd, yyyy').format(_deadline!),
                            style: TextStyle(fontWeight: FontWeight.w600, color: _deadline == null ? Colors.grey : AppColors.text),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Target Industry
                  _buildSectionLabel('Target Industry'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Select Industry'),
                        value: _selectedIndustryId,
                        items: _industries.map((i) => DropdownMenuItem(value: i.id, child: Text(i.name))).toList(),
                        onChanged: (v) => setState(() => _selectedIndustryId = v),
                      ),
                    ),
                  ),
                ],

                const Divider(height: 40),
                const Text('VISIBILITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildVisibilityChip('My Chapter', 'chapter', TablerIcons.building_community),
                    const SizedBox(width: 8),
                    _buildVisibilityChip('Network', 'network', TablerIcons.world),
                    const SizedBox(width: 8),
                    _buildVisibilityChip('Club', 'club', TablerIcons.users_group),
                  ],
                ),

                if (_visibility == 'club') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Select Horizontal Club'),
                        value: _selectedClubId,
                        items: _clubs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (v) => setState(() => _selectedClubId = v),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(TablerIcons.photo, color: Colors.grey.shade400),
                      const SizedBox(width: 12),
                      Text('Add Images (Coming Soon)', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
    );
  }

  Widget _buildTypeChip(String label, String value, IconData icon) {
    final isSelected = _postType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _postType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 18),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityChip(String label, String value, IconData icon) {
    final isSelected = _visibility == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _visibility = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade600 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.blue.shade600 : Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 18),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
    );
  }
}
