// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/reservation_repository.dart';
import 'my_reservations_state.dart';

/// Cubit load danh sách reservation từ `GET /api/v1/reservations/my`.
///
/// **Luồng UX:**
/// 1. User mở tab "Lịch đặt" → auto-load với `participationType=Host`,
///    `pageSize=20`.
/// 2. Response trả về items + 2 summary count (`hostedCount`, `joinedCount`).
/// 3. User đổi sang tab "Tôi tham gia" → cubit fetch lại với
///    `participationType=Member` (giữ nguyên các filter khác).
/// 4. Pull-to-refresh → reset về page 1, fetch lại.
/// 5. Infinite scroll → `loadMore()` với `page+1`.
///
/// **Cache strategy:**
/// - Cubit KHÔNG cache items theo tab — mỗi lần đổi tab sẽ fetch mới từ
///   server. Lý do: tab summary count + filter phức tạp → caching client
///   dễ gây stale data. Server `GET /my` đủ nhanh (1 query SQL).
class MyReservationsCubit extends Cubit<MyReservationsState> {
  final ReservationRepository _repository;

  /// Số phần tử trên mỗi trang (cố định để đơn giản).
  static const int _pageSize = 20;

  MyReservationsCubit({required ReservationRepository repository})
      : _repository = repository,
        super(const MyReservationsInitial());

  // ─── Init ──────────────────────────────────────────────────────

  /// Auto-load khi cubit được tạo. Mặc định bắt đầu với tab "Tôi tạo"
  /// (Host) — phổ biến nhất cho player tạo lobby.
  void initialize() {
    if (state is MyReservationsInitial) {
      load(initialTab: ReservationParticipationType.host);
    }
  }

  // ─── Tab switch ────────────────────────────────────────────────

  /// Đổi tab hiển thị — fetch lại với `participationType` tương ứng.
  ///
  /// Nếu user đang ở tab A và bấm lại tab A → no-op (giữ state).
  ///
  /// **UX khi đổi tab:** ta KHÔNG giữ `previousItems` của tab cũ vì chúng
  /// thuộc về tab khác (khác `participationType`) → nếu render sẽ gây
  /// "khựng" — user thấy danh sách tab cũ trong khi đợi API tab mới. Thay
  /// vào đó emit Loading rỗng → panel hiển thị shimmer skeleton ngay
  /// lập tức, chờ API trả về rồi fade-in danh sách mới.
  Future<void> switchTab(ReservationParticipationType tab) async {
    final current = state;

    // Nếu đang ở tab được yêu cầu + đã có data → no-op.
    if (current is MyReservationsLoaded && current.activeTab == tab) {
      return;
    }

    final filter = current is MyReservationsLoaded
        ? current.filter
        : (current is MyReservationsFailure && current.filter != null
            ? current.filter!
            : MyReservationsFilter.empty);

    await _load(
      participationType: tab,
      filter: filter,
      isRefresh: false,
      isTabSwitch: true,
    );
  }

  // ─── Filter setters ────────────────────────────────────────────

  /// Cập nhật filter status. Reset về page 1.
  Future<void> setStatuses(List<String>? statuses) async {
    final current = state;
    final activeTab = current is MyReservationsLoaded
        ? current.activeTab
        : (current is MyReservationsFailure
            ? current.activeTab
            : ReservationParticipationType.host);
    final oldFilter = current is MyReservationsLoaded
        ? current.filter
        : (current is MyReservationsFailure && current.filter != null
            ? current.filter!
            : MyReservationsFilter.empty);

    final newFilter = oldFilter.copyWith(
      statuses: (statuses != null && statuses.isNotEmpty) ? statuses : null,
      clearStatuses: statuses == null || statuses.isEmpty,
    );

    await _load(
      participationType: activeTab,
      filter: newFilter,
      isRefresh: false,
    );
  }

  /// Cập nhật khoảng ngày. Server tự swap nếu fromDate > toDate.
  Future<void> setDateRange(DateTime? from, DateTime? to) async {
    if (from != null && to != null && to.isBefore(from)) {
      final tmp = from;
      from = to;
      to = tmp;
    }

    final current = state;
    final activeTab = current is MyReservationsLoaded
        ? current.activeTab
        : (current is MyReservationsFailure
            ? current.activeTab
            : ReservationParticipationType.host);
    final oldFilter = current is MyReservationsLoaded
        ? current.filter
        : (current is MyReservationsFailure && current.filter != null
            ? current.filter!
            : MyReservationsFilter.empty);

    final newFilter = oldFilter.copyWith(
      fromDate: from,
      toDate: to,
      clearFromDate: from == null,
      clearToDate: to == null,
    );

    await _load(
      participationType: activeTab,
      filter: newFilter,
      isRefresh: false,
    );
  }

