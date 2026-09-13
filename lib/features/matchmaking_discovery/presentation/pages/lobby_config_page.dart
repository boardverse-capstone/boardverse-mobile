import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/navigation/lobby_flow_navigator.dart';
import '../../../../core/utils/lobby_time_calculator.dart';
import '../../../lobby_management/presentation/widgets/lobby_game_picker_sheet.dart';
import '../../../reservation/domain/entities/entities.dart';
import '../../../reservation/presentation/cubit/reservation_cubit.dart';
import '../../../reservation/presentation/cubit/reservation_state.dart';
import '../../../reservation/presentation/pages/reservation_quote_page.dart';
import '../../domain/entities/board_game_entity.dart';
import '../../domain/entities/board_game_detail_entity.dart';
import '../../domain/entities/cafe_entity.dart';
import '../cubit/matchmaking_cubit.dart';
import '../cubit/matchmaking_state.dart';
import '../widgets/lobby_config/confirm_lobby_dialog.dart';
import '../widgets/lobby_config/lobby_config_tab_bar.dart';
import '../widgets/lobby_config/tab_cau_hinh.dart';
import '../widgets/lobby_config/tab_dat_coc.dart';
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
  bool _isCreatingLobby = false;
  bool _showAdvanced = false;

  double _searchRadiusKm = 5.0;
  double _minimumKarma = 0.0;

  // Quote preview - cache local từ cubit stream
  ReservationQuoteEntity? _quotePreview;
  String? _quoteError;
  bool _isQuoteLoading = false;

  final Duration _leadTime = const Duration(minutes: 20);

  /// Default start time nếu player chưa chọn giờ. 09:00 là khung giờ hẹn
  /// phổ biến cho board game (sáng sớm sau khi quán mở cửa).
  static const TimeOfDay _defaultStartTime = TimeOfDay(hour: 9, minute: 0);

  /// Default end time nếu player không chọn giờ kết thúc. 13:00 (~4 tiếng)
  /// là đủ dài cho 1 phiên board game trung bình.
  static const TimeOfDay _defaultEndTime = TimeOfDay(hour: 13, minute: 0);

  /// Số phút từ `now` tới `scheduledTime - leadTime` (deadline BR-08).
  int get _bufferMinutes {
    final now = DateTime.now();
    final scheduledTime = _getScheduledDateTime();
    final deadline = scheduledTime.subtract(_leadTime);
    return deadline.difference(now).inMinutes;
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
  /// UI, KHÔNG block user khỏi việc đặt lobby.
  bool get _hasBufferWarning =>
      !_isScheduledInPast && _bufferMinutes >= 0 && _bufferMinutes < 60;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _preferredStartTime = _defaultStartTime;
    // Khởi tạo mutable state từ widget values (cho phép đổi game sau).
    _currentGameId = widget.gameId;
    _currentGameName = widget.gameName;
    _currentGameEntity = widget.gameEntity;
    widget.matchmakingCubit.loadGameDetail(gameId: _currentGameId);
    // Load quote ngay khi mở trang để đảm bảo có data khi vào tab 4
    _loadQuotePreview();
  }

  /// Khi user chuyển sang tab Đặt cọc (index 3) và cubit đang ở state
  /// settled (Initial / QuoteError / QuoteLoaded) — tức không phải đang
  /// load — thì trigger reload quote để lấy dữ liệu mới nhất (tránh
  /// trường hợp user mở trang từ session trước, cubit còn giữ state
  /// cũ từ session trước đó).
  ///
  /// Dùng `indexIsChanging` để tránh trigger khi tab chưa thực sự đổi.
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    if (_tabController.index != 3) return;
    final cubit = GetIt.instance<ReservationCubit>();
    if (cubit.state is ReservationInitial ||
        cubit.state is ReservationQuoteError ||
        cubit.state is ReservationQuoteLoaded ||
        cubit.state is ReservationInsufficientBalance ||
        cubit.state is ReservationQuoteExpired) {
      // Đã settle → reload để có data mới nhất.
      debugPrint('[LobbyConfig] tab3 activated → reload quote');
      _loadQuotePreview();
    }
  }

  @override
  void dispose() {
    _quoteSubscription?.cancel();
    _tabController.removeListener(_onTabChanged);
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

    // Load game detail mới + reload quote preview vì gameId đã đổi.
    matchmakingCubit.loadGameDetail(gameId: picked.id);
    _loadQuotePreview();
  }

  void _goToTab(int tabIndex) {
    _tabController.animateTo(tabIndex);
  }

  // Lắng nghe trực tiếp ReservationCubit stream để cập nhật _quotePreview
  StreamSubscription<ReservationState>? _quoteSubscription;

  Future<void> _loadQuotePreview() async {
    final reservationCubit = GetIt.instance<ReservationCubit>();

    // Helper: chỉ setState khi widget đã mounted VÀ không đang trong build phase.
    // Nếu đang build (frame đầu tiên), defer ra post-frame để tránh crash.
    void safeSetState(VoidCallback fn) {
      if (!mounted) return;
      final phase = WidgetsBinding.instance.schedulerPhase;
      final isBuilding = phase == SchedulerPhase.transientCallbacks ||
          phase == SchedulerPhase.midFrameMicrotasks ||
          phase == SchedulerPhase.persistentCallbacks;
      if (isBuilding) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(fn);
        });
      } else {
        setState(fn);
      }
    }

    // Set loading state
    safeSetState(() {
      _quoteError = null;
      _quotePreview = null;
      _isQuoteLoading = true;
    });

    // Subscribe trước khi trigger createQuote để không miss event
    await _quoteSubscription?.cancel();
    _quoteSubscription = reservationCubit.stream.listen((state) {
      debugPrint('[LobbyConfig] ReservationState changed: ${state.runtimeType}');
      if (state is ReservationQuoteLoaded) {
        safeSetState(() {
          _quotePreview = state.quote;
          _isQuoteLoading = false;
        });
      } else if (state is ReservationInsufficientBalance) {
        safeSetState(() {
          _quotePreview = state.quote;
          _isQuoteLoading = false;
        });
      } else if (state is ReservationQuoteError) {
        safeSetState(() {
          _quoteError = state.message;
          _isQuoteLoading = false;
        });
      }
    });

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
  }

  Future<void> _confirmAndCreateLobby() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => LobbyConfigConfirmDialog(
        cafeName: widget.cafeName,
        gameName: _currentGameName,
        selectedDate: _selectedDate,
        preferredStartTime: _preferredStartTime,
        preferredEndTime: _preferredEndTime,
        endCrossesMidnight: _endCrossesMidnight,
        maxPlayers: _maxPlayers,
        isPublic: _isPublic,
        minimumKarma: _minimumKarma,
        searchRadiusKm: _searchRadiusKm,
        quotePreview: _quotePreview ?? GetIt.instance<ReservationCubit>().currentQuote,
        formatDate: _formatDate,
        formatTime: _formatTimeOfDay,
        formatBuffer: _formatBuffer,
        bufferMinutes: _bufferMinutes,
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCreatingLobby = true);

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
    LobbyFlowNavigator.push(
      context,
      BlocProvider.value(
        value: reservationCubit,
        child: const ReservationQuotePage(),
      ),
    ).then((_) {
      if (mounted) setState(() => _isCreatingLobby = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.matchmakingCubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tạo phòng chờ'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          children: [
            // Tab bar
            LobbyConfigTabBar(controller: _tabController),

            // Tab content
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
                    controller: _tabController,
                    children: [
                      // Tab 1: Quán & Game
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

                      // Tab 2: Thời gian
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
                        formatBuffer: _formatBuffer,
                        onNext: () => _goToTab(2),
                      ),

                      // Tab 3: Cấu hình
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
                        onNext: () {
                          _loadQuotePreview();
                          _goToTab(3);
                        },
                      ),

                      // Tab 4: Đặt cọc
                      LobbyConfigTabDatCoc(
                        cafeName: widget.cafeName,
                        gameName: _currentGameName,
                        selectedDate: _selectedDate,
                        preferredStartTime: _preferredStartTime,
                        preferredEndTime: _preferredEndTime,
                        endCrossesMidnight: _endCrossesMidnight,
                        maxPlayers: _maxPlayers,
                        isPublic: _isPublic,
                        minimumKarma: _minimumKarma,
                        quotePreview: _quotePreview,
                        quoteError: _quoteError,
                        isQuoteLoading: _isQuoteLoading,
                        isCreatingLobby: _isCreatingLobby,
                        bufferMinutes: _bufferMinutes,
                        hasBufferWarning: _hasBufferWarning,
                        formatDate: _formatDate,
                        formatTime: _formatTimeOfDay,
                        formatBuffer: _formatBuffer,
                        onConfirm: _confirmAndCreateLobby,
                        onRefreshQuote: _loadQuotePreview,
                        onLoadQuote: _loadQuotePreview,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}