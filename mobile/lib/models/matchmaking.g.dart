// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matchmaking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchingProfile _$MatchingProfileFromJson(Map<String, dynamic> json) =>
    MatchingProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessDescription: json['business_description'] as String?,
      servicesOffered: (json['services_offered'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      lookingFor: (json['looking_for'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      targetSectors: (json['target_sectors'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      matchingEnabled: json['matching_enabled'] as bool,
    );

Map<String, dynamic> _$MatchingProfileToJson(MatchingProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'business_description': instance.businessDescription,
      'services_offered': instance.servicesOffered,
      'looking_for': instance.lookingFor,
      'target_sectors': instance.targetSectors,
      'matching_enabled': instance.matchingEnabled,
    };

MatchSuggestion _$MatchSuggestionFromJson(Map<String, dynamic> json) =>
    MatchSuggestion(
      id: json['id'] as String,
      matchedUserId: json['matched_user_id'] as String,
      score: (json['score'] as num).toDouble(),
      scoreBreakdown: (json['score_breakdown'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      explanation: json['explanation'] as String?,
      partnershipStrategy: json['partnership_strategy'] as String?,
      status: json['status'] as String,
      matchedUserName: json['matched_user_name'] as String?,
      matchedUserPhoto: json['matched_user_photo'] as String?,
      matchedUserIndustry: json['matched_user_industry'] as String?,
    );

Map<String, dynamic> _$MatchSuggestionToJson(MatchSuggestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'matched_user_id': instance.matchedUserId,
      'score': instance.score,
      'score_breakdown': instance.scoreBreakdown,
      'explanation': instance.explanation,
      'partnership_strategy': instance.partnershipStrategy,
      'status': instance.status,
      'matched_user_name': instance.matchedUserName,
      'matched_user_photo': instance.matchedUserPhoto,
      'matched_user_industry': instance.matchedUserIndustry,
    };
