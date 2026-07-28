/// Format `DateTime` thành chuỗi "X ngày/giờ/phút trước" theo tiếng Việt.
///
/// Dùng cho FriendRequestCard, _SentRequestTile, và các nơi cần hiển thị
/// thời gian tương đối. Hàm pure (không phụ thuộc context) nên test dễ.
String formatTimeAgo(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inDays > 0) return '${diff.inDays} ngày trước';
  if (diff.inHours > 0) return '${diff.inHours} giờ trước';
  if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
  return 'Vừa xong';
}
