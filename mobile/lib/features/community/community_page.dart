import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart' as sk;

import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/services/community_service.dart';
import 'package:pbn/core/services/push_notification_service.dart';
import 'package:pbn/core/widgets/cached_avatar.dart';
import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';
import 'package:pbn/core/widgets/pbn_bottom_sheet.dart';
import 'package:pbn/features/community/create_post_page.dart';
import 'package:pbn/models/community.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with WidgetsBindingObserver {
  final _service = CommunityService();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  Timer? _liveTimer;
  StreamSubscription? _notifSubscription;

  List<CommunityPost> _posts = [];
  bool _loading = true;
  String? _error;
  String _activeFilter = 'all';
  String _searchQuery = '';
  bool _networkWide = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFeed();
    _startLiveUpdates();
    _listenToNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLiveUpdates();
    _notifSubscription?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _listenToNotifications() {
    _notifSubscription =
        PushNotificationService.onMessageStream.listen((message) {
      final type = message.data['type']?.toString().toLowerCase();
      final notificationType =
          message.data['notification_type']?.toString().toLowerCase();
      if (type == 'community' ||
          type == 'community_post' ||
          notificationType?.contains('community') == true) {
        _loadFeed(isSilent: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startLiveUpdates();
    } else {
      _stopLiveUpdates();
    }
  }

  void _startLiveUpdates() {
    _stopLiveUpdates();
    _liveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _searchQuery.isEmpty) {
        _loadFeed(isSilent: true);
      }
    });
  }

  void _stopLiveUpdates() {
    _liveTimer?.cancel();
    _liveTimer = null;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
      _loadFeed();
    });
  }

  Future<void> _loadFeed({bool isSilent = false}) async {
    if (!isSilent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final posts = await _service.getFeed(
        search: _searchQuery,
        filter: _activeFilter,
        networkWide: _networkWide,
      );
      if (mounted) {
        setState(() {
          _posts = posts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && !isSilent) {
        setState(() {
          _error = 'Failed to load feed';
          _loading = false;
        });
      }
    }
  }

  // ──────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Text(
              'Chapter Feed',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.5),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: const [PbnAppBarActions()],
      ),
      body: Column(
        children: [
          _buildStickyHeader(),
          Expanded(
            child: sk.Skeletonizer(
              enabled: _loading && _posts.isEmpty,
              enableSwitchAnimation: true,
              effect: sk.ShimmerEffect(
                baseColor: AppColors.surfaceAlt,
                highlightColor: Colors.white.withValues(alpha: 0.9),
                duration: const Duration(milliseconds: 1400),
              ),
              child: RefreshIndicator(
                onRefresh: _loadFeed,
                color: AppColors.primary,
                child: _buildBody(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ──────────────────────────────────────────────────────────
  // STICKY HEADER — scope toggle + search + filter chips
  // ──────────────────────────────────────────────────────────
  Widget _buildStickyHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Column(
        children: [
          // Scope toggle: pill segmented control with gold underline.
          Container(
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                _scopeTab('My Chapter', TablerIcons.users, false),
                _scopeTab('Network', TablerIcons.world, true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Search bar
          _buildSearchField(),
          const SizedBox(height: 12),
          // Filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                _filterChip('All Posts', 'all', TablerIcons.layout_list),
                const SizedBox(width: 8),
                _filterChip('Leads', 'lead', TablerIcons.flame),
                const SizedBox(width: 8),
                _filterChip('RFPs', 'rfp', TablerIcons.clipboard_list),
                const SizedBox(width: 8),
                _filterChip('My Posts', 'my_posts', TablerIcons.user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scopeTab(String label, IconData icon, bool isNetwork) {
    final selected = _networkWide == isNetwork;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _networkWide = isNetwork;
            _activeFilter = 'all';
          });
          _loadFeed();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected ? AppColors.shadowSm : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color:
                    selected ? AppColors.accent : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: selected
                      ? FontWeight.w900
                      : FontWeight.w700,
                  color: selected
                      ? AppColors.text
                      : AppColors.textMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final hasFocus = _searchFocus.hasFocus;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasFocus
              ? AppColors.accent.withValues(alpha: 0.5)
              : AppColors.border.withValues(alpha: 0.7),
          width: hasFocus ? 1.4 : 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        onChanged: _onSearchChanged,
        onTap: () => setState(() {}),
        onSubmitted: (_) => setState(() {}),
        style: GoogleFonts.dmSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        decoration: InputDecoration(
          hintText: 'Search posts, leads, or RFPs…',
          hintStyle: GoogleFonts.dmSans(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(TablerIcons.search,
              color: AppColors.textSecondary, size: 18),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(TablerIcons.x,
                      size: 16, color: AppColors.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value, IconData icon) {
    final selected = _activeFilter == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeFilter = value);
        _loadFeed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: AppColors.goldGradient)
              : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppColors.border.withValues(alpha: 0.7),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                color:
                    selected ? Colors.white : AppColors.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // BODY
  // ──────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_error != null && _posts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        children: [_buildErrorState()],
      );
    }

    if (_loading && _posts.isEmpty) {
      // Skeletonizer wraps the list — generate fake posts as placeholders.
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (ctx, i) => _PostCard(
          post: _skeletonPost(),
          onRefresh: _loadFeed,
        ),
      );
    }

    if (_posts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        children: [_buildEmptyState()],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _posts.length + (_error != null ? 1 : 0),
      itemBuilder: (context, i) {
        // Inline error banner above the list when a non-empty list also
        // hit a transient failure on its last refresh.
        if (_error != null && i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _inlineErrorBanner(),
          );
        }
        final idx = _error != null ? i - 1 : i;
        return _PostCard(
          post: _posts[idx],
          onRefresh: _loadFeed,
        );
      },
    );
  }

  CommunityPost _skeletonPost() {
    return CommunityPost(
      id: 'skeleton',
      chapterId: 'sk',
      content:
          'Quick update from the chapter — closing in on the quarterly '
          'target and looking for two more intros into hospitality.',
      isPinned: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      author: PostAuthor(
        id: 'sk',
        fullName: 'Member Name',
        role: 'CHAPTER_MEMBER',
      ),
      likesCount: 12,
      commentsCount: 3,
      isLikedByMe: false,
      postType: 'general',
      visibility: 'chapter',
    );
  }

  // ──────────────────────────────────────────────────────────
  // EMPTY STATE
  // ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    String title;
    String message;
    IconData icon;

    if (_searchQuery.isNotEmpty) {
      title = 'No matches';
      message = 'Nothing came back for "$_searchQuery". Try a different keyword.';
      icon = TablerIcons.search_off;
    } else if (_activeFilter == 'lead') {
      title = 'No leads right now';
      message = 'Open leads from your chapter and network will appear here.';
      icon = TablerIcons.flame;
    } else if (_activeFilter == 'rfp') {
      title = 'No RFPs right now';
      message = 'Requests for proposals will appear here as members post them.';
      icon = TablerIcons.clipboard_list;
    } else if (_activeFilter == 'my_posts') {
      title = "You haven't posted yet";
      message = 'Share an update, a lead, or an RFP to start the conversation.';
      icon = TablerIcons.user;
    } else {
      title = 'Be the first to post';
      message =
          'The feed is quiet. Drop in with an update — your chapter is watching.';
      icon = TablerIcons.messages;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.18),
                  AppColors.accent.withValues(alpha: 0.06),
                ],
              ),
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, size: 36, color: AppColors.accent),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          if (_searchQuery.isEmpty && _activeFilter == 'all')
            _goldPillCta(
              icon: TablerIcons.plus,
              label: 'NEW POST',
              onTap: _openCreate,
            )
          else
            _ghostPillCta(
              icon: TablerIcons.refresh,
              label: 'CLEAR FILTERS',
              onTap: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _activeFilter = 'all';
                });
                _loadFeed();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warning.withValues(alpha: 0.18),
                  AppColors.warning.withValues(alpha: 0.06),
                ],
              ),
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppColors.warning.withValues(alpha: 0.30)),
            ),
            child: const Icon(TablerIcons.alert_triangle,
                size: 36, color: AppColors.warning),
          ),
          const SizedBox(height: 18),
          Text(
            "Couldn't load the feed",
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _error ?? 'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          _goldPillCta(
            icon: TablerIcons.refresh,
            label: 'RETRY',
            onTap: _loadFeed,
          ),
        ],
      ),
    );
  }

  Widget _inlineErrorBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha: 0.10),
            AppColors.warning.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.warning.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warning.withValues(alpha: 0.18),
                  AppColors.warning.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.22)),
            ),
            child: const Icon(TablerIcons.alert_triangle,
                color: AppColors.warning, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error ?? 'A refresh failed.',
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                HapticFeedback.selectionClick();
                _loadFeed();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.30)),
                ),
                child: Text(
                  'RETRY',
                  style: GoogleFonts.dmSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.warning,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _goldPillCta({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.goldGradient),
            borderRadius: BorderRadius.circular(12),
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
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ghostPillCta({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.border.withValues(alpha: 0.7), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // FAB — gold gradient with goldGlow
  // ──────────────────────────────────────────────────────────
  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.40),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            _openCreate();
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.goldGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(TablerIcons.feather,
                color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  void _openCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostPage()),
    ).then((result) {
      if (result is CommunityPost) {
        setState(() => _posts.insert(0, result));
      } else if (result == true) {
        _loadFeed();
      }
    });
  }
}

