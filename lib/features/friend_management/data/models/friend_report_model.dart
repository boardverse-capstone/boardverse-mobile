import '../../domain/entities/entities.dart';
import 'enum_parsing.dart';

/// Model cho [FriendReportEntity] — báo cáo vi phạm của current user.
class FriendReportModel {
  const FriendReportModel({
    required this.reportId,
    required this.targetUserId,
    required this.targetUsername,
    required this.category,
    required this.reason,
    required this.createdAt,
    required this.status,
  });

  final String reportId;
  final String targetUserId;
  final String targetUsername;
  final String category;
  final String reason;
  final DateTime createdAt;
  final String status;

  factory FriendReportModel.fromJson(Map<String, dynamic> json) {
    return FriendReportModel(
      reportId: (json['reportId'] ?? json['id'] ?? '').toString(),
      targetUserId: (json['targetUserId'] ?? '').toString(),
      targetUsername:
          (json['targetUsername'] ?? json['targetUser']?['username'] ?? '')
              .toString(),
      category: (json['category'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
      status: (json['status'] ?? 'pending').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetUserId': targetUserId,
      'category': category,
      'reason': reason,
    };
  }

  FriendReportEntity toEntity() => FriendReportEntity(
        reportId: reportId,
        targetUserId: targetUserId,
        targetUsername: targetUsername,
        category: _parseCategory(category),
        reason: reason,
        createdAt: createdAt,
        status: status,
      );

  /// Parse [FriendReportCategory]. Backend trả các giá trị (theo friend.md):
  /// `Spam` / `Harassment` / `FakeAccount` / `InappropriateContent` / `Other`.
  static FriendReportCategory _parseCategory(String value) {
    return parseEnum<FriendReportCategory>(
      FriendReportCategory.values,
      value,
      fallback: FriendReportCategory.other,
      aliases: const {
        'spam': FriendReportCategory.spam,
        'harassment': FriendReportCategory.harassment,
        'fakeaccount': FriendReportCategory.fakeAccount,
        'inappropriatecontent': FriendReportCategory.inappropriateContent,
        'inappropriate': FriendReportCategory.inappropriateContent,
        'cheating': FriendReportCategory.cheating,
        'other': FriendReportCategory.other,
      },
    );
  }
}
