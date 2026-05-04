import 'package:json_annotation/json_annotation.dart';

part 'matchmaking.g.dart';

@JsonSerializable()
class MatchingProfile {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'business_description')
  final String? businessDescription;
  @JsonKey(name: 'services_offered')
  final List<String> servicesOffered;
  @JsonKey(name: 'looking_for')
  final List<String> lookingFor;
  @JsonKey(name: 'target_sectors')
  final List<String> targetSectors;
  @JsonKey(name: 'matching_enabled')
  final bool matchingEnabled;

  MatchingProfile({
    required this.id,
    required this.userId,
    this.businessDescription,
    required this.servicesOffered,
    required this.lookingFor,
    required this.targetSectors,
    required this.matchingEnabled,
  });

  factory MatchingProfile.fromJson(Map<String, dynamic> json) => _$MatchingProfileFromJson(json);
  Map<String, dynamic> toJson() => _$MatchingProfileToJson(this);
}

@JsonSerializable()
class MatchSuggestion {
  final String id;
  @JsonKey(name: 'matched_user_id')
  final String matchedUserId;
  final double score;
  @JsonKey(name: 'score_breakdown')
  final Map<String, double> scoreBreakdown;
  final String? explanation;
  @JsonKey(name: 'partnership_strategy')
  final String? partnershipStrategy;
  final String status;
  
  @JsonKey(name: 'matched_user_name')
  final String? matchedUserName;
  @JsonKey(name: 'matched_user_photo')
  final String? matchedUserPhoto;
  @JsonKey(name: 'matched_user_industry')
  final String? matchedUserIndustry;

  MatchSuggestion({
    required this.id,
    required this.matchedUserId,
    required this.score,
    required this.scoreBreakdown,
    this.explanation,
    this.partnershipStrategy,
    required this.status,
    this.matchedUserName,
    this.matchedUserPhoto,
    this.matchedUserIndustry,
  });

  factory MatchSuggestion.fromJson(Map<String, dynamic> json) => _$MatchSuggestionFromJson(json);
  Map<String, dynamic> toJson() => _$MatchSuggestionToJson(this);
}