  /// Reset toàn bộ filter (giữ nguyên tab đang active).
  Future<void> clearFilters() async {
    final current = state;
    final activeTab = current is MyReservationsLoaded
        ? current.activeTab
        : (current is MyReservationsFailure
            ? current.activeTab
            : ReservationParticipationType.host);

    await _load(
      participationType: activeTab,
      filter: MyReservationsFilter.empty,
      isRefresh: false,
    );
  }

  // ─── Main load ─────────────────────────────────────────────────

  /// Load danh sách reservation cho tab [participationType].
  ///
  /// Dùng cho initial load + đổi tab + đổi filter.
  /// `isRefresh = true` → emit Loading rồi mới load (dùng cho pull-to-refresh).
  Future<void> load({
    ReservationParticipationType initialTab =
        ReservationParticipationType.host,
  }) async {
    await _load(
      participationType: initialTab,
      filter: MyReservationsFilter.empty,
      isRefresh: true,
    );
  }

  Future<void> _load({
    required ReservationParticipationType participationType,
    required MyReservationsFilter filter,
    required bool isRefresh,
    bool isTabSwitch = false,
  }) async {
    // Khi đổi tab, KHÔNG giữ previousItems của tab cũ — chúng thuộc về
    // participationType khác, render sẽ gây khựng UX. Với các thay đổi
    // khác (filter, refresh, initial load) vẫn giữ previousItems để UI
    // không flash skeleton khi API nhanh.
    final prevItems = isTabSwitch
        ? <ReservationEntity>[]
        : (state is MyReservationsLoaded
            ? (state as MyReservationsLoaded).items
            : (state is MyReservationsFailure
                ? (state as MyReservationsFailure).previousItems
                : <ReservationEntity>[]));

    emit(MyReservationsLoading(
      previousItems: prevItems,
      activeTab: participationType,
    ));

    final result = await _repository.getMyReservations(
      participationType: participationType,
      statuses: filter.statuses,
      cafeId: filter.cafeId,
      fromDate: filter.fromDate,
      toDate: filter.toDate,
      page: 1,
      pageSize: _pageSize,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(MyReservationsFailure(
        message: failure.message,
        previousItems: prevItems,
        activeTab: participationType,
        filter: filter,
      )),
      (data) => emit(MyReservationsLoaded(
        items: data.items,
        hostedCount: data.hostedCount,
        joinedCount: data.joinedCount,
        activeTab: participationType,
        filter: filter,
        page: data.paginated.page,
        pageSize: data.paginated.pageSize,
        totalItems: data.paginated.totalItems,
        totalPages: data.paginated.totalPages,
        hasNextPage: data.paginated.hasNextPage,
        hasPreviousPage: data.paginated.hasPreviousPage,
      )),
    );
  }

  /// Force refresh (pull-to-refresh) — reset về page 1, fetch lại.
  Future<void> refresh() async {
    final current = state;
    if (current is MyReservationsLoaded) {
      await _load(
        participationType: current.activeTab,
        filter: current.filter,
        isRefresh: true,
      );
    } else if (current is MyReservationsFailure) {
      await _load(
        participationType: current.activeTab,
        filter: current.filter ?? MyReservationsFilter.empty,
        isRefresh: true,
      );
    } else {
      await load();
    }
  }

  /// Load trang tiếp theo (infinite scroll).
  Future<void> loadMore() async {
    final current = state;
    if (current is! MyReservationsLoaded) return;
    if (!current.hasNextPage) return;
    if (current.isLoadMore) return;

    emit(current.copyWith(isLoadMore: true));

    final nextPage = current.page + 1;
    final result = await _repository.getMyReservations(
      participationType: current.activeTab,
      statuses: current.filter.statuses,
      cafeId: current.filter.cafeId,
      fromDate: current.filter.fromDate,
      toDate: current.filter.toDate,
      page: nextPage,
      pageSize: current.pageSize,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(MyReservationsFailure(
        message: failure.message,
        previousItems: current.items,
        activeTab: current.activeTab,
        filter: current.filter,
      )),
      (data) => emit(current.copyWith(
        items: [...current.items, ...data.items],
        page: data.paginated.page,
        totalItems: data.paginated.totalItems,
        totalPages: data.paginated.totalPages,
        hasNextPage: data.paginated.hasNextPage,
        hasPreviousPage: data.paginated.hasPreviousPage,
        isLoadMore: false,
      )),
    );
  }
}