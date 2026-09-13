import 'package:equatable/equatable.dart';

import '../../domain/entities/entities.dart';

/// State cho `SearchReservationsCubit` — quản lý kết quả tìm kiếm
/// reservations.
///
/// Tự động chọn endpoint dựa trên query:
/// - Không có `gameName` và `fromDate/toDate` → `GET /api/v1/reservations`
/// - Có `gameName` hoặc `fromDate/toDate` → `GET /api/v1/reservations/search`
///
/// Tách riêng khỏi `ReservationListCubit` (chỉ list đơn giản) để:
/// - Lưu các filter đang active (gameName, fromDate, toDate, statuses, scope).
/// - Cho phép phân trang & infinite scroll.
/// - Cho phép reset / clear filter dễ dàng.
sealed class SearchReservationsState extends Equatable {
  const SearchReservationsState();

  @override
  List<Object?> get props => [];
}

class SearchReservationsInitial extends SearchReservationsState {
  const SearchReservationsInitial();
}

/// State loading — dùng cho cả initial load và load-more.
/// [isLoadMore] = true khi đây là pagination (giữ list cũ + spinner cuối).
class SearchReservationsLoading extends SearchReservationsState {
  final List<ReservationEntity> previousItems;
  final bool isLoadMore;

  const SearchReservationsLoading({
    this.previousItems = const [],
    this.isLoadMore = false,
  });

  @override
  List<Object?> get props => [previousItems, isLoadMore];
}

class SearchReservationsLoaded extends SearchReservationsState {
  /// Filter query hiện tại — lưu để UI có thể re-render chip filter,
  /// và để cubit biết còn page nào cần load.
  final ReservationSearchQuery query;

  final List<ReservationEntity> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final bool isLoadMore;

  const SearchReservationsLoaded({
    required this.query,
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    this.isLoadMore = false,
  });

  SearchReservationsLoaded copyWith({
    ReservationSearchQuery? query,
    List<ReservationEntity>? items,
    int? page,
    int? pageSize,
    int? totalItems,
    int? totalPages,
    bool? hasNextPage,
    bool? hasPreviousPage,
    bool? isLoadMore,
  }) {
    return SearchReservationsLoaded(
      query: query ?? this.query,
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalItems: totalItems ?? this.totalItems,
      totalPages: totalPages ?? this.totalPages,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      isLoadMore: isLoadMore ?? this.isLoadMore,
    );
  }

  @override
  List<Object?> get props => [
        query,
        items,
        page,
        pageSize,
        totalItems,
        totalPages,
        hasNextPage,
        hasPreviousPage,
        isLoadMore,
      ];
}

class SearchReservationsFailure extends SearchReservationsState {
  final String message;
  final List<ReservationEntity> previousItems;
  final ReservationSearchQuery? query;

  const SearchReservationsFailure({
    required this.message,
    this.previousItems = const [],
    this.query,
  });

  @override
  List<Object?> get props => [message, previousItems, query];
}

/// Filter params cho reservation list/search.
///
/// Tự động chọn endpoint:
/// - Không có [gameName] và [fromDate/toDate] → `GET /api/v1/reservations`
/// - Có [gameName] hoặc [fromDate/toDate] → `GET /api/v1/reservations/search`
///
/// Field nào null thì không truyền lên query string (server không filter
/// theo field đó).
///
/// `scope` điều khiển 2 flag `HostedByMe`/`JoinedByMe`:
/// - [SearchScope.all]: trả cả 2 (default — cả host + member).
/// - [SearchScope.hostedOnly]: chỉ reservation user host.
/// - [SearchScope.joinedOnly]: chỉ reservation user tham gia.
class ReservationSearchQuery extends Equatable {
  final String? gameName;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<String>? statuses;
  final String? cafeId;
  final SearchScope scope;

  const ReservationSearchQuery({
    this.gameName,
    this.fromDate,
    this.toDate,
    this.statuses,
    this.cafeId,
    this.scope = SearchScope.all,
  });

  /// Query rỗng — dùng cho initial load hoặc sau khi clear filter.
  static const ReservationSearchQuery empty = ReservationSearchQuery();

  /// Có filter nào đang active không (dùng để hiển thị chip "Đang lọc").
  bool get hasAnyFilter =>
      (gameName != null && gameName!.trim().isNotEmpty) ||
      fromDate != null ||
      toDate != null ||
      (statuses != null && statuses!.isNotEmpty) ||
      (cafeId != null && cafeId!.isNotEmpty) ||
      scope != SearchScope.all;

  /// True nếu không có filter text/date (chỉ có thể scope) — vẫn gọi
  /// API nhưng user sẽ thấy list đầy đủ. Dùng để quyết định có auto-search
  /// khi mở trang hay không.
  bool get isEffectivelyEmpty =>
      !hasAnyFilter || (gameName == null && fromDate == null && toDate == null);

  ReservationSearchQuery copyWith({
    String? gameName,
    DateTime? fromDate,
    DateTime? toDate,
    List<String>? statuses,
    String? cafeId,
    SearchScope? scope,
    bool clearGameName = false,
    bool clearFromDate = false,
    bool clearToDate = false,
    bool clearStatuses = false,
    bool clearCafeId = false,
  }) {
    return ReservationSearchQuery(
      gameName: clearGameName ? null : (gameName ?? this.gameName),
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
      statuses: clearStatuses ? null : (statuses ?? this.statuses),
      cafeId: clearCafeId ? null : (cafeId ?? this.cafeId),
      scope: scope ?? this.scope,
    );
  }

  @override
  List<Object?> get props => [gameName, fromDate, toDate, statuses, cafeId, scope];
}

/// Phạm vi tìm kiếm — map sang `HostedByMe`/`JoinedByMe` của backend.
enum SearchScope {
  all,
  hostedOnly,
  joinedOnly;

  bool? get hostedByMe => this == SearchScope.hostedOnly ? true : null;
  bool? get joinedByMe => this == SearchScope.joinedOnly ? true : null;
}
