import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:nexconnect/core/constants/app_colors.dart';
import 'package:nexconnect/core/widgets/custom_button.dart';
import 'package:nexconnect/models/member.dart';

class CreateReferralPage extends StatefulWidget {
  const CreateReferralPage({super.key});

  @override
  State<CreateReferralPage> createState() => _CreateReferralPageState();
}

class _CreateReferralPageState extends State<CreateReferralPage> {
  final List<Member> _members = Member.mockMembers.take(10).toList();
  String? _selectedMember;
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();

  void _submitReferral() {
    if (_selectedMember == null || _descriptionController.text.isEmpty || _valueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all referral details'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Business Referral Sent Successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Create Referral', style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(TablerIcons.briefcase, color: AppColors.accent, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'NEW BUSINESS OPPORTUNITY',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Select Recipient Member',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Choose a professional partner'),
                  value: _selectedMember,
                  icon: const Icon(TablerIcons.chevron_down),
                  onChanged: (value) => setState(() => _selectedMember = value),
                  items: _members.map((Member member) {
                    return DropdownMenuItem<String>(
                      value: member.name,
                      child: Text(member.name),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Business Opportunity Description',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'e.g., Looking for a residential construction service for a new 3,000 sqft house inquiry from my close circle.',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Estimated Transaction Value (LKR)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g., 250,500.00',
                prefixIcon: Icon(TablerIcons.coin),
              ),
            ),
            const SizedBox(height: 48),
            CustomButton(
              text: 'SUBMIT REFERRAL',
              backgroundColor: AppColors.accent,
              onPressed: _submitReferral,
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Chapter members will be notified instantly.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
