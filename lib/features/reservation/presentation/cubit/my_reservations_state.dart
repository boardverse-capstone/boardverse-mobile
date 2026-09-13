import 'package:equatable/equatable.dart';

import '../../domain/entities/entities.dart';

/// Trạng thái của `MyReservationsCubit` — quản lý danh sách reservation
/// của user (cả Host + Member) cho tab "Lịch đặt" trong `BookingsPage`.
///
/// Sử dụng endpoint `GET /api/v1/reservations/my` (mới thêm Sep 2026) — trả
/// về items kèm 2 summary count `hostedCount` / `joinedCount` để render tab
/// strip "Tôi tạo (N) | Tôi tham gia (M)" mà không cần filter client-side.
///
/// **Design:**
/// - Cubit lưu 1 state duy nhất với 2 danh sách items riêng (host / member)
///   + 2 summary count + active tab hiện tại. Khi user đổi tab, UI swap
///   `items` (không cần gọi lại API).
/// - Cubit chỉ fetch 1 endpoint duy nhất (`getMyReservations`) với filter
///   `participationType` tương ứng với tab đang active. Đổi tab → fetch
///   lại với filter mới.
/// - Pagination qua `loadMore()` (infinite scroll).
sealed class MyReservationsState extends Equatable {
  const MyReservationsState();

  @override
  List<Object?> get props => [];
}

class MyReservationsInitial extends MyReservationsState {
  const MyReservationsInitial();
}

class MyReservationsLoading extends MyReservationsState {
  /// Items đang hiển thị (giữ lại để render skeleton không che list).
  final List<ReservationEntity> previousItems;

  /// Tab đang active trước khi load (để UI hiển thị skeleton ở tab tương ứng).
  final ReservationParticipationType activeTab;

  /// True khi đang fetch trang tiếp theo (pagination) thay vì initial load.
  final bool isLoadMore;

  const MyReservationsLoading({
    this.previousItems = const [],
    this.activeTab = ReservationParticipationType.host,
    this.isLoadMore = false,
  });

  @override
  List<Object?> get props => [previousItems, activeTab, isLoadMore];
}

class MyReservationsLoaded extends MyReservationsState {
  /// Danh sách reservation cho tab hiện tại (sau filter participationType).
  final List<ReservationEntity> items;

  /// Summary count Host (từ server, độc lập với filter participationType).
  final int hostedCount;

  /// Summary count Member (từ server, độc lập với filter participationType).
  final int joinedCount;

  /// Tab đang hiển thị.
  final ReservationParticipationType activeTab;

  /// Filter hiện tại.
  final MyReservationsFilter filter;

  /// Phân trang.
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final bool isLoadMore;

  const MyReservationsLoaded({
    required this.items,
    required this.hostedCount,
    required this.joinedCount,
    required this.activeTab,
    required this.filter,
    this.page = 1,
    this.pageSize = 20,
    this.totalItems = 0,
    this.totalPages = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.isLoadMore = false,
  });

  MyReservationsLoaded copyWith({
    List<ReservationEntity>? items,
    int? hostedCount,
    int? joinedCount,
    ReservationParticipationType? activeTab,
    MyReservationsFilter? filter,
    int? page,
    int? pageSize,
    int? totalItems,
    int? totalPages,
    bool? hasNextPage,
    bool? hasPreviousPage,
    bool? isLoadMore,
  }) {
    return MyReservationsLoaded(
      items: items ?? this.items,
      hostedCount: hostedCount ?? this.hostedCount,
      joinedCount: joinedCount ?? this.joinedCount,
      activeTab: activeTab ?? this.activeTab,
      filter: filter ?? this.filter,
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
        items,
        hostedCount,
        joinedCount,
        activeTab,
        filter,
        page,
        pageSize,
        totalItems,
        totalPages,
        hasNextPage,
        hasPreviousPage,
        isLoadMore,
      ];
}

class MyReservationsFailure extends MyReservationsState {
  final String message;
  final List<ReservationEntity> previousItems;
  final ReservationParticipationType activeTab;
  final MyReservationsFilter? filter;

  const MyReservationsFailure({
    required this.message,
    this.previousItems = const [],
    this.activeTab = ReservationParticipationType.host,
    this.filter,
  });

  @override
  List<Object?> get props => [message, previousItems, activeTab, filter];
}

/// Filter cho `MyReservationsCubit` — filter status, khoảng ngày, cafe.
class MyReservationsFilter extends Equatable {
  final List<String>? statuses;
  final String? cafeId;
  final DateTime? fromDate;
  final DateTime? toDate;

  const MyReservationsFilter({
    this.statuses,
    this.cafeId,
    this.fromDate,
    this.toDate,
  });

  static const MyReservationsFilter empty = MyReservationsFilter();

  bool get hasAnyFilter =>
      (statuses != null && statuses!.isNotEmpty) ||
      (cafeId != null && cafeId!.isNotEmpty) ||
      fromDate != null ||
      toDate != null;

  MyReservationsFilter copyWith({
    List<String>? statuses,
    String? cafeId,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearStatuses = false,
    bool clearCafeId = false,
    bool clearFromDate = false,
    bool clearToDate = false,
  }) {
    return MyReservationsFilter(
      statuses: clearStatuses ? null : (statuses ?? this.statuses),
      cafeId: clearCafeId ? null : (cafeId ?? this.cafeId),
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
    );
  }

  @override
  List<Object?> get props => [statuses, cafeId, fromDate, toDate];
}