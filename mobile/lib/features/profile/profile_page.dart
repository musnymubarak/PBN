import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart' as sk;

import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/providers/member_provider.dart';
import 'package:pbn/core/providers/notification_provider.dart';
import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/core/services/chapter_service.dart';
import 'package:pbn/core/widgets/cached_avatar.dart';
import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';
import 'package:pbn/features/matchmaking/business_matching_profile_page.dart';
import 'package:pbn/models/chapter.dart';
import 'package:pbn/models/user.dart';

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

      // ── Client-side Validation ──────────────────────────
      final int fileSize = await pickedFile.length();
      const int maxSizeBytes = 5 * 1024 * 1024; // 5MB
      final String ext = pickedFile.path.split('.').last.toLowerCase();
      final List<String> allowedExts = ['jpg', 'jpeg', 'png', 'webp'];

      if (fileSize > maxSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File too large. Maximum allowed size is 5MB. Your file: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB.')),
          );
        }
        return;
      }

      if (!allowedExts.contains(ext)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid format. Only JPG, PNG, and WebP are allowed.')),
          );
        }
        return;
      }

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated successfully!')));
    } catch (e) {
      String message = 'Failed to upload photo.';
      if (e is DioException) {
        message = e.response?.data?['message'] ?? message;
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editProfile(String initialName, String initialPhone, {String? initialEmail, bool focusEmail = false}) async {
    final nameCtrl = TextEditingController(text: initialName);
    final phoneCtrl = TextEditingController(text: initialPhone);
    final emailCtrl = TextEditingController(text: initialEmail ?? '');
    final emailFocus = FocusNode();
    bool saving = false;

    if (focusEmail) {
      WidgetsBinding.instance.addPostFrameCallback((_) => emailFocus.requestFocus());
    }

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
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  focusNode: emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'name@example.com',
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
                    final email = emailCtrl.text.trim();
                    final payload = <String, dynamic>{
                      'full_name': nameCtrl.text.trim(),
                      'phone_number': phoneCtrl.text.trim(),
                    };
                    if (email.isNotEmpty) payload['email'] = email;
                    await ApiClient().put('/auth/me', data: payload);
                    if (context.mounted) {
                      await context.read<AuthProvider>().tryAutoLogin();
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
                    }
                  } catch (e) {
                    String message = 'Failed to update profile.';
                    if (e is DioException) {
                      message = e.response?.data?['message'] ?? message;
                    }
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _confirmSignOut() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(TablerIcons.logout, color: AppColors.error, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('Sign out?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'You will need to log in again to access your PBN dashboard, referrals, and chapters.',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.textSecondary, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    context.read<MemberProvider>().clearCache();
    context.read<NotificationProvider>().stopListening();
    await auth.logout();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  Future<void> _confirmDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(TablerIcons.trash, color: AppColors.error, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('Delete Account?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'This action is permanent and cannot be undone. All your data, memberships, and history will be deleted.',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.textSecondary, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ApiClient().dio.delete('/auth/me');
      if (!mounted) return;
      
      final auth = context.read<AuthProvider>();
      context.read<MemberProvider>().clearCache();
      context.read<NotificationProvider>().stopListening();
      await auth.logout();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    } catch (e) {
      String message = 'Failed to delete account.';
      if (e is DioException) {
        message = e.response?.data?['message'] ?? message;
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final sections = <Widget>[
      _buildHeroCard(user),
      const SizedBox(height: 14),
      _buildCompletenessBand(user),
      const SizedBox(height: 14),
      _buildQuickStats(user),
      const SizedBox(height: 24),
      _sectionHeader('Personal Information'),
      _buildPersonalInfoCard(user),
      if (_memberships.isNotEmpty) ...[
        const SizedBox(height: 24),
        _sectionHeader('Memberships'),
        ..._memberships.map(_buildMembershipCard),
      ],
      const SizedBox(height: 24),
      _sectionHeader('Account'),
      _buildGroupedAccountCard(),
      const SizedBox(height: 24),
      _buildSignOutCard(),
      const SizedBox(height: 16),
      _buildDeleteAccountCard(),
      const SizedBox(height: 24),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: sk.Skeletonizer(
        enabled: _loading,
        enableSwitchAnimation: true,
        effect: sk.ShimmerEffect(
          baseColor: AppColors.surfaceAlt,
          highlightColor: Colors.white.withValues(alpha: 0.9),
          duration: const Duration(milliseconds: 1400),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: 60,
              floating: true,
              snap: true,
              title: const Text(
                'Profile',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -0.5),
              ),
              actions: const [PbnAppBarActions()],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverList.list(
                children: List.generate(sections.length, (i) {
                  final delayMs = (i * 35).clamp(0, 280);
                  return sections[i]
                      .animate(delay: delayMs.ms)
                      .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.10, end: 0, duration: 320.ms, curve: Curves.easeOutCubic);
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // SECTION HEADER (gold bar + bold title, matches home page)
  // ──────────────────────────────────────────────────────────
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.goldGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.3,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // 1) HERO IDENTITY CARD
  // ──────────────────────────────────────────────────────────
  Widget _buildHeroCard(User? user) {
    final level = (user?.verificationLevel ?? 'none').toLowerCase();
    final hasTier = level != 'none';
    final tierColor = _tierColor(level);
    final roleText = (user?.role ?? '').replaceAll('_', ' ').toUpperCase();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Ambient gold glow top-right
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentBlue.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              child: Row(
                children: [
                  // Gold-ringed avatar
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: AppColors.goldGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: CachedAvatar(
                          imageUrl: user?.profilePhoto,
                          initials: user?.initials ?? '?',
                          size: 78,
                          backgroundColor: AppColors.surface,
                          textColor: AppColors.primary,
                          fontSize: 28,
                        ),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _pickAndUploadPhoto();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: AppColors.goldGradient,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(TablerIcons.camera_plus, size: 13, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  // Identity column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user?.fullName ?? '',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            height: 1.1,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (roleText.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  roleText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            if (hasTier)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      tierColor.withValues(alpha: 0.28),
                                      tierColor.withValues(alpha: 0.10),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: tierColor.withValues(alpha: 0.55), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(TablerIcons.discount_check_filled, color: tierColor, size: 11),
                                    const SizedBox(width: 3),
                                    Text(
                                      level.toUpperCase(),
                                      style: TextStyle(
                                        color: tierColor,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // EDIT gold pill
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _editProfile(
                                user?.fullName ?? '',
                                user?.phoneNumber ?? '',
                                initialEmail: user?.email,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: AppColors.goldGradient),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(TablerIcons.edit, color: Colors.white, size: 13),
                                  SizedBox(width: 6),
                                  Text(
                                    'EDIT PROFILE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // 2) PROFILE COMPLETENESS BAND
  // ──────────────────────────────────────────────────────────
  Widget _buildCompletenessBand(User? user) {
    // Completeness: 3 user-actionable checks (photo, email, phone).
    // Verification tier is admin-controlled — not included here; shown in hero chip instead.
    final hasPhoto = user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty;
    final hasEmail = user?.email != null && user!.email!.isNotEmpty;
    final hasPhone = user?.phoneNumber != null && user!.phoneNumber.isNotEmpty;
    int filled = 0;
    if (hasPhoto) filled++;
    if (hasEmail) filled++;
    if (hasPhone) filled++;
    const total = 3;
    final percent = (filled / total * 100).round();
    final complete = filled == total;

    // Contextual hint + action — each missing piece opens its own flow.
    String hint;
    VoidCallback action;
    if (!hasPhoto) {
      hint = 'Add a profile photo to stand out';
      action = _pickAndUploadPhoto;
    } else if (!hasEmail) {
      hint = 'Add your email for important updates';
      action = () => _editProfile(
            user.fullName,
            user.phoneNumber,
            initialEmail: user.email,
            focusEmail: true,
          );
    } else if (!hasPhone) {
      hint = 'Add your mobile number';
      action = () => _editProfile(
            user.fullName,
            user.phoneNumber,
            initialEmail: user.email,
          );
    } else {
      hint = 'Setup business matching to find leads';
      action = () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BusinessMatchingProfilePage()),
          );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.selectionClick();
          action();
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFDF7), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
            boxShadow: AppColors.shadowSm,
          ),
          child: Row(
            children: [
              // Progress arc using stacked SizedBox
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation(AppColors.borderLight),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        value: filled / total,
                        strokeWidth: 4,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      complete ? 'NEXT STEP' : 'PROFILE PROGRESS',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: GoogleFonts.dmSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(TablerIcons.chevron_right, color: AppColors.accent, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // 3) QUICK STATS STRIP
  // ──────────────────────────────────────────────────────────
  Widget _buildQuickStats(User? user) {
    int years = 0;
    int months = 0;
    try {
      if (user?.createdAt.isNotEmpty == true) {
        final dt = DateTime.parse(user!.createdAt).toLocal();
        final diff = DateTime.now().difference(dt);
        years = diff.inDays ~/ 365;
        months = (diff.inDays % 365) ~/ 30;
      }
    } catch (_) {}

    final tenureLabel = years > 0
        ? '${years}y${months > 0 ? ' ${months}m' : ''}'
        : months > 0
            ? '${months}m'
            : 'New';

    final tierLabel = (user?.verificationLevel ?? 'none').toLowerCase();
    final tierText = tierLabel == 'none' ? 'Member' : '${tierLabel[0].toUpperCase()}${tierLabel.substring(1)}';

    Widget chip(IconData icon, Color color, String value, String label) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.surfaceGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            boxShadow: AppColors.shadowSm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.18),
                      color.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: color.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: color, size: 13),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        letterSpacing: -0.3,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(TablerIcons.calendar_check, AppColors.accentBlue, tenureLabel, 'Tenure'),
        const SizedBox(width: 8),
        chip(TablerIcons.building_skyscraper, AppColors.accent, '${_memberships.length}', 'Chapters'),
        const SizedBox(width: 8),
        chip(TablerIcons.shield_check, AppColors.success, tierText, 'Status'),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // 4) PERSONAL INFO CARD (grouped: phone / email / since)
  // ──────────────────────────────────────────────────────────
  Widget _buildPersonalInfoCard(User? user) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(
        children: [
          _premiumInfoRow(
            icon: TablerIcons.phone,
            iconColor: AppColors.accentBlue,
            label: 'MOBILE NUMBER',
            value: user?.phoneNumber.isNotEmpty == true ? user!.phoneNumber : 'Not set',
          ),
          _hairlineDivider(),
          _premiumInfoRow(
            icon: TablerIcons.mail,
            iconColor: const Color(0xFF8B5CF6),
            label: 'EMAIL ADDRESS',
            value: user?.email?.isNotEmpty == true ? user!.email! : 'No email provided',
          ),
          _hairlineDivider(),
          _premiumInfoRow(
            icon: TablerIcons.calendar,
            iconColor: AppColors.accent,
            label: 'MEMBER SINCE',
            value: _formatMemberSince(user?.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _hairlineDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 1,
        color: AppColors.border.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _premiumInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withValues(alpha: 0.18),
                  iconColor.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: iconColor.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMemberSince(String? iso) {
    if (iso == null || iso.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return iso.split('T').first;
    }
  }

  // ──────────────────────────────────────────────────────────
  // 5) MEMBERSHIP CARD (refined)
  // ──────────────────────────────────────────────────────────
  Widget _buildMembershipCard(Membership m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.shadowSm,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.18),
                  AppColors.accent.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
            ),
            child: const Icon(TablerIcons.building_skyscraper, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  m.chapter.name,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.text,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  m.industryCategory.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  m.membershipType.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accent,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: m.isActive
                    ? [AppColors.success.withValues(alpha: 0.2), AppColors.success.withValues(alpha: 0.08)]
                    : [Colors.grey.withValues(alpha: 0.15), Colors.grey.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: m.isActive ? AppColors.success.withValues(alpha: 0.35) : Colors.grey.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: m.isActive ? AppColors.success : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  m.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: m.isActive ? AppColors.success : Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // 6) GROUPED ACCOUNT CARD (iOS-style settings list)
  // ──────────────────────────────────────────────────────────
  Widget _buildGroupedAccountCard() {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.shadowMd,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            _settingsRow(
              icon: TablerIcons.bell_cog,
              iconColor: const Color(0xFFF59E0B),
              title: 'Notification Preferences',
              subtitle: 'Customize your push alerts',
              onTap: () => Navigator.pushNamed(context, '/notification-settings'),
            ),
            _hairlineDivider(),
            _settingsRow(
              icon: TablerIcons.credit_card,
              iconColor: AppColors.accentBlue,
              title: 'Payment History',
              subtitle: 'Manage your payments and invoices',
              onTap: () => Navigator.pushNamed(context, '/payments'),
            ),
            _hairlineDivider(),
            _settingsRow(
              icon: TablerIcons.sparkles,
              iconColor: AppColors.accent,
              title: 'Business Matching Profile',
              subtitle: 'Setup your needs and target sectors',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BusinessMatchingProfilePage()),
              ),
            ),
            _hairlineDivider(),
            _settingsSwitchRow(
              icon: TablerIcons.shield_lock,
              iconColor: const Color(0xFF10B981),
              title: 'Two-Factor Authentication',
              subtitle: 'Require email verification to log in',
              value: user?.twoFactorEnabled ?? false,
              onChanged: _toggleTwoFactor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        splashColor: iconColor.withValues(alpha: 0.06),
        highlightColor: iconColor.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withValues(alpha: 0.18),
                      iconColor.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: iconColor.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, size: 19, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: AppColors.text,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: const Icon(TablerIcons.chevron_right, color: AppColors.textMuted, size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsSwitchRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withValues(alpha: 0.18),
                  iconColor.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: iconColor.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppColors.text,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTwoFactor(bool newValue) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    if (newValue && (user.email == null || user.email!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must configure an email address before enabling Two-Factor Authentication.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final passwordCtrl = TextEditingController();
    bool submittable = false;
    bool dialogLoading = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              newValue ? 'Enable Two-Factor?' : 'Disable Two-Factor?',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  newValue
                      ? 'Confirm your password to enable Two-Factor Authentication. A login verification code will be sent to your email.'
                      : 'Confirm your password to disable Two-Factor Authentication.',
                  style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  onChanged: (val) {
                    setModalState(() {
                      submittable = val.trim().isNotEmpty;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: dialogLoading ? null : () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: (!submittable || dialogLoading)
                    ? null
                    : () async {
                        setModalState(() => dialogLoading = true);
                        final success = await auth.toggle2FA(newValue, passwordCtrl.text.trim());
                        if (context.mounted) {
                          if (success) {
                            Navigator.pop(ctx, true);
                          } else {
                            setModalState(() => dialogLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(auth.error ?? 'Failed to update Two-Factor Authentication setting'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: dialogLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newValue
                ? 'Two-Factor Authentication enabled successfully.'
                : 'Two-Factor Authentication disabled.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ──────────────────────────────────────────────────────────
  // 7) SIGN OUT CARD (outlined, with confirmation)
  // ──────────────────────────────────────────────────────────
  Widget _buildSignOutCard() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          _confirmSignOut();
        },
        splashColor: AppColors.error.withValues(alpha: 0.06),
        highlightColor: AppColors.error.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.22), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(TablerIcons.logout, size: 18, color: AppColors.error),
              const SizedBox(width: 10),
              Text(
                'Sign Out',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.error,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // 8) DELETE ACCOUNT CARD
  // ──────────────────────────────────────────────────────────
  Widget _buildDeleteAccountCard() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          _confirmDeleteAccount();
        },
        splashColor: Colors.red.withValues(alpha: 0.06),
        highlightColor: Colors.red.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.22), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(TablerIcons.trash, size: 18, color: Colors.red),
              const SizedBox(width: 10),
              Text(
                'Delete Account',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.red,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────
  Color _tierColor(String level) {
    switch (level.toLowerCase()) {
      case 'platinum':
        return const Color(0xFFE5E7EB);
      case 'gold':
        return const Color(0xFFFACC15);
      case 'silver':
        return AppColors.textMuted;
      case 'verified':
        return const Color(0xFF3B82F6);
      default:
        return AppColors.accent;
    }
  }
}