// ──────────────────────────────────────────────────────────────
// POST CARD
// ──────────────────────────────────────────────────────────────
class _PostCard extends StatefulWidget {
  final CommunityPost post;
  final VoidCallback onRefresh;

  const _PostCard({required this.post, required this.onRefresh});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  final _service = CommunityService();
  late bool _isLiked;
  late int _likesCount;
  late bool _isPinned;
  late int _commentsCount;
  bool _liking = false;
  bool _pinning = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByMe;
    _likesCount = widget.post.likesCount;
    _isPinned = widget.post.isPinned;
    _commentsCount = widget.post.commentsCount;
  }

  @override
  void didUpdateWidget(_PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.id == oldWidget.post.id) {
      if (!_liking) {
        _isLiked = widget.post.isLikedByMe;
        _likesCount = widget.post.likesCount;
      }
      if (!_pinning) _isPinned = widget.post.isPinned;
      _commentsCount = widget.post.commentsCount;
    } else {
      _isLiked = widget.post.isLikedByMe;
      _likesCount = widget.post.likesCount;
      _isPinned = widget.post.isPinned;
      _commentsCount = widget.post.commentsCount;
    }
  }

  Future<void> _toggleLike() async {
    if (_liking) return;
    HapticFeedback.selectionClick();
    setState(() {
      _liking = true;
      if (_isLiked) {
        _likesCount--;
        _isLiked = false;
      } else {
        _likesCount++;
        _isLiked = true;
      }
    });

    try {
      final result = await _service.toggleLike(widget.post.id);
      if (mounted) {
        setState(() {
          _likesCount = result['likes_count'];
          _isLiked = result['is_liked'];
          _liking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _liking = false;
          if (_isLiked) {
            _likesCount--;
            _isLiked = false;
          } else {
            _likesCount++;
            _isLiked = true;
          }
        });
      }
    }
  }

  Future<void> _togglePin() async {
    if (_pinning) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pinning = true;
      _isPinned = !_isPinned;
    });

    try {
      final result = await _service.togglePin(widget.post.id);
      if (mounted) {
        setState(() {
          _isPinned = result['is_pinned'];
          _pinning = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pinning = false;
          _isPinned = !_isPinned;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final canDelete = auth.user?.id == widget.post.author.id ||
        auth.user?.role == 'SUPER_ADMIN' ||
        auth.user?.role == 'CHAPTER_ADMIN';

    final isLead = widget.post.postType == 'lead';
    final isRFP = widget.post.postType == 'rfp';
    final hasBusinessDetails = isLead || isRFP;

    // Top accent strip tints leads gold (premium opportunity) and RFPs
    // blue (informational). General posts have no strip.
    final Color? accentStrip = isLead
        ? AppColors.accent
        : (isRFP ? AppColors.accentBlue : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (accentStrip != null)
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentStrip,
                      accentStrip.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),

            // Header: avatar + name + meta + type pill + actions
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _goldRingedAvatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                widget.post.author.fullName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: AppColors.text,
                                  letterSpacing: -0.2,
                                  height: 1.15,
                                ),
                              ),
                            ),
                            if (widget.post.visibility == 'network') ...[
                              const SizedBox(width: 6),
                              const Icon(TablerIcons.world,
                                  size: 13,
                                  color: AppColors.accentBlue),
                            ],
                            if (_isPinned) ...[
                              const SizedBox(width: 6),
                              const Icon(TablerIcons.pinned_filled,
                                  size: 13, color: AppColors.accent),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_prettyRole(widget.post.author.role)} • ${_formatTime(widget.post.createdAt)}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: GoogleFonts.dmSans(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasBusinessDetails) ...[
                    const SizedBox(width: 6),
                    _typePill(isLead: isLead),
                  ],
                  _menuButton(canDelete: canDelete),
                ],
              ),
            ),

            // Business details (Lead / RFP)
            if (hasBusinessDetails) _buildBusinessDetails(isLead: isLead),

            // Content
            if (widget.post.content.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: Text(
                  widget.post.content,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.text,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),
              ),

            // Image
            if (widget.post.imageUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: Image.network(
                      widget.post.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

            // Action bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
              child: Row(
                children: [
                  _actionButton(
                    icon: _isLiked
                        ? TablerIcons.heart_filled
                        : TablerIcons.heart,
                    label: '$_likesCount',
                    tint: _isLiked ? AppColors.error : AppColors.textSecondary,
                    onTap: _toggleLike,
                  ),
                  _actionButton(
                    icon: TablerIcons.message_circle,
                    label: '$_commentsCount',
                    tint: AppColors.textSecondary,
                    onTap: _showComments,
                  ),
                  if (hasBusinessDetails &&
                      context.read<AuthProvider>().user?.id ==
                          widget.post.author.id)
                    _actionButton(
                      icon: TablerIcons.adjustments,
                      label: 'MANAGE',
                      tint: AppColors.accent,
                      onTap: _showLeadManagementSheet,
                    ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header helpers ────────────────────────────────────────
  Widget _goldRingedAvatar() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: AppColors.goldSoftGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CachedAvatar(
        imageUrl: widget.post.author.profilePhoto,
        initials: widget.post.author.fullName.isNotEmpty
            ? widget.post.author.fullName.substring(0, 1).toUpperCase()
            : '?',
        size: 38,
        backgroundColor: AppColors.surface,
        textColor: AppColors.primary,
        fontSize: 14,
      ),
    );
  }

  Widget _typePill({required bool isLead}) {
    final tint = isLead ? AppColors.accent : AppColors.accentBlue;
    final label = isLead ? 'LEAD' : 'RFP';
    final icon = isLead ? TablerIcons.flame : TablerIcons.clipboard_list;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: tint.withValues(alpha: 0.32), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: tint),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: tint,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuButton({required bool canDelete}) {
    return PopupMenuButton<String>(
      tooltip: '',
      icon: const Icon(TablerIcons.dots_vertical,
          size: 18, color: AppColors.textMuted),
      color: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      onSelected: (v) {
        if (v == 'pin') _togglePin();
        if (v == 'delete') _showDeleteDialog();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'pin',
          child: Row(
            children: [
              Icon(
                _isPinned ? TablerIcons.pinned_off : TablerIcons.pin,
                size: 16,
                color: AppColors.accent,
              ),
              const SizedBox(width: 10),
              Text(
                _isPinned ? 'Unpin Post' : 'Pin to Top',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
        if (canDelete)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(TablerIcons.trash,
                    size: 16, color: AppColors.error),
                const SizedBox(width: 10),
                Text(
                  'Delete Post',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Business details (Lead/RFP) ───────────────────────────
  Widget _buildBusinessDetails({required bool isLead}) {
    final tint = isLead ? AppColors.accent : AppColors.accentBlue;
    final status = (widget.post.leadStatus ?? 'open');
    final statusInfo = _statusInfo(status);

    final rows = <Widget>[];

    if (widget.post.budgetRange != null &&
        widget.post.budgetRange!.isNotEmpty) {
      rows.add(_detailRow(
        icon: TablerIcons.coin,
        tint: AppColors.accent,
        label: 'BUDGET',
        value: widget.post.budgetRange!,
      ));
    }
    if (widget.post.deadline != null) {
      rows.add(_detailRow(
        icon: TablerIcons.calendar_event,
        tint: AppColors.accentBlue,
        label: 'DEADLINE',
        value: DateFormat('MMM d, yyyy').format(widget.post.deadline!),
      ));
    }
    if (widget.post.targetIndustryName != null) {
      rows.add(_detailRow(
        icon: TablerIcons.briefcase,
        tint: AppColors.accentBlue,
        label: 'INDUSTRY',
        value: widget.post.targetIndustryName!,
      ));
    }
    if (widget.post.targetClubName != null) {
      rows.add(_detailRow(
        icon: TablerIcons.users_group,
        tint: AppColors.accent,
        label: 'CLUB',
        value: widget.post.targetClubName!,
      ));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tint.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status pill at the top of the details
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo.tint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: statusInfo.tint.withValues(alpha: 0.32),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusInfo.tint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusInfo.label,
                        style: GoogleFonts.dmSans(
                          color: statusInfo.tint,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.post.businessValue != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: AppColors.goldGradient),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(TablerIcons.trophy,
                            size: 10, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'LKR ${NumberFormat('#,##0').format(widget.post.businessValue!)}',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (rows.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...rows,
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required Color tint,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  tint.withValues(alpha: 0.18),
                  tint.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tint.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, size: 12, color: tint),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: AppColors.textMuted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  _StatusInfo _statusInfo(String status) {
    switch (status) {
      case 'in_progress':
        return _StatusInfo('IN PROGRESS', AppColors.warning);
      case 'closed_won':
        return _StatusInfo('CLOSED WON', AppColors.success);
      case 'closed_lost':
        return _StatusInfo('CLOSED LOST', AppColors.textMuted);
      case 'open':
      default:
        return _StatusInfo('OPEN', AppColors.accentBlue);
    }
  }

  // ── Action bar button ────────────────────────────────────
  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color tint,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        splashColor: tint.withValues(alpha: 0.06),
        highlightColor: tint.withValues(alpha: 0.04),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: tint, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: tint,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
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
  // LEAD MANAGEMENT SHEET (preserved — already palette-aligned)
  // ──────────────────────────────────────────────────────────
  void _showLeadManagementSheet() {
    showPbnBottomSheet(
      context,
      builder: (_) => PbnBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                  'Manage Opportunity',
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
            const SizedBox(height: 14),
            _statusItem(
                label: 'Open',
                status: 'open',
                icon: TablerIcons.circle,
                tint: AppColors.accentBlue),
            const SizedBox(height: 10),
            _statusItem(
                label: 'In Progress',
                status: 'in_progress',
                icon: TablerIcons.player_play,
                tint: AppColors.warning),
            const SizedBox(height: 10),
            _statusItem(
                label: 'Closed Won (TYFB)',
                status: 'closed_won',
                icon: TablerIcons.trophy,
                tint: AppColors.success),
            const SizedBox(height: 10),
            _statusItem(
                label: 'Closed Lost',
                status: 'closed_lost',
                icon: TablerIcons.x,
                tint: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _statusItem({
    required String label,
    required String status,
    required IconData icon,
    required Color tint,
  }) {
    final isCurrent = widget.post.leadStatus == status;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        splashColor: tint.withValues(alpha: 0.06),
        highlightColor: tint.withValues(alpha: 0.04),
        onTap: () async {
          Navigator.pop(context);
          if (status == 'closed_won') {
            _showTYFBDialog();
          } else {
            try {
              await _service.updateLeadStatus(widget.post.id, status);
              widget.onRefresh();
            } catch (_) {}
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.surfaceGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrent
                  ? tint.withValues(alpha: 0.40)
                  : AppColors.border.withValues(alpha: 0.6),
              width: isCurrent ? 1.4 : 1,
            ),
            boxShadow: AppColors.shadowSm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tint.withValues(alpha: 0.18),
                      tint.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: tint.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, size: 18, color: tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.text,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                        color: tint.withValues(alpha: 0.32), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(TablerIcons.check, size: 10, color: tint),
                      const SizedBox(width: 4),
                      Text(
                        'CURRENT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: tint,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // TYFB DIALOG — palette-aligned premium dialog (was raw)
  // ──────────────────────────────────────────────────────────
  void _showTYFBDialog() {
    final controller = TextEditingController();
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppColors.shadowLg,
              border:
                  Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Navy header with gold trophy
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(22)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: AppColors.goldGradient),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent
                                  .withValues(alpha: 0.40),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(TablerIcons.trophy,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Record Business Success',
                        style: GoogleFonts.dmSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Thank You For Business',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Body
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Congratulations! How much business was '
                        'closed on this opportunity?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.accent
                                .withValues(alpha: 0.30),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textMuted,
                            ),
                            prefixText: 'LKR  ',
                            prefixStyle: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.accent,
                              letterSpacing: 0.4,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _dialogGhostButton(
                          label: 'CANCEL',
                          onTap: submitting
                              ? null
                              : () => Navigator.pop(ctx),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _dialogGoldButton(
                          label: submitting
                              ? 'RECORDING…'
                              : 'RECORD & CLOSE',
                          icon: TablerIcons.discount_check,
                          onTap: submitting
                              ? null
                              : () async {
                                  final val = double.tryParse(
                                          controller.text) ??
                                      0;
                                  if (val <= 0) return;
                                  // Capture the messenger before any
                                  // await so we don't reach across the
                                  // gap with the outer `context`.
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  final navigator = Navigator.of(ctx);
                                  setLocal(() => submitting = true);
                                  try {
                                    await _service.recordTYFB(
                                        widget.post.id, val);
                                    widget.onRefresh();
                                    if (!mounted) return;
                                    navigator.pop();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Thank You For Business recorded! '
                                          'Network ROI updated.',
                                          style: GoogleFonts.dmSans(
                                            color: Colors.white,
                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                        ),
                                        backgroundColor:
                                            AppColors.success,
                                        behavior:
                                            SnackBarBehavior.floating,
                                      ),
                                    );
                                  } catch (_) {
                                    if (!mounted) return;
                                    setLocal(() =>
                                        submitting = false);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // DELETE DIALOG — palette-aligned destructive confirmation
  // ──────────────────────────────────────────────────────────
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border:
                Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            boxShadow: AppColors.shadowLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.28)),
                ),
                child: const Icon(TablerIcons.trash,
                    color: AppColors.error, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                'Delete this post?',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _dialogGhostButton(
                      label: 'CANCEL',
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          Navigator.pop(ctx);
                          try {
                            await _service.deletePost(widget.post.id);
                            widget.onRefresh();
                          } catch (_) {}
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error
                                    .withValues(alpha: 0.30),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Icon(TablerIcons.trash,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'DELETE',
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogGhostButton({
    required String label,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.7),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogGoldButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(colors: AppColors.goldGradient)
                : LinearGradient(colors: [
                    AppColors.textMuted.withValues(alpha: 0.5),
                    AppColors.textMuted.withValues(alpha: 0.3),
                  ]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // COMMENTS — preserves existing redesigned sheet
  // ──────────────────────────────────────────────────────────
  void _showComments() {
    showPbnBottomSheet(
      context,
      builder: (_) => _CommentSheet(
        post: widget.post,
        service: _service,
        onCommentAdded: () {
          if (mounted) setState(() => _commentsCount++);
        },
      ),
    ).then((_) => widget.onRefresh());
  }
}

class _StatusInfo {
  final String label;
  final Color tint;
  _StatusInfo(this.label, this.tint);
}

// ──────────────────────────────────────────────────────────────
// Helpers shared by the post card
// ──────────────────────────────────────────────────────────────
String _prettyRole(String role) {
  if (role.isEmpty) return '';
  return role
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty
          ? w
          : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

String _formatTime(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d').format(date);
}

// ──────────────────────────────────────────────────────────────
// COMMENT SHEET — preserved from prior redesign
// ──────────────────────────────────────────────────────────────
class _CommentSheet extends StatefulWidget {
  final CommunityPost post;
  final CommunityService service;
  final VoidCallback onCommentAdded;
  const _CommentSheet(
      {required this.post,
      required this.service,
      required this.onCommentAdded});

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final _commentController = TextEditingController();
  List<PostComment> _comments = [];
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await widget.service.getComments(widget.post.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _submitting) return;

    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    final tempId =
        DateTime.now().millisecondsSinceEpoch.toString();
    final optimisticComment = PostComment(
      id: tempId,
      postId: widget.post.id,
      content: text,
      createdAt: DateTime.now(),
      author: PostAuthor(
        id: auth.user!.id.toString(),
        fullName: auth.user!.fullName,
        profilePhoto: auth.user!.profilePhoto,
        role: auth.user!.role,
      ),
    );

    setState(() {
      _comments.insert(0, optimisticComment);
      _commentController.clear();
      _submitting = true;
    });

    try {
      await widget.service.addComment(widget.post.id, text);
      widget.onCommentAdded();
      await _loadComments();
    } catch (_) {
      if (mounted) {
        setState(() {
          _comments.removeWhere((c) => c.id == tempId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to post comment. Please try again.')),
          );
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PbnBottomSheet(
      scrollable: false,
      maxHeightFraction: 0.88,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
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
                  'Comments',
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
          ),
          Container(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : _comments.isEmpty
                    ? Center(
                        child: Text(
                          'No comments yet',
                          style: GoogleFonts.dmSans(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        itemCount: _comments.length,
                        itemBuilder: (context, i) =>
                            _buildCommentItem(_comments[i]),
                      ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment…',
                      hintStyle: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: null,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _submitting ? null : _submitComment,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: AppColors.goldGradient),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.accent.withValues(alpha: 0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _submitting ? TablerIcons.loader : TablerIcons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(PostComment comment) {
    final auth = context.read<AuthProvider>();
    final canDelete = auth.user?.id == comment.author.id ||
        auth.user?.role == 'SUPER_ADMIN';

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedAvatar(
            imageUrl: comment.author.profilePhoto,
            initials: comment.author.fullName.isNotEmpty
                ? comment.author.fullName.substring(0, 1).toUpperCase()
                : '?',
            size: 32,
            fontSize: 11,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        comment.author.fullName,
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatTime(comment.createdAt),
                      style: GoogleFonts.dmSans(
                        fontSize: 9.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              icon: const Icon(TablerIcons.trash,
                  size: 13, color: AppColors.textMuted),
              onPressed: () async {
                try {
                  await widget.service.deleteComment(comment.id);
                  _loadComments();
                } catch (_) {}
              },
            ),
        ],
      ),
    );
  }
}
