import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/constants/api_config.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/services/community_service.dart';
import 'package:pbn/models/community.dart';
import 'package:pbn/features/community/create_post_page.dart';
import 'package:pbn/core/services/push_notification_service.dart';

import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> with WidgetsBindingObserver {
  final _service = CommunityService();
  final _searchController = TextEditingController();
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
    _debounce?.cancel();
    super.dispose();
  }

  void _listenToNotifications() {
    _notifSubscription = PushNotificationService.onMessageStream.listen((message) {
      final type = message.data['type']?.toString().toLowerCase();
      final notificationType = message.data['notification_type']?.toString().toLowerCase();
      
      // Matches both the 'type' field and the 'notification_type' sent by backend
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
    _liveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
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
      setState(() {
        _searchQuery = query;
      });
      _loadFeed();
    });
  }

  Future<void> _loadFeed({bool isSilent = false}) async {
    if (isSilent) debugPrint('COMMUNITY_SYNC: Background silent refresh started at ${DateTime.now()}');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 120,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('Chapter Feed',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        letterSpacing: -0.5)),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: 4)],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Scope Toggle
            Container(
              height: 40,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildScopeTab('My Chapter', false),
                  _buildScopeTab('Network', true),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 50),
            child: PbnAppBarActions(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildErrorState()
                    : RefreshIndicator(
                        onRefresh: _loadFeed,
                        color: AppColors.primary,
                        child: _posts.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                itemCount: _posts.length,
                                itemBuilder: (context, i) => _PostCard(
                                  post: _posts[i],
                                  onRefresh: _loadFeed,
                                ),
                              ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostPage()),
          ).then((result) {
            if (result is CommunityPost) {
              setState(() {
                _posts.insert(0, result);
              });
            } else if (result == true) {
              _loadFeed();
            }
          });
        },
        backgroundColor: AppColors.primary,
        child: const Icon(TablerIcons.square_plus, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search posts...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w600),
                prefixIcon: const Icon(TablerIcons.search, color: AppColors.primary, size: 20),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(TablerIcons.x, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Posts', 'all', TablerIcons.layout_list),
                const SizedBox(width: 8),
                _buildFilterChip('Leads', 'lead', TablerIcons.flame),
                const SizedBox(width: 8),
                _buildFilterChip('RFPs', 'rfp', TablerIcons.clipboard_list),
                const SizedBox(width: 8),
                _buildFilterChip('My Posts', 'my_posts', TablerIcons.user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeTab(String label, bool isNetwork) {
    final isSelected = _networkWide == isNetwork;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _networkWide = isNetwork;
            _activeFilter = 'all'; // Reset filter when switching scope
          });
          _loadFeed();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.primary : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _activeFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = value;
        });
        _loadFeed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(label, 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w700, 
                color: isSelected ? Colors.white : Colors.grey.shade600
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'Be the first to post something!';
    IconData icon = TablerIcons.messages;

    if (_searchQuery.isNotEmpty) {
      message = 'No results found for "$_searchQuery"';
      icon = TablerIcons.search_off;
    } else if (_activeFilter == 'pinned') {
      message = 'No pinned posts yet';
      icon = TablerIcons.pin;
    } else if (_activeFilter == 'my_posts') {
      message = 'You haven\'t posted anything yet';
      icon = TablerIcons.user_minus;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 32),
          if (_searchQuery.isEmpty && _activeFilter == 'all')
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostPage())).then((v) {
                if (v == true) _loadFeed();
              }),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('New Post', style: TextStyle(color: Colors.white)),
            )
          else
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _activeFilter = 'all';
                });
                _loadFeed();
              },
              icon: const Icon(TablerIcons.refresh, size: 18),
              label: const Text('Clear Filters', style: TextStyle(fontWeight: FontWeight.w800)),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(TablerIcons.alert_triangle, size: 48, color: Colors.amber.shade300),
          const SizedBox(height: 16),
          Text(_error ?? 'An unexpected error occurred', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadFeed,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('RETRY', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

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
      if (!_pinning) {
        _isPinned = widget.post.isPinned;
      }
      // Only sync comment count if not currently in comments sheet or if data changed
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
          // Rollback on error
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
          _isPinned = !_isPinned; // Rollback
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

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: hasBusinessDetails 
          ? Border(left: BorderSide(color: isLead ? Colors.amber.shade600 : Colors.blue.shade600, width: 4))
          : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildAvatar(widget.post.author),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.post.author.fullName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.text),
                            ),
                          ),
                          if (widget.post.visibility == 'network') ...[
                            const SizedBox(width: 6),
                            const Icon(TablerIcons.world, size: 14, color: Colors.blue),
                          ],
                        ],
                      ),
                      Text(
                        '${widget.post.author.role.toUpperCase()} • ${_formatTime(widget.post.createdAt)}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                if (hasBusinessDetails)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isLead ? Colors.amber : Colors.blue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.post.postType.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isLead ? Colors.amber.shade800 : Colors.blue.shade800),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    _isPinned ? TablerIcons.pinned : TablerIcons.pin, 
                    size: 18, 
                    color: _isPinned ? AppColors.primary : Colors.grey.shade400
                  ),
                  onPressed: _togglePin,
                ),
                if (canDelete)
                  IconButton(
                    icon: Icon(TablerIcons.trash, size: 18, color: Colors.grey.shade400),
                    onPressed: _showDeleteDialog,
                  ),
              ],
            ),
          ),

          // Business Details Section (If Lead/RFP)
          if (hasBusinessDetails)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (widget.post.budgetRange != null && widget.post.budgetRange!.isNotEmpty)
                    _buildDetailRow(TablerIcons.coin, 'Budget', widget.post.budgetRange!),
                  if (widget.post.deadline != null)
                    _buildDetailRow(TablerIcons.calendar_event, 'Deadline', DateFormat('MMM dd, yyyy').format(widget.post.deadline!)),
                  if (widget.post.targetIndustryName != null)
                    _buildDetailRow(TablerIcons.briefcase, 'Industry', widget.post.targetIndustryName!),
                  if (widget.post.targetClubName != null)
                    _buildDetailRow(TablerIcons.users_group, 'Club', widget.post.targetClubName!),
                  _buildDetailRow(TablerIcons.target, 'Status', (widget.post.leadStatus ?? 'OPEN').replaceAll('_', ' ').toUpperCase()),
                ],
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              widget.post.content,
              style: const TextStyle(fontSize: 14, color: AppColors.text, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ),

          // Image (if any)
          if (widget.post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(0)),
                child: Image.network(
                  widget.post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),

          // Actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                _buildActionButton(
                  icon: _isLiked ? TablerIcons.heart_filled : TablerIcons.heart,
                  label: '$_likesCount',
                  color: _isLiked ? Colors.redAccent : Colors.grey.shade600,
                  onTap: _toggleLike,
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: TablerIcons.message_circle,
                  label: '$_commentsCount',
                  color: Colors.grey.shade600,
                  onTap: _showComments,
                ),
                if ((widget.post.postType == 'lead' || widget.post.postType == 'rfp') && 
                    context.read<AuthProvider>().user?.id == widget.post.author.id) ...[
                  const SizedBox(width: 24),
                  _buildActionButton(
                    icon: TablerIcons.adjustments,
                    label: 'MANAGE',
                    color: AppColors.primary,
                    onTap: _showLeadManagementSheet,
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLeadManagementSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manage Opportunity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            _buildStatusItem('Open', 'open', TablerIcons.circle),
            _buildStatusItem('In Progress', 'in_progress', TablerIcons.player_play),
            _buildStatusItem('Closed Won (TYFB)', 'closed_won', TablerIcons.trophy),
            _buildStatusItem('Closed Lost', 'closed_lost', TablerIcons.x),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String status, IconData icon) {
    final isCurrent = widget.post.leadStatus == status;
    return ListTile(
      leading: Icon(icon, color: isCurrent ? AppColors.primary : Colors.grey),
      title: Text(label, style: TextStyle(fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600, color: isCurrent ? AppColors.primary : AppColors.text)),
      trailing: isCurrent ? const Icon(TablerIcons.check, color: AppColors.primary) : null,
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
    );
  }

  void _showTYFBDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Business Success'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Congratulations! How much business was closed? (LKR)'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Enter amount', prefixText: 'LKR '),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text) ?? 0;
              if (val > 0) {
                Navigator.pop(context);
                try {
                  await _service.recordTYFB(widget.post.id, val);
                  widget.onRefresh();
                  // Show celebration
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🎉 Thank You For Business recorded! Network ROI updated.')),
                    );
                  }
                } catch (_) {}
              }
            },
            child: const Text('RECORD & CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(PostAuthor author) {
    final hasPhoto = author.profilePhoto != null && author.profilePhoto!.isNotEmpty;
    final imageUrl = hasPhoto ? '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}${author.profilePhoto}' : '';
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.1),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
        image: hasPhoto ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
      ),
      child: hasPhoto ? null : Center(
        child: Text(author.fullName.substring(0, 1).toUpperCase(), 
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Text('$label:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
          const SizedBox(width: 4),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.text))),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(date);
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to remove this post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _service.deletePost(widget.post.id);
                widget.onRefresh();
              } catch (_) {}
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

class _CommentSheet extends StatefulWidget {
  final CommunityPost post;
  final CommunityService service;
  final VoidCallback onCommentAdded;
  const _CommentSheet({required this.post, required this.service, required this.onCommentAdded});

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
      if (mounted) setState(() { _comments = comments; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _submitting) return;

    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    // Create Optimistic Comment
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
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
      _comments.insert(0, optimisticComment); // Show at top
      _commentController.clear();
      _submitting = true;
    });

    try {
      await widget.service.addComment(widget.post.id, text);
      widget.onCommentAdded();
      // Wait a bit then refresh to get the real ID from server
      await _loadComments();
    } catch (_) {
      // Rollback on failure
      if (mounted) {
        setState(() {
          _comments.removeWhere((c) => c.id == tempId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to post comment. Please try again.')),
          );
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          ),
          const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text)),
          const SizedBox(height: 20),

          // Comments List
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator()) 
              : _comments.isEmpty 
                  ? Center(child: Text('No comments yet', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w700)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _comments.length,
                      itemBuilder: (context, i) => _buildCommentItem(_comments[i]),
                    ),
          ),

          // Input
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      filled: true, fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    maxLines: null,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _submitComment,
                  icon: Icon(_submitting ? TablerIcons.loader : TablerIcons.send, color: AppColors.primary),
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
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTinyAvatar(comment.author),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(comment.author.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.text)),
                    Text(_formatTime(comment.createdAt), style: TextStyle(fontSize: 9, color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (canDelete)
            IconButton(icon: Icon(TablerIcons.trash, size: 14, color: Colors.grey.shade300), onPressed: () async {
              try {
                await widget.service.deleteComment(comment.id);
                _loadComments();
              } catch (_) {}
            }),
        ],
      ),
    );
  }

  Widget _buildTinyAvatar(PostAuthor author) {
    final hasPhoto = author.profilePhoto != null && author.profilePhoto!.isNotEmpty;
    final imageUrl = hasPhoto ? '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}${author.profilePhoto}' : '';
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(0.05), image: hasPhoto ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null),
      child: hasPhoto ? null : Center(child: Text(author.fullName.substring(0, 1).toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900))),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return DateFormat('MMM d').format(date);
  }
}
