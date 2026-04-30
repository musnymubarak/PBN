import 'dart:convert';

class CommunityPost {
  final String id;
  final String chapterId;
  final String content;
  final String? imageUrl;
  final bool isPinned;
  final DateTime createdAt;
  final PostAuthor author;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByMe;

  // Phase 2 Economic Engine fields
  final String postType; // general, lead, rfp
  final String visibility; // chapter, network, club
  final String? leadStatus; // open, in_progress, closed_won, closed_lost
  final String? budgetRange;
  final DateTime? deadline;
  final String? targetClubId;
  final String? targetClubName;
  final String? targetIndustryId;
  final String? targetIndustryName;
  final double? businessValue;

  CommunityPost({
    required this.id,
    required this.chapterId,
    required this.content,
    this.imageUrl,
    required this.isPinned,
    required this.createdAt,
    required this.author,
    required this.likesCount,
    required this.commentsCount,
    required this.isLikedByMe,
    this.postType = 'general',
    this.visibility = 'chapter',
    this.leadStatus,
    this.budgetRange,
    this.deadline,
    this.targetClubId,
    this.targetClubName,
    this.targetIndustryId,
    this.targetIndustryName,
    this.businessValue,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'],
      chapterId: json['chapter_id'],
      content: json['content'],
      imageUrl: json['image_url'],
      isPinned: json['is_pinned'],
      createdAt: DateTime.parse(json['created_at']),
      author: PostAuthor.fromJson(json['author']),
      likesCount: json['likes_count'],
      commentsCount: json['comments_count'],
      isLikedByMe: json['is_liked_by_me'],
      postType: json['post_type'] ?? 'general',
      visibility: json['visibility'] ?? 'chapter',
      leadStatus: json['lead_status'],
      budgetRange: json['budget_range'],
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      targetClubId: json['target_club_id'],
      targetClubName: json['target_club_name'],
      targetIndustryId: json['target_industry_id'],
      targetIndustryName: json['target_industry_name'],
      businessValue: json['business_value'] != null ? (json['business_value'] as num).toDouble() : null,
    );
  }
}

class PostAuthor {
  final String id;
  final String fullName;
  final String? profilePhoto;
  final String role;

  PostAuthor({
    required this.id,
    required this.fullName,
    this.profilePhoto,
    required this.role,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id'],
      fullName: json['full_name'],
      profilePhoto: json['profile_photo'],
      role: json['role'],
    );
  }
}

class PostComment {
  final String id;
  final String postId;
  final String content;
  final DateTime createdAt;
  final PostAuthor author;

  PostComment({
    required this.id,
    required this.postId,
    required this.content,
    required this.createdAt,
    required this.author,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'],
      postId: json['post_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      author: PostAuthor.fromJson(json['author']),
    );
  }
}
