import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/services/chapter_service.dart';
import 'package:pbn/models/chapter.dart';
import 'package:pbn/core/constants/api_config.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbn/core/services/api_client.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _chapterService = ChapterService();
  List<Membership> _memberships = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _memberships = await _chapterService.getMyMemberships();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;
      
      setState(() => _loading = true);
      
      final dio = ApiClient().dio;
      final bytes = await pickedFile.readAsBytes();
      final fileData = MultipartFile.fromBytes(bytes, filename: pickedFile.name);
      final formData = FormData.fromMap({'file': fileData});
      
      await dio.post(
        '/auth/me/photo', 
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      
      if (!mounted) return;
      await context.read<AuthProvider>().tryAutoLogin(); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated successfully!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload photo.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editProfile(String initialName, String initialPhone) async {
    final nameCtrl = TextEditingController(text: initialName);
    final phoneCtrl = TextEditingController(text: initialPhone);
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w800)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: saving ? null : () async {
                  setModalState(() => saving = true);
                  try {
                    await ApiClient().put('/auth/me', data: {
                      'full_name': nameCtrl.text.trim(),
                      'phone_number': phoneCtrl.text.trim(),
                    });
                    if (mounted) {
                      await context.read<AuthProvider>().tryAutoLogin();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile.')));
                  }
                  setModalState(() => saving = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w800))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(padding: const EdgeInsets.all(20), children: [
              // ── Profile Split Card Modern UI ──────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Dark Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF0A2540), Color(0xFF1E3A8A)]),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                      ),
                      child: Row(children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.2), width: 2)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: user?.id != null 
                                    ? Image.network(
                                        user!.profilePhoto != null 
                                            ? '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}${user.profilePhoto}' 
                                            : 'https://i.pravatar.cc/150?u=${user.id}', 
                                        fit: BoxFit.cover, 
                                        errorBuilder: (c, e, s) => Center(child: Text(user.initials, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w900, fontSize: 28))))
                                    : const SizedBox(),
                              ),
                            ),
                            Positioned(
                              right: -6, bottom: -6,
                              child: GestureDetector(
                                onTap: _pickAndUploadPhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1E3A8A), width: 3)),
                                  child: const Icon(TablerIcons.camera_plus, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(user?.fullName ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                            child: Text(user?.role.toUpperCase() ?? '', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          ),
                        ])),
                        IconButton(
                          icon: const Icon(TablerIcons.edit, color: Colors.white70),
                          onPressed: () => _editProfile(user?.fullName ?? '', user?.phoneNumber ?? ''),
                        ),
                      ]),
                    ),
                    // Bottom Info Section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildInfoRow(TablerIcons.phone, 'Mobile Number', user?.phoneNumber ?? ''),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                          _buildInfoRow(TablerIcons.mail, 'Email Address', user?.email ?? 'No email provided'),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                          _buildInfoRow(TablerIcons.calendar, 'Member Since', user?.createdAt.split('T').first ?? ''),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Memberships ──────────────────────────
              if (_memberships.isNotEmpty) ...[
                const Text('My Chapters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                ..._memberships.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(TablerIcons.building_skyscraper, color: AppColors.primary, size: 24)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.chapter.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.text, letterSpacing: -0.3)),
                      const SizedBox(height: 4),
                      Text(m.industryCategory.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: m.isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(m.isActive ? 'ACTIVE' : 'INACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: m.isActive ? Colors.green : Colors.grey)),
                    ),
                  ]),
                )),
              ],

              const SizedBox(height: 32),
              // ── Logout ────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await auth.logout();
                    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                  },
                  icon: const Icon(TablerIcons.logout, size: 20),
                  label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade100.withOpacity(0.3),
                    foregroundColor: Colors.redAccent.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ]),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
          ],
        ),
      ],
    );
  }
}
