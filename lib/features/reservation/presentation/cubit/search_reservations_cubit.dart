// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/reservation_repository.dart';
import 'search_reservations_state.dart';

/// Cubit cho trang Lịch đặt / Search Reservations.
///
/// Tự động chọn endpoint dựa trên query:
/// - Không có `gameName` và `fromDate/toDate` → `GET /api/v1/reservations`
///   (simple get all, không cần fuzzy search).
/// - Có `gameName` hoặc `fromDate/toDate` → `GET /api/v1/reservations/search`
///   (fuzzy search endpoint).
///
/// Design:
/// - Cubit này được nhúng thẳng vào BookingsPage (tab "Lịch đặt") — KHÔNG
///   qua trang riêng. User thấy search bar + filter chips ngay trên cùng
///   và list kết quả bên dưới.
/// - Khi vừa mở page → auto-load với query rỗng (lấy tất cả reservation
///   của user, default `HostedByMe=true` của cubit).
/// - Mỗi lần filter thay đổi → reset về page 1 + emit Loading rồi gọi API.
/// - Text search có debounce 400ms để tránh spam request khi user gõ.
/// - `loadMore()` để infinite scroll (chỉ gọi khi `hasNextPage`).
/// - `clearFilters()` để reset toàn bộ filter về rỗng (giữ UI ổn định).
class SearchReservationsCubit extends Cubit<SearchReservationsState> {
  final ReservationRepository _repository;

  /// Query hiện tại đang được áp dụng — dùng để re-search khi filter đổi.
  ReservationSearchQuery _currentQuery = ReservationSearchQuery.empty;

  /// Debounce timer cho text search (gameName).
  Timer? _debounce;

  /// Số phần tử trên mỗi trang (cố định để đơn giản).
  static const int _pageSize = 20;

  /// Debounce duration cho text search.
  static const Duration _debounceDuration = Duration(milliseconds: 400);

  SearchReservationsCubit({required ReservationRepository repository})
      : _repository = repository,
        super(const SearchReservationsInitial()) {
    // Auto-load khi cubit được tạo — đảm bảo user thấy kết quả ngay
    // khi mở tab "Lịch đặt" mà không cần nhấn nút.
    search(ReservationSearchQuery.empty);
  }

  /// Query đang được áp dụng — UI dùng để hiển thị state filter chips.
  ReservationSearchQuery get currentQuery => _currentQuery;

  // ─── Filter setters (auto-search) ─────────────────────────────────

  /// Cập nhật text search theo tên game. Có debounce 400ms.
  ///
  /// Dùng cho `TextField.onChanged` để user gõ là tự search.
  void setGameName(String value) {
    _currentQuery = _currentQuery.copyWith(
      gameName: value.trim().isEmpty ? null : value.trim(),
      clearGameName: value.trim().isEmpty,
    );
    _scheduleSearch();
  }

  /// Cập nhật khoảng ngày (từ/đến) — search ngay lập tức.
  void setDateRange(DateTime? from, DateTime? to) {
    if (from != null && to != null && to.isBefore(from)) {
      // Nếu user chọn toDate < fromDate → đảo lại để không bị 400 từ BE.
      final tmp = from;
      from = to;
      to = tmp;
    }
    _currentQuery = _currentQuery.copyWith(
      fromDate: from,
      toDate: to,
      clearFromDate: from == null,
      clearToDate: to == null,
    );
    search(_currentQuery);
  }

  /// Cập nhật danh sách status filter. `null` hoặc `[]` nghĩa là "bỏ filter".
  void setStatuses(List<String>? statuses) {
    _currentQuery = _currentQuery.copyWith(
      statuses: (statuses != null && statuses.isNotEmpty) ? statuses : null,
      clearStatuses: statuses == null || statuses.isEmpty,
    );
    search(_currentQuery);
  }

  /// Cập nhật phạm vi (tất cả / tôi host / tôi tham gia).
  void setScope(SearchScope scope) {
    if (scope == _currentQuery.scope) return;
    _currentQuery = _currentQuery.copyWith(scope: scope);
    search(_currentQuery);
  }

  /// Reset toàn bộ filter về rỗng + auto-search lại.
  void clearFilters() {
    _debounce?.cancel();
    _currentQuery = ReservationSearchQuery.empty;
    search(_currentQuery);
  }

