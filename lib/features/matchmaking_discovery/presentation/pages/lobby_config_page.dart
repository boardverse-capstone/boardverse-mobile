import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/navigation/lobby_flow_navigator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../../../core/utils/lobby_time_calculator.dart';
import '../../../lobby_management/presentation/widgets/lobby_game_picker_sheet.dart';
import '../../../reservation/presentation/cubit/reservation_cubit.dart';
import '../../../reservation/presentation/pages/reservation_quote_page.dart';
import '../../domain/entities/board_game_entity.dart';
import '../../domain/entities/board_game_detail_entity.dart';
import '../../domain/entities/cafe_entity.dart';
import '../cubit/matchmaking_cubit.dart';
import '../cubit/matchmaking_state.dart';
import '../widgets/lobby_config/lobby_config_tab_bar.dart';
import '../widgets/lobby_config/tab_cau_hinh.dart';
import '../widgets/lobby_config/tab_quan_va_game.dart';
import '../widgets/lobby_config/tab_thoi_gian.dart';
import 'lobby_cafe_selection_page.dart';
class LobbyConfigPage extends StatefulWidget {
  final String gameId;
  final String gameName;
  final String cafeId;
  final String cafeName;
  final CafeEntity? cafeEntity;
  final MatchmakingCubit matchmakingCubit;
  final BoardGameEntity? gameEntity;

  const LobbyConfigPage({
    super.key,
    required this.gameId,
    required this.gameName,
    required this.cafeId,
    required this.cafeName,
    this.cafeEntity,
    required this.matchmakingCubit,
    this.gameEntity,
  });

  @override
  State<LobbyConfigPage> createState() => _LobbyConfigPageState();
}

