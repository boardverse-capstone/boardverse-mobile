import 'package:equatable/equatable.dart';

/// Entity cho tin nhắn chat trong lobby.
///
/// Backend trả response từ GET /api/v1/lobbies/{lobbyId}/messages với format:
///
/// ```json
/// {
///   "id": "uuid",
///   "lobbyId": "uuid",
///   "senderId": "uuid|null",        // null nếu là system message
///   "senderName": "string",          // "Hệ thống" cho system message
///   "senderAvatarUrl": "string|null",
///   "content": "string",
///   "isSystem": bool,                 // true cho system-generated messages
///   "createdAt": "ISO 8601 datetime"
/// }
/// ```
///
/// **Lưu ý:** Backend dùng field `senderName` (không phải `senderUsername`).
/// Từ 2026-07-29 có thêm field `isSystem` để phân biệt system messages (vd:
/// "Phòng chờ đã được tạo.") với user messages — UI render style khác nhau.
class LobbyChatMessage extends Equatable {
  final String id;
  final String lobbyId;

  /// Nullable vì system messages có senderId = null.
  final String? senderId;
  final String senderName;

  /// Backward-compatible: hỗ trợ cả `senderUsername` (cũ) và `senderName` (mới).
  String get senderUsername => senderName;

  final String? senderAvatarUrl;
  final String content;

  /// True nếu là system-generated message (host cancel, lobby created, v.v...).
  /// Khi đó `senderId` = null và UI nên render khác (center, italics, màu nhạt).
  final bool isSystem;
  final DateTime createdAt;

  const LobbyChatMessage({
    required this.id,
    required this.lobbyId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.content,
    this.isSystem = false,
    required this.createdAt,
  });

  factory LobbyChatMessage.fromJson(Map<String, dynamic> json) {
    // Backend trả `senderName` cho cả user lẫn system message.
    // Một số version cũ dùng `senderUsername` — fallback để tránh lỗi.
    final rawName = json['senderName'] ?? json['senderUsername'];
    final resolvedName = rawName?.toString().trim();

    return LobbyChatMessage(
      id: json['id']?.toString() ?? '',
      lobbyId: json['lobbyId']?.toString() ?? '',
      senderId: json['senderId']?.toString().isEmpty ?? true
          ? null
          : json['senderId'].toString(),
      senderName: (resolvedName == null || resolvedName.isEmpty)
          ? 'Unknown'
          : resolvedName,
      senderAvatarUrl: json['senderAvatarUrl']?.toString(),
      content: json['content']?.toString() ?? '',
      isSystem: json['isSystem'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        lobbyId,
        senderId,
        senderName,
        senderAvatarUrl,
        content,
        isSystem,
        createdAt,
      ];
}

/// Request model để gửi tin nhắn.
class SendChatMessageRequest extends Equatable {
  final String content;

  const SendChatMessageRequest({required this.content});

  Map<String, dynamic> toJson() => {'content': content};

  @override
  List<Object?> get props => [content];
}