  /// Force search lại với query hiện tại — dùng khi user pull-to-refresh.
  Future<void> refresh() => search(_currentQuery);

  // ─── Internals ──────────────────────────────────────────────────

  /// Debounce + search — dùng cho text search.
  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => search(_currentQuery));
  }

  /// Thực hiện search với query hiện tại. Reset về page 1.
  ///
  /// Tự động chọn endpoint phù hợp:
  /// - Không có [gameName] và [fromDate/toDate] → `GET /api/v1/reservations`
  ///   (simple get all, không cần fuzzy search).
  /// - Có [gameName] hoặc [fromDate/toDate] → `GET /api/v1/reservations/search`
  ///   (fuzzy search endpoint).
  ///
  /// `statuses`, `cafeId`, `scope` được truyền cho cả 2 endpoint.
  Future<void> search(ReservationSearchQuery query) async {
    _currentQuery = query;
    emit(const SearchReservationsLoading());

    // Quyết định endpoint: chỉ dùng /search khi có gameName hoặc date range.
    final needsSearch = (query.gameName != null && query.gameName!.trim().isNotEmpty) ||
        query.fromDate != null ||
        query.toDate != null;

    final result = needsSearch
        ? await _repository.searchReservations(
            gameName: query.gameName,
            fromDate: query.fromDate,
            toDate: query.toDate,
            statuses: query.statuses,
            cafeId: query.cafeId,
            hostedByMe: query.scope.hostedByMe,
            joinedByMe: query.scope.joinedByMe,
            page: 1,
            pageSize: _pageSize,
          )
        : await _repository.getReservations(
            statuses: query.statuses,
            cafeId: query.cafeId,
            hostedByMe: query.scope.hostedByMe,
            joinedByMe: query.scope.joinedByMe,
            page: 1,
            pageSize: _pageSize,
          );

    result.fold(
      (failure) => emit(SearchReservationsFailure(
        message: failure.message,
        query: query,
      )),
      (paginated) => emit(SearchReservationsLoaded(
        query: query,
        items: paginated.items,
        page: paginated.page,
        pageSize: paginated.pageSize,
        totalItems: paginated.totalItems,
        totalPages: paginated.totalPages,
        hasNextPage: paginated.hasNextPage,
        hasPreviousPage: paginated.hasPreviousPage,
      )),
    );
  }

  /// Load trang tiếp theo (infinite scroll).
  /// No-op nếu đã ở trang cuối hoặc state không phải Loaded.
  /// Dùng cùng endpoint như lúc initial load (đã được chọn dựa trên query).
  Future<void> loadMore() async {
    final current = state;
    if (current is! SearchReservationsLoaded) return;
    if (!current.hasNextPage) return;
    if (current.isLoadMore) return;

    final nextPage = current.page + 1;

    emit(current.copyWith(isLoadMore: true));

    // Xác định endpoint dựa trên query tại thời điểm load đầu tiên.
    final needsSearch = (current.query.gameName != null &&
            current.query.gameName!.trim().isNotEmpty) ||
        current.query.fromDate != null ||
        current.query.toDate != null;

    final result = needsSearch
        ? await _repository.searchReservations(
            gameName: current.query.gameName,
            fromDate: current.query.fromDate,
            toDate: current.query.toDate,
            statuses: current.query.statuses,
            cafeId: current.query.cafeId,
            hostedByMe: current.query.scope.hostedByMe,
            joinedByMe: current.query.scope.joinedByMe,
            page: nextPage,
            pageSize: current.pageSize,
          )
        : await _repository.getReservations(
            statuses: current.query.statuses,
            cafeId: current.query.cafeId,
            hostedByMe: current.query.scope.hostedByMe,
            joinedByMe: current.query.scope.joinedByMe,
            page: nextPage,
            pageSize: current.pageSize,
          );

    result.fold(
      (failure) => emit(SearchReservationsFailure(
        message: failure.message,
        previousItems: current.items,
        query: current.query,
      )),
      (paginated) => emit(current.copyWith(
        items: [...current.items, ...paginated.items],
        page: paginated.page,
        totalItems: paginated.totalItems,
        totalPages: paginated.totalPages,
        hasNextPage: paginated.hasNextPage,
        hasPreviousPage: paginated.hasPreviousPage,
        isLoadMore: false,
      )),
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