class _LobbyConfigPageState extends State<LobbyConfigPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ----- Mutable state copy của widget.* (cho phép player đổi game) -----
  // Khi player ấn "Đổi game" ở tab Quán & Game, các field này được
  // cập nhật thay vì phải navigate lại flow. Cafe (widget.cafe*) giữ
  // nguyên — player đã chọn cafe rồi, không cần chọn lại.
  late String _currentGameId;
  late String _currentGameName;
  late BoardGameEntity? _currentGameEntity;

  // State
  late DateTime _selectedDate;
  TimeOfDay? _preferredStartTime;
  TimeOfDay? _preferredEndTime;
  bool _isPublic = true;
  int _maxPlayers = 4;
  bool _showAdvanced = false;

  double _searchRadiusKm = 5.0;
  double _minimumKarma = 0.0;

  final Duration _leadTime = const Duration(minutes: 20);

  /// Default start time nếu player chưa chọn giờ. LUÔN được tính dựa
  /// trên `_selectedDate` + giờ hiện tại — không phải const cứng — để:
  /// - Ngày tương lai → 09:00 (khuôn mặc định).
  /// - Hôm nay → `now + leadTime + 3h safety buffer` (làm tròn lên giờ
  ///   chẵn, clamp ≤ 22:00). Tránh bug UX "default 09:00 nằm trong quá
  ///   khứ → backend trả 400 → UI flash lỗi ~1s trước khi user kịp
  ///   chỉnh tay".
  /// Xem [LobbyTimeCalculator.computeSmartDefaultStartTime].
  TimeOfDay get _defaultStartTime =>
      LobbyTimeCalculator.computeSmartDefaultStartTime(
        _selectedDate,
        leadTime: _leadTime,
      );

  /// Default end time dựa theo start time + 4 tiếng (chuẩn board game
  /// session). Xem [LobbyTimeCalculator.computeDefaultEndTime].
  TimeOfDay get _defaultEndTime =>
      LobbyTimeCalculator.computeDefaultEndTime(
        _preferredStartTime ?? _defaultStartTime,
      );

  /// Số phút từ `now` tới `scheduledTime - leadTime` (deadline BR-08).
  /// Số phút từ BÂY GIỜ đến giờ chơi (`scheduledStartTime - now`). KHÔNG
  /// trừ `leadTime` ở đây — `leadTime` chỉ dùng cho validation backend
  /// (`recruitmentDeadline`) và cho `computeSmartDefaultStartTime`,
  /// không phải semantic của buffer hiển thị trên UI.
  ///
  /// UI semantic: "thời gian tuyển người = thời gian còn lại trước khi
  /// lobby bắt đầu". VD: now=19:30, scheduled=20:00 → buffer=30p.
  /// Player thấy đúng với expectation, dễ tính nhẩm.
  ///
  /// Trước đây tính `scheduledTime - leadTime - now` (= 9p cho 19:30 →
  /// 20:00 với leadTime=20p) — khiến UI hiển thị buffer âm/ngắn bất
  /// thường, gây hiểu nhầm. Backend vẫn tự validate `recruitmentDeadline`
  /// theo lead time của riêng nó, FE không cần replicate.
  int get _bufferMinutes {
    final now = DateTime.now();
    final scheduledTime = _getScheduledDateTime();
    return scheduledTime.difference(now).inMinutes;
  }

  /// `true` nếu `scheduledTime < now` (lobby sẽ chơi ở quá khứ).
  /// Đây là điều kiện DUY NHẤT block user khỏi việc đặt lobby. Chỉ
  /// phụ thuộc `scheduledTime`, không trừ lead time (BR §XXI-B.4: lead
  /// time chỉ ảnh hưởng deadline tuyển người, không ảnh hưởng khả
  /// năng tạo lobby).
  bool get _isScheduledInPast =>
      _getScheduledDateTime().isBefore(DateTime.now());

  /// `true` khi giờ kết thúc rơi vào NGÀY KẾ TIẾP so với ngày bắt đầu,
  /// tức là `preferredEndTime < preferredStartTime` (tính theo phút).
  ///
  /// Backend (BR-NEW-15, `.agents/docs/apis_docs/reservation.md` §
  /// preferredEndTime) hỗ trợ overnight: nếu end < start thì
  /// `scheduledEndTime` thuộc `playDate + 1`. UI phải hiển thị rõ
  /// trường hợp này để user biết lobby kéo dài qua đêm.
  ///
  /// Ví dụ: start 23:00, end 05:00 → `endCrossesMidnight = true`.
  bool get _endCrossesMidnight =>
      LobbyTimeCalculator.isOvernight(_preferredStartTime, _preferredEndTime);

  /// Cảnh báo buffer ngắn (< 60 phút) — CHỈ để hiển thị warning trên
  /// UI, KHÔNG block user khỏi việc đặt lobby (BR §XXI-B.6, cập nhật
  /// 2026-10-01: đồng bộ với ngưỡng cảnh báo "insufficient").
  bool get _hasBufferWarning =>
      !_isScheduledInPast && _bufferMinutes >= 0 && _bufferMinutes < 60;

  /// Ngưỡng tối thiểu `scheduledStartTime - now` để cho phép player
  /// chuyển sang bước tiếp theo. Nếu buffer < [_minutesAheadMin] thì:
  /// - Disable nút "Tiếp tục".
  /// - Hiển thị lý do ("không đủ thời gian chuẩn bị") để player hiểu
  ///   vì sao không bấm được.
  ///
  /// Lý do đặt 30 phút (BR §XXI-B.6, cập nhật 2026-10-01):
  /// - Đủ để bạn bè trong group nhận invite + di chuyển đến quán.
  /// - Đồng bộ với `validateStartTime` ở
  ///   `lib/core/utils/lobby_time_calculator.dart` để tránh "UI cho
  ///   đi tiếp nhưng server reject" gây UX khó chịu.
  /// - Trước đây là 5 phút (UI guard) + 60 phút (validation) → user
  ///   có thể qua UI nhưng fail ở server. Đã hợp nhất về 30 phút.
  static const int _minutesAheadMin = 30;

  /// Ngưỡng warning "không đủ thời gian chuẩn bị" (BR §XXI-B.6, cập nhật
  /// 2026-10-01). Dưới 60 phút = cảnh báo (group bạn đi chung vẫn đặt
  /// được nhưng nên chọn slot xa hơn nếu muốn tuyển thêm thành viên),
  /// trên 60 phút = không cảnh báo.
  static const int _minutesAheadWarning = 60;

  /// `true` khi player có thể chuyển sang bước tiếp theo (đặt lobby).
  /// `false` khi một trong các điều kiện nghiệp vụ bị vi phạm (BR §XXI-B.6,
  /// cập nhật 2026-10-01):
  ///   - `scheduledTime` ở quá khứ (user chọn giờ đã qua hôm nay).
  ///   - `buffer < 30 phút` (không đủ thời gian chuẩn bị cho group).
  ///   - `preferredEndTime == preferredStartTime` (BR-PreferredTimesMustDiffer
  ///     — backend reject với 400, mobile phải chặn trước ở tab Thời gian).
  bool get _canProceed {
    if (_isScheduledInPast) return false;
    if (_bufferMinutes < _minutesAheadMin) return false;
    if (_preferredEndTime != null &&
        _preferredStartTime != null &&
        LobbyTimeCalculator.validateEndTime(
              _preferredStartTime!,
              _preferredEndTime!,
            ) ==
            LobbyEndTimeValidation.equal) {
      return false;
    }
    return true;
  }

  /// Lý do KHÔNG cho phép tiếp tục (khi `_canProceed == false`).
  /// Hiển thị trong banner đỏ ngay phía trên nút "Tiếp tục" ở tab
  /// Thời gian để player hiểu tại sao bị disable (BR §XXI-B.6).
  /// Trả về `null` nếu có thể tiếp tục.
  String? get _cannotProceedReason {
    if (_isScheduledInPast) {
      return 'Giờ bắt đầu đã ở trong quá khứ — vui lòng chọn khung giờ '
          'khác hoặc đổi sang ngày mai.';
    }
    if (_bufferMinutes < _minutesAheadMin) {
      return 'Chỉ còn ${_formatBuffer(_bufferMinutes)} trước giờ chơi — '
          'không đủ thời gian chuẩn bị (cần ít nhất $_minutesAheadMin phút). '
          'Vui lòng chọn khung giờ xa hơn.';
    }
    if (_preferredEndTime != null &&
        _preferredStartTime != null &&
        LobbyTimeCalculator.validateEndTime(
              _preferredStartTime!,
              _preferredEndTime!,
            ) ==
            LobbyEndTimeValidation.equal) {
      return 'Giờ kết thúc phải khác giờ bắt đầu — vui lòng chọn lại giờ '
          'kết thúc (mặc định sẽ là +4 giờ so với giờ bắt đầu).';
    }
    return null;
  }

  /// `true` khi buffer nằm trong "vùng cảnh báo" — player VẪN CÓ THỂ
  /// đặt lobby nhưng UI cảnh báo họ rằng thời gian chuẩn bị rất ngắn
  /// (30 ≤ buffer < 60 phút). Nút "Tiếp tục" vẫn enabled ở mức này.
  bool get _isBufferInsufficient =>
      !_isScheduledInPast &&
      _bufferMinutes >= _minutesAheadMin &&
      _bufferMinutes < _minutesAheadWarning;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _preferredStartTime = _defaultStartTime;
    // Khởi tạo mutable state từ widget values (cho phép đổi game sau).
    _currentGameId = widget.gameId;
    _currentGameName = widget.gameName;
    _currentGameEntity = widget.gameEntity;
    widget.matchmakingCubit.loadGameDetail(gameId: _currentGameId);
    // Bắt đầu timer refresh buffer mỗi 30 giây. Nếu widget unmount,
    // timer tự cancel trong dispose(). Lý do: buffer là getter dùng
    // DateTime.now() — nếu widget không rebuild trong vài phút (user
    // chỉ đọc thông tin, không tương tác), giá trị hiển thị sẽ
    // stale, lệch với đồng hồ thực. Tần suất 30s đủ để giữ giá trị
    // tươi (max drift = 30s, không đáng kể so với đơn vị phút của UI)
    // mà không tốn pin/CPU.
    //
    // BR §XXI-B.6 (cập nhật 2026-10-01): sau khi bỏ Tab 4 (Đặt cọc),
    // tạo quote / lobby diễn ra ở `ReservationQuotePage` riêng biệt —
    // widget này chỉ host 3 tab config, không cần state
    // `_isCreatingLobby` nữa. Timer chỉ skip khi scheduled time đã
    // ở quá khứ (buffer không còn ý nghĩa hiển thị).
    _bufferRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (!mounted) return;
        if (_isScheduledInPast) return;
        setState(() {});
      },
    );
  }

  /// Timer đánh thức widget mỗi 30 giây để buffer info được refresh
  /// real-time. Nếu không, Flutter chỉ rebuild khi `setState()` được
  /// gọi — buffer hiển thị sẽ bị "đứng" ở giá trị tại lần build
  /// trước, lệch so với `DateTime.now()` thực tế khi user nhìn lại
  /// sau vài phút.
  ///
  /// Ví dụ: mở page lúc 18:00 với `scheduledTime = 20:00`, buffer =
  /// 120p. Không tương tác 20 phút, nhìn lại lúc 18:20 — UI vẫn hiển
  /// thị 120p (stale) dù thực tế buffer = 100p. Bug UX: player thấy
  /// buffer không khớp với đồng hồ.
  Timer? _bufferRefreshTimer;

  @override
  void dispose() {
    _bufferRefreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  /// Trả về DateTime giờ chơi thực tế:
  /// - Ưu tiên [_preferredStartTime] nếu user đã chọn (giờ chính xác
  ///   user muốn chơi).
  /// - Fallback [_defaultStartTime] (09:00) nếu chưa chọn.
  DateTime _getScheduledDateTime() {
    final time = _preferredStartTime ?? _defaultStartTime;
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      time.hour,
      time.minute,
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final weekday = weekdays[date.weekday % 7];
    return '$weekday, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Format `TimeOfDay` thành chuỗi `HH:mm:ss` theo ISO-8601 time format
  /// mà `ReservationQuoteRequestDto` yêu cầu (swagger.json line 27829).
  ///
  /// BR-NEW-15 (2026-08-18): backend giờ parse giờ chơi từ
  /// `preferredStartTime`/`preferredEndTime` (HH:mm:ss) thay vì enum
  /// TimeSlot.
  String _formatTimeOfDayAsHHMMSS(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  String _formatBuffer(int minutes) {
    // Trường hợp ngày đã chọn nằm trong quá khứ
    if (minutes < 0) {
      return 'Ngày đã chọn nằm trong quá khứ';
    }
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) return '${hours}h';
      return '${hours}h ${mins}p';
    }
    return '${minutes}p';
  }

  void _onDateSelected(DateTime date) {
    setState(() => _selectedDate = date);
    // Lưu ý: không cần reset quote ở đây nữa — quote chỉ được tạo
    // khi user sang `ReservationQuotePage` (sau Tab 3), lúc đó cubit
    // sẽ tự dùng date mới nhất qua `createQuote(...)`.
  }

  Future<void> _openDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
      helpText: 'Chọn ngày hẹn',
      cancelText: 'Huỷ',
      confirmText: 'Xác nhận',
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectPreferredTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _preferredStartTime ?? _defaultStartTime,
      helpText: 'Chọn giờ bắt đầu dự kiến',
      cancelText: 'Huỷ',
      confirmText: 'Xác nhận',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _preferredStartTime = picked;
        // Đổi giờ → quote sẽ được tạo lại trên `ReservationQuotePage`
        // qua `createQuote(...)` với giờ mới nhất. Không cần refetch ở
        // đây — quote chỉ được tạo khi user sang tab xác nhận đặt cọc.
      });
    }
  }

  Future<void> _selectPreferredEndTime(BuildContext context) async {
    final startTime = _preferredStartTime ?? _defaultStartTime;
    final initialTime = _preferredEndTime ?? _defaultEndTime;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Chọn giờ kết thúc dự kiến',
      cancelText: 'Huỷ',
      confirmText: 'Xác nhận',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;
    if (!context.mounted) return;

    // Backend rule (BR-NEW-15, swagger `preferredEndTime`):
    //   - end > start  → cùng ngày (same-day session).
    //   - end < start  → overnight, scheduledEndTime = playDate + 1.
    //   - end == start → 400 PreferredTimesMustDiffer.
    //
    // Trước Sep 2026 UI chỉ chấp nhận end > start, vô hiệu hóa luôn
    // overnight — user không thể đặt lobby 23:00 → 05:00. Fix: cho phép
    // cả hai trường hợp end > start và end < start, chỉ chặn khi bằng
    // nhau (vì backend trả 400).
    final validation = LobbyTimeCalculator.validateEndTime(startTime, picked);
    if (validation == LobbyEndTimeValidation.equal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Giờ kết thúc không được trùng giờ bắt đầu. '
            'Nếu muốn đặt qua đêm, chọn giờ nhỏ hơn giờ bắt đầu.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _preferredEndTime = picked;
      // Quote sẽ được tạo lại trên `ReservationQuotePage` sau khi
      // user xong Tab 3 (Cấu hình), không cần refetch ở đây.
    });
  }

  void _changeCafe() {
    final game = _currentGameEntity;
    if (game == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LobbyCafeSelectionPage(
          game: game,
          matchmakingCubit: widget.matchmakingCubit,
        ),
      ),
    );
  }

  /// Đổi sang tựa game khác khi đang ở flow cấu hình lobby.
  ///
  /// Flow: Player ấn "Đổi game" trên tab Quán & Game →
  ///   1. Gọi `GET /api/cafes/{cafeId}/active-games` để lấy danh sách
  ///      board game đang hoạt động tại quán đã chọn (chỉ game có sẵn
  ///      tại quán, không phải toàn bộ game hệ thống).
  ///   2. Mở bottom sheet [LobbyGamePickerSheet] với danh sách game của quán.
  ///   3. Nếu player chọn → cập nhật [_currentGameId] / [_currentGameName]
  ///      / [_currentGameEntity] + load game detail mới.
  ///   4. Cafe đã chọn giữ nguyên (player không phải chọn lại).
  ///
  /// Lưu ý: KHÔNG pop flow lobby về MainScaffold. Player vẫn ở trong
  /// page cấu hình, chỉ thay game. UX khớp với behavior của "Đổi quán".
  Future<void> _changeGame() async {
    final matchmakingCubit = widget.matchmakingCubit;

    // Load games của quán đã chọn. Dùng `loadCafeActiveGames` thay vì
    // `searchGames` (toàn bộ catalog hệ thống) — đảm bảo player chỉ
    // thấy game thực sự có tại quán, tránh chọn game không có và gặp
    // lỗi ở bước cuối.
    matchmakingCubit.loadCafeActiveGames(widget.cafeId);

    // Chờ cho đến khi cubit emit trạng thái settled (không còn Loading).
    // Dùng `await` trên stream.firstWhere để đợi state thay đổi.
    // Filter: bỏ qua MatchmakingLoading, nhận mọi state khác.
    late final MatchmakingState finalState;
    try {
      finalState = await matchmakingCubit.stream
          .firstWhere((s) => s is! MatchmakingLoading);
    } catch (_) {
      // Stream đã closed trước khi emit state settled → không mở picker.
      if (!mounted) return;
      return;
    }

    if (!mounted) return;

    // Nếu load thất bại (MatchmakingFailure), vẫn mở picker với danh
    // sách rỗng để player có thể đóng sheet. Lỗi đã được cubit emit
    // rồi — UI sẽ hiển thị SnackBar hoặc toast.
    final games = finalState is MatchmakingCafeGamesLoaded
        ? finalState.games
        : <BoardGameEntity>[];

    final picked = await showModalBottomSheet<BoardGameEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => LobbyGamePickerSheet(games: games),
    );

    if (picked == null || !mounted) return;

    // Bỏ qua nếu player chọn lại chính game hiện tại.
    if (picked.id == _currentGameId) return;

    setState(() {
      _currentGameId = picked.id;
      _currentGameName = picked.name;
      _currentGameEntity = picked;
    });

    // Load game detail mới. Quote sẽ được tạo sau khi user xong
    // Tab 3 (Cấu hình) và bấm "Tiếp tục" → `ReservationQuotePage`.
    matchmakingCubit.loadGameDetail(gameId: picked.id);
  }

  void _goToTab(int tabIndex) {
    _tabController.animateTo(tabIndex);
  }

  /// Quay lại tab trước đó (nếu đang ở tab đầu tiên thì không làm gì).
  /// Được gọi từ nút "Quay lại" ở bottom action bar — thay thế cho nút
  /// back trên AppBar để user chủ động bấm thay vì phản xạ chạm vào góc
  /// trên-trái (gây pop cả page, mất toàn bộ tiến trình).
  void _onPreviousTab() {
    final current = _tabController.index;
    if (current <= 0) return;
    _tabController.animateTo(current - 1);
  }

  // ══════════════════════════════════════════════════════════════════
  // ĐÃ BỎ (BR §XXI-B.6, cập nhật 2026-10-01):
  //   - `_quotePreview` / `_quoteError` / `_isQuoteLoading` state.
  //   - `_loadQuotePreview()` method.
  //   - `_quoteSubscription` stream listener.
  //   - `_onTabChanged` reload-on-tab-activate hook.
  //
  // Lý do: Tab 4 (Đặt cọc) đã được xoá khỏi flow 3 bước. Quote chỉ
  // được tạo tại thời điểm user bấm "Tiếp tục" ở Tab 3 (Cấu hình) →
  // chuyển sang `ReservationQuotePage` (trang xác nhận đặt cọc RIÊNG).
  // Trang đó tự quản lý quote state qua `ReservationCubit` + hiển thị
  // loading/error/loaded tương ứng. Widget này không cần pre-fetch nữa.
  // ══════════════════════════════════════════════════════════════════

  /// Bước cuối cùng của LobbyConfigPage — tạo quote và chuyển sang
  /// trang xác nhận đặt cọc RIÊNG (ReservationQuotePage).
  ///
  /// BR §XXI-B.6 (cập nhật 2026-10-01): bỏ Tab 4 (Đặt cọc) khỏi flow
  /// 3 bước của LobbyConfigPage. Sau khi user xong Tab 3 (Cấu hình) và
  /// bấm "Tiếp tục":
  ///   1. Reset `ReservationCubit` để clear state cũ (nếu có từ
  ///      session trước).
  ///   2. Trigger `createQuote(...)` với current config (date, time,
  ///      players, private/public...).
  ///   3. Push `ReservationQuotePage` lên navigation stack — trang
  ///      này tự subscribe cubit, hiển thị loading → loaded quote với
  ///      countdown + button "Xác nhận & Tạo lobby".
  ///
  /// Trang confirmation này TÁCH BIỆT khỏi LobbyConfigPage, không
  /// phải 1 tab nữa — tránh UX lặp lại thông tin cọc nhiều lần.
  Future<void> _confirmAndCreateLobby() async {
    final reservationCubit = GetIt.instance<ReservationCubit>();
    reservationCubit.reset();
    reservationCubit.createQuote(
      cafeId: widget.cafeId,
      gameId: _currentGameId,
      playDate: _selectedDate,
      preferredStartTime: _formatTimeOfDayAsHHMMSS(
          _preferredStartTime ?? _defaultStartTime),
      preferredEndTime:
          _formatTimeOfDayAsHHMMSS(_preferredEndTime ?? _defaultEndTime),
      minPlayers: 2,
      maxPlayers: _maxPlayers,
      isPrivate: !_isPublic,
    );

    if (!mounted) return;
    await LobbyFlowNavigator.push(
      context,
      BlocProvider.value(
        value: reservationCubit,
        child: const ReservationQuotePage(),
      ),
    );
  }

  /// Confirm trước khi thoát flow lobby nếu user đã nhập thông tin
  /// (không phải tab 1 mặc định). Tránh mất toàn bộ tiến trình khi
  /// user lỡ nhấn system back (Android hardware back / edge swipe).
  ///
  /// Returns `true` nếu cho phép pop, `false` nếu user huỷ.
  Future<bool> _confirmExitIfNeeded() async {
    // Nếu đang ở tab 1 (chưa nhập nhiều) → cho thoát luôn.
    if (_tabController.index <= 0) return true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Thoát tạo phòng chờ?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Các thông tin đã điền sẽ bị huỷ. Bạn có chắc muốn thoát?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Tiếp tục tạo phòng',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(
              'Thoát',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  /// User yêu cầu thoát flow lobby (qua nút X trên header HOẶC system
  /// back). Sau khi confirm, pop về MainScaffold (màn hình khám phá /
  /// home) thay vì chỉ pop 1 lần — đảm bảo user không bị kẹt ở các
  /// page trung gian (cafe selection, board game detail...).
  Future<void> _onRequestExit() async {
    final navigator = Navigator.of(context);
    final shouldExit = await _confirmExitIfNeeded();
    if (!shouldExit || !mounted) return;
    // Dùng helper returnToRoot để pop tới MainScaffold an toàn (không
    // rơi vào màn hình rỗng nếu stack chỉ còn page này).
    LobbyFlowNavigator.returnToRoot(navigator.context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.matchmakingCubit,
      child: PopScope(
        // Chỉ confirm khi đã vào sâu (tab > 0). Tab 1 cho thoát tự do.
        canPop: _tabController.index <= 0,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await _onRequestExit();
        },
        child: Scaffold(
        // Không có AppBar — nút back ở AppBar trước đây dễ bị chạm nhầm
        // khi user đang focus vào form, dẫn đến pop cả page và mất toàn
        // bộ tiến trình đã điền. Giờ thay bằng header custom chỉ có
        // title + step indicator, navigation giữa các tab điều khiển
        // qua nút "Quay lại" / "Tiếp tục" ở bottom action bar (rõ ràng
        // về intent, không bị phản xạ chạm nhầm).
        //
        // Thoát flow lobby hoàn toàn (huỷ tạo phòng) vẫn có thể dùng
        // system back gesture / hardware back button — đây là action có
        // chủ ý chứ không phải thói quen chạm vùng góc trên-trái.
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Custom header ───────────────────────────────────────
              // Dùng AnimatedBuilder để header rebuild khi đổi tab
              // (progress dots + step counter cập nhật theo _tabController).
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) => _LobbyConfigHeader(
                  stepIndex: _tabController.index,
                  totalSteps: 3,
                  // Nút X (Đóng) — player thoát flow về MainScaffold
                  // khi đổi ý (có việc bận, muốn khám phá thêm...).
                  onExit: _onRequestExit,
                ),
              ),

              // ── Tab bar ─────────────────────────────────────────────
              LobbyConfigTabBar(controller: _tabController),

              // ── Tab content ─────────────────────────────────────────
              Expanded(
                child: BlocBuilder<MatchmakingCubit, MatchmakingState>(
                  builder: (context, state) {
                    final BoardGameDetailEntity? gameDetail =
                        state is MatchmakingGameDetail ? state.game : null;
                    final maxPlayers = gameDetail?.maxPlayers ??
                        _currentGameEntity?.maxPlayers ?? 6;
                    final minPlayers = gameDetail?.minPlayers ??
                        _currentGameEntity?.minPlayers ?? 2;

                    return TabBarView(
                      // BR §XXI-B.6 (cập nhật 2026-10-01): vô hiệu hoá
                      // lướt ngang giữa các bước — player chỉ chuyển tab
                      // qua nút "Quay lại" / "Tiếp tục" ở bottom action
                      // bar. Tránh lướt nhầm khi đang cuộn dọc trong form
                      // (date picker, time picker, slider player count...).
                      // Lưu ý: KHÔNG đổi sang IndexedStack — TabController
                      // vẫn hoạt động bình thường, chỉ tắt gesture swipe.
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Tab 1: Quán & Game — không có nút Quay lại
                        // (đây là bước đầu tiên trong flow).
                        LobbyConfigTabQuanVaGame(
                          cafeName: widget.cafeName,
                          cafeEntity: widget.cafeEntity,
                          gameName: _currentGameName,
                          gameEntity: _currentGameEntity,
                          gameDetail: gameDetail,
                          onChangeCafe: _changeCafe,
                          onChangeGame: _changeGame,
                          onNext: () => _goToTab(1),
                        ),

                        // Tab 2: Thời gian — có Quay lại + Tiếp tục
                        LobbyConfigTabThoiGian(
                          selectedDate: _selectedDate,
                          preferredStartTime: _preferredStartTime,
                          preferredEndTime: _preferredEndTime,
                          endCrossesMidnight: _endCrossesMidnight,
                          onDateSelected: _onDateSelected,
                          onOpenDatePicker: () => _openDatePicker(context),
                          onPreferredTimeTap: () => _selectPreferredTime(context),
                          onPreferredEndTimeTap: () => _selectPreferredEndTime(context),
                          formatDate: _formatDate,
                          formatTime: _formatTimeOfDay,
                          bufferMinutes: _bufferMinutes,
                          isScheduledInPast: _isScheduledInPast,
                          hasBufferWarning: _hasBufferWarning,
                          isBufferInsufficient: _isBufferInsufficient,
                          // Disable NẾU quá khứ, buffer < 30p, HOẶC
                          // endTime == startTime (xem [_canProceed],
                          // BR §XXI-B.6 cập nhật 2026-10-01). Khi
                          // disable, hiển thị banner lý do ngay trên
                          // nút để họ hiểu tại sao không bấm được.
                          canProceed: _canProceed,
                          cannotProceedReason: _cannotProceedReason,
                          formatBuffer: _formatBuffer,
                          onPrev: _onPreviousTab,
                          onNext: () => _goToTab(2),
                        ),

                        // Tab 3: Cấu hình — có Quay lại + Xem thông tin cọc
                        LobbyConfigTabCauHinh(
                          maxPlayers: maxPlayers,
                          minPlayers: minPlayers,
                          selectedMaxPlayers: _maxPlayers,
                          isPublic: _isPublic,
                          showAdvanced: _showAdvanced,
                          minimumKarma: _minimumKarma,
                          searchRadiusKm: _searchRadiusKm,
                          onMaxPlayersChanged: (v) => setState(() => _maxPlayers = v),
                          onPublicChanged: (v) => setState(() => _isPublic = v),
                          onToggleAdvanced: () => setState(() => _showAdvanced = !_showAdvanced),
                          onKarmaChanged: (v) => setState(() => _minimumKarma = v),
                          onRadiusChanged: (v) => setState(() => _searchRadiusKm = v),
                          onPrev: _onPreviousTab,
                          // Tab cuối (Cấu hình) — bấm "Tiếp tục" sẽ
                          // tạo quote + push sang `ReservationQuotePage`
                          // (trang xác nhận đặt cọc RIÊNG). KHÔNG còn
                          // Tab 4 (Đặt cọc) trong flow này nữa.
                          onNext: _confirmAndCreateLobby,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// CUSTOM HEADER — thay thế AppBar để bỏ nút back dễ chạm nhầm
// ══════════════════════════════════════════════════════════════════════════

/// Header neo-brutalism cho [LobbyConfigPage].
///
/// Layout:
/// ```
/// ┌─────────────────────────────────────────────┐
/// │  [X]    TẠO PHÒNG CHỜ                        │   ← Close (X) + Title đậm
/// │         Bước 2 / 4 · Thời gian              │   ← Step counter
/// │         ●━━━●━━━○━━━○                        │   ← Progress dots
/// └─────────────────────────────────────────────┘
/// ```
///
/// Nút X ở góc trên-trái thay thế cho nút back cũ — cho phép player
/// chủ động thoát flow lobby về MainScaffold (khám phá) khi đổi ý
/// (có việc bận, muốn khám phá thêm...). Tap X → confirm dialog →
///
/// `[LobbyFlowNavigator.returnToRoot]`.
///
/// Navigation giữa các bước KHÔNG đi qua X mà dùng bottom action bar
/// (rõ ràng về intent: "Quay lại" chỉ chuyển tab, không pop page).
class _LobbyConfigHeader extends StatelessWidget {
  final int stepIndex;
  final int totalSteps;
  final VoidCallback? onExit;

  const _LobbyConfigHeader({
    required this.stepIndex,
    required this.totalSteps,
    this.onExit,
  });

  /// Tab labels — khớp thứ tự với TabController (length = 3).
  /// BR §XXI-B.6 (cập nhật 2026-10-01): bỏ Tab 4 (Đặt cọc) — trang
  /// xác nhận đặt cọc giờ là `ReservationQuotePage` RIÊNG biệt, push
  /// sau khi user xong bước Cấu hình.
  static const _stepLabels = ['Quán & Game', 'Thời gian', 'Cấu hình'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLabel = _stepLabels[stepIndex.clamp(0, _stepLabels.length - 1)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: NeoBrutalismTheme.borderWidth,
          ),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Center column: title + step + progress ────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tạo phòng chờ',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),

              // Step counter: "Bước 2 / 4 · Thời gian"
              Text(
                'Bước ${stepIndex + 1} / $totalSteps · $currentLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Progress dots — neo-brutalism style: filled square (current)
              // + outline square (chưa tới) + line connector.
              _ProgressDots(
                stepIndex: stepIndex,
                totalSteps: totalSteps,
              ),
            ],
          ),

          // ── Close (X) button — top-left ───────────────────────────
          // Đặt trong Stack + Align để không chiếm không gian của Column
          // trung tâm, vẫn neo-brutalism với border đậm + hard shadow.
          if (onExit != null)
            Positioned(
              left: 0,
              top: 0,
              child: _CloseButtonNeo(
                onPressed: onExit!,
                tooltip: 'Đóng',
              ),
            ),
        ],
      ),
    );
  }
}

/// Nút X (Đóng) neo-brutalism — dùng cho [_LobbyConfigHeader].
///
/// Kích thước 40×40, nền surface (light/dark), border đậm 2px, hard
/// offset shadow 3×3 (no blur), press animation translate (2,2). Icon
/// `Icons.close_rounded` size 20, màu text primary (subtle — không
/// dùng màu error để tránh cảm giác destructive).
class _CloseButtonNeo extends StatefulWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const _CloseButtonNeo({
    required this.onPressed,
    required this.tooltip,
  });

  @override
  State<_CloseButtonNeo> createState() => _CloseButtonNeoState();
}

class _CloseButtonNeoState extends State<_CloseButtonNeo> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidthBold,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: AppColors.black.withValues(alpha: 0.3),
            ),
          ),
          transform: _isPressed
              ? (Matrix4.identity()..translateByDouble(2.0, 2.0, 0.0, 1.0))
              : Matrix4.identity(),
          child: Center(
            child: Icon(
              Icons.close_rounded,
              size: 20,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Row of dots cho progress indicator. Dùng neo-brutalism hard-edge
/// squares thay vì circles tròn để đồng bộ với design language.
class _ProgressDots extends StatelessWidget {
  final int stepIndex;
  final int totalSteps;

  const _ProgressDots({
    required this.stepIndex,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.primary;
    final muted = isDark ? AppColors.borderDark : AppColors.border;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps * 2 - 1, (i) {
        // Pattern: [dot, line, dot, line, dot, line, dot]
        if (i.isEven) {
          final dotIndex = i ~/ 2;
          final isDone = dotIndex < stepIndex;
          final isCurrent = dotIndex == stepIndex;
          return Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: (isDone || isCurrent) ? accent : Colors.transparent,
              border: Border.all(
                color: (isDone || isCurrent) ? accent : muted,
                width: NeoBrutalismTheme.borderWidth,
              ),
              boxShadow: (isDone || isCurrent)
                  ? NeoBrutalismTheme.lightShadow(
                      shadowColor: accent.withValues(alpha: 0.5),
                    )
                  : null,
            ),
          );
        }
        // Line connector giữa 2 dots — filled nếu đã qua, outline nếu chưa.
        final beforeIndex = (i - 1) ~/ 2;
        final filled = beforeIndex < stepIndex;
        return Container(
          width: 32,
          height: 3,
          color: filled
              ? accent
              : (isDark ? AppColors.borderDark : AppColors.border),
        );
      }),
    );
  }
}