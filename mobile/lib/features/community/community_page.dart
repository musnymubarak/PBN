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

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final _service = CommunityService();
  List<CommunityPost> _posts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await _service.getFeed();
      if (mounted) {
        setState(() {
          _posts = posts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
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
        toolbarHeight: 70,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('COMMUNITY HUB',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                    letterSpacing: 2)),
            const Text('Chapter Feed',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text)),
          ],
        ),
      ),
      body: _loading
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostPage()),
          ).then((value) {
            if (value == true) _loadFeed();
          });
        },
        backgroundColor: AppColors.primary,
        child: const Icon(TablerIcons.square_plus, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(TablerIcons.messages, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Be the first to post something!',
            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostPage())).then((v) {
              if (v == true) _loadFeed();
            }),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('New Post', style: TextStyle(color: Colors.white)),
          )
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
          Text(_error!, style: const TextStyle(fontWeight: FontWeight.w700)),
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
  bool _liking = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByMe;
    _likesCount = widget.post.likesCount;
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

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final canDelete = auth.user?.id == widget.post.author.id || 
                      auth.user?.role == 'SUPER_ADMIN' || 
                      auth.user?.role == 'CHAPTER_ADMIN';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                      Text(widget.post.author.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.text)),
                      Text(
                        '${widget.post.author.role.toUpperCase()} • ${_formatTime(widget.post.createdAt)}',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                if (canDelete)
                  IconButton(
                    icon: Icon(TablerIcons.trash, size: 18, color: Colors.grey.shade400),
                    onPressed: _showDeleteDialog,
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  label: '${widget.post.commentsCount}',
                  color: Colors.grey.shade600,
                  onTap: _showComments,
                ),
                const Spacer(),
                if (widget.post.isPinned)
                  Icon(TablerIcons.pin, size: 16, color: AppColors.primary.withOpacity(0.5)),
              ],
            ),
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
      builder: (_) => _CommentSheet(post: widget.post, service: _service),
    ).then((_) => widget.onRefresh());
  }
}

class _CommentSheet extends StatefulWidget {
  final CommunityPost post;
  final CommunityService service;
  const _CommentSheet({required this.post, required this.service});

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

    setState(() => _submitting = true);
    try {
      await widget.service.addComment(widget.post.id, text);
      _commentController.clear();
      _loadComments();
    } catch (_) {}
    if (mounted) setState(() => _submitting = false);
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
