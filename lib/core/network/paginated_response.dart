/// Generic paginated response wrapper cho list APIs.
///
/// Backend CÓ THỂ trả về một trong 2 envelopes tùy endpoint:
/// 1. `totalItems` + `totalPages` + `hasNextPage` + `hasPreviousPage`
///    (chuẩn chung).
/// 2. `totalCount` + `totalPages` (chuẩn ASP.NET Core dùng cho nhiều
///    endpoint, vd: `GET /api/v1/reservations/search`).
///
/// `fromJson` hỗ trợ cả 2 để call site không phải viết 2 parser.
/// ```json
/// {
///   "items": [...],
///   "page": 1,
///   "pageSize": 10,
///   "totalItems": 100,
///   "totalPages": 10,
///   "hasNextPage": true,
///   "hasPreviousPage": false
/// }
/// ```
class PaginatedResponse<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaginatedResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final items = (json['items'] as List<dynamic>?)
            ?.map((e) => fromJsonT(e as Map<String, dynamic>))
            .toList() ??
        [];

    final page = json['page'] as int? ?? 1;
    final pageSize = json['pageSize'] as int? ?? 10;

    // totalItems fallback từ totalCount (chuẩn ASP.NET Core /search).
    final totalItems =
        json['totalItems'] as int? ?? json['totalCount'] as int? ?? 0;

    // totalPages có thể không được backend trả về — tự tính.
    final totalPages = json['totalPages'] as int? ??
        (pageSize > 0 ? (totalItems / pageSize).ceil() : 0);

    final hasNextPage = json['hasNextPage'] as bool? ?? page < totalPages;
    final hasPreviousPage = json['hasPreviousPage'] as bool? ?? page > 1;

    return PaginatedResponse<T>(
      items: items,
      page: page,
      pageSize: pageSize,
      totalItems: totalItems,
      totalPages: totalPages,
      hasNextPage: hasNextPage,
      hasPreviousPage: hasPreviousPage,
    );
  }
}
