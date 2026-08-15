import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/navigation/lobby_flow_navigator.dart';
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

/// Trang cấu hình lobby — thiết kế lại với TabBarView:
///
/// 4 tabs:
/// 1. Quán & Game - Chọn/chỉnh sửa quán và game
/// 2. Thời gian - Chọn ngày (7 chips + lịch) và phiên (3 slots)
/// 3. Cấu hình - Số người, chế độ, nâng cao
/// 4. Đặt cọc - Preview cọc, xác nhận cuối cùng
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
  TimeSlot _selectedTimeSlot = TimeSlot.morning;
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

  /// Số phút từ `now` tới `scheduledTime - leadTime` (deadline BR-08).
  ///
  /// Dùng [_preferredStartTime] nếu user đã chọn (giờ chính xác user
  /// muốn chơi) — fallback slot start nếu chưa chọn. Tránh trường hợp
  /// user chọn giờ 16h trong slot evening mà bị tính nhầm theo slot
  /// start (18h).
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

  /// Cảnh báo buffer ngắn (< 60 phút) — CHỈ để hiển thị warning trên
  /// UI, KHÔNG block user khỏi việc đặt lobby. Theo BR §XXI-B.4, lobby
  /// vẫn được tạo thành công nếu `scheduledTime > now` (không kể lead
  /// time của backend BR-08 = 20 phút, vì user đã chấp nhận warning).
  ///
  /// Trước đây: `bufferMinutes < 60` → button "Tiếp tục" bị disable,
  /// gây UX xấu khi user muốn đặt sát giờ. Hiện tại: chỉ cảnh báo
  /// thông tin, vẫn cho đặt.
  bool get _hasBufferWarning =>
      !_isScheduledInPast && _bufferMinutes >= 0 && _bufferMinutes < 60;

  // Chỉ 3 slots: morning, afternoon, evening (không có night)
  static const _availableSlots = [TimeSlot.morning, TimeSlot.afternoon, TimeSlot.evening];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _preferredStartTime = _getSlotStartTime(TimeSlot.morning);
    // Khởi tạo mutable state từ widget values (cho phép đổi game sau).
    _currentGameId = widget.gameId;
    _currentGameName = widget.gameName;
    _currentGameEntity = widget.gameEntity;
    widget.matchmakingCubit.loadGameDetail(gameId: _currentGameId);
    // Load quote ngay khi mở trang để đảm bảo có data khi vào tab 4
    _loadQuotePreview();
  }

  @override
  void dispose() {
    _quoteSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  TimeOfDay _getSlotStartTime(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return const TimeOfDay(hour: 9, minute: 0);
      case TimeSlot.afternoon:
        return const TimeOfDay(hour: 13, minute: 0);
      case TimeSlot.evening:
        return const TimeOfDay(hour: 18, minute: 0);
      case TimeSlot.night:
        return const TimeOfDay(hour: 19, minute: 0);
    }
  }

  TimeOfDay _getSlotEndTime(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return const TimeOfDay(hour: 13, minute: 0);
      case TimeSlot.afternoon:
        return const TimeOfDay(hour: 18, minute: 0);
      case TimeSlot.evening:
        return const TimeOfDay(hour: 23, minute: 0);
      case TimeSlot.night:
        return const TimeOfDay(hour: 24, minute: 0);
    }
  }

  /// Trả về DateTime giờ chơi thực tế:
  /// - Ưu tiên [_preferredStartTime] nếu user đã chọn (giờ chính xác
  ///   user muốn chơi — vd 16h00 trong slot evening).
  /// - Fallback slot start (morning=9h, afternoon=13h, evening=18h).
  ///
  /// Quan trọng: trước đây chỉ dùng slot start → user chọn giờ 16h
  /// trong slot evening vẫn bị tính theo 18h → có thể block sai khi
  /// giờ slot start nằm trong tương lai xa nhưng giờ user chọn lại ở
  /// quá khứ (vd afternoon slot start 13h nhưng bây giờ 14h, user chọn
  /// 16h vẫn OK, nhưng nếu user chọn 14h slot evening thì tính 18h).
  DateTime _getScheduledDateTime() {
    final time = _preferredStartTime ?? _getSlotStartTime(_selectedTimeSlot);
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

  void _onTimeSlotChanged(TimeSlot slot) {
    setState(() {
      _selectedTimeSlot = slot;
      _preferredStartTime = _getSlotStartTime(slot);
      _preferredEndTime = null; // Reset end time when slot changes
    });
  }

  TimeSlot _detectTimeSlotFromTime(TimeOfDay time) {
    final hour = time.hour + time.minute / 60;
    if (hour >= 9 && hour < 13) return TimeSlot.morning;
    if (hour >= 13 && hour < 18) return TimeSlot.afternoon;
    if (hour >= 18 && hour < 23) return TimeSlot.evening;
    return TimeSlot.night;
  }

  Future<void> _selectPreferredTime(BuildContext context) async {
    final startTime = _getSlotStartTime(_selectedTimeSlot);
    final endTime = _getSlotEndTime(_selectedTimeSlot);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _preferredStartTime ?? startTime,
      helpText: 'Chọn giờ dự kiến (trong khung ${_getSlotLabel(_selectedTimeSlot)})',
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
      final pickedHour = picked.hour + picked.minute / 60;
      final startHour = startTime.hour + startTime.minute / 60;
      final endHour = endTime.hour == 24 ? 24.0 : endTime.hour + endTime.minute / 60;

      final isWithinCurrentSlot = pickedHour >= startHour && pickedHour < endHour;
      final detectedSlot = _detectTimeSlotFromTime(picked);

      setState(() {
        if (isWithinCurrentSlot) {
          _preferredStartTime = picked;
        } else {
          // User picked time outside current slot - auto-select correct slot
          _selectedTimeSlot = detectedSlot;
          _preferredStartTime = picked;
        }
      });
    }
  }

  Future<void> _selectPreferredEndTime(BuildContext context) async {
    final startTime = _preferredStartTime ?? _getSlotStartTime(_selectedTimeSlot);
    final slotEndTime = _getSlotEndTime(_selectedTimeSlot);

    // End time must be after start time
    final initialTime = _preferredEndTime ?? slotEndTime;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Chọn giờ kết thúc ưa thích',
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
      final pickedMinutes = picked.hour * 60 + picked.minute;
      final startMinutes = startTime.hour * 60 + startTime.minute;

      // Only allow end time after start time
      if (pickedMinutes > startMinutes) {
        setState(() {
          _preferredEndTime = picked;
        });
      }
    }
  }

  String _getSlotLabel(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return 'Sáng (9:00-13:00)';
      case TimeSlot.afternoon:
        return 'Chiều (13:00-18:00)';
      case TimeSlot.evening:
        return 'Tối (18:00-23:00)';
      case TimeSlot.night:
        return 'Khuya (19:00-24:00)';
    }
  }

  String _getSlotShortLabel(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return 'Sáng';
      case TimeSlot.afternoon:
        return 'Chiều';
      case TimeSlot.evening:
        return 'Tối';
      case TimeSlot.night:
        return 'Khuya';
    }
  }

  IconData _getSlotIcon(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return Icons.wb_sunny;
      case TimeSlot.afternoon:
        return Icons.wb_cloudy;
      case TimeSlot.evening:
        return Icons.nights_stay;
      case TimeSlot.night:
        return Icons.bedtime;
    }
  }

  Color _getSlotColor(TimeSlot slot, ColorScheme colorScheme) {
    switch (slot) {
      case TimeSlot.morning:
        return Colors.orange;
      case TimeSlot.afternoon:
        return Colors.amber;
      case TimeSlot.evening:
        return Colors.indigo;
      case TimeSlot.night:
        return Colors.deepPurple;
    }
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
  ///   1. Mở bottom sheet [LobbyGamePickerSheet] (giống flow tạo lobby
  ///      ở [LobbyHubPage]) để player chọn tựa game mới.
  ///   2. Nếu player chọn → cập nhật [_currentGameId] / [_currentGameName]
  ///      / [_currentGameEntity] + load game detail mới.
  ///   3. Cafe đã chọn giữ nguyên (player không phải chọn lại).
  ///
  /// Lưu ý: KHÔNG pop flow lobby về MainScaffold. Player vẫn ở trong
  /// page cấu hình, chỉ thay game. UX khớp với behavior của "Đổi quán"
  /// — player chỉ swap một field, không reset cả flow.
  Future<void> _changeGame() async {
    // Đảm bảo cubit đã có danh sách games để picker hiển thị. Có thể
    // cubit chưa fetch nếu player mở flow qua BoardGameDetail trực tiếp
    // (chưa vào Search tab Explore). Lấy state hiện tại trước, nếu chưa
    // có kết quả → gọi searchGames() để fetch.
    final matchmakingCubit = widget.matchmakingCubit;
    if (matchmakingCubit.state is! MatchmakingSearchResults) {
      await matchmakingCubit.searchGames();
      if (!mounted) return;
    }

    // Mở bottom sheet picker — contract giống LobbyHubPage:
    // nhận List<BoardGameEntity> đã được cache trong cubit state, trả
    // về BoardGameEntity qua Navigator.pop (null nếu player đóng).
    final picked = await showModalBottomSheet<BoardGameEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        final s = matchmakingCubit.state;
        final games = s is MatchmakingSearchResults
            ? s.games
            : <BoardGameEntity>[];
        return LobbyGamePickerSheet(games: games);
      },
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
      timeSlot: _selectedTimeSlot,
      preferredStartTime: _preferredStartTime != null
          ? '${_preferredStartTime!.hour.toString().padLeft(2, '0')}:'
              '${_preferredStartTime!.minute.toString().padLeft(2, '0')}:00'
          : null,
      preferredEndTime: _preferredEndTime != null
          ? '${_preferredEndTime!.hour.toString().padLeft(2, '0')}:'
              '${_preferredEndTime!.minute.toString().padLeft(2, '0')}:00'
          : null,
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
        selectedTimeSlot: _selectedTimeSlot,
        preferredStartTime: _preferredStartTime,
        preferredEndTime: _preferredEndTime,
        maxPlayers: _maxPlayers,
        isPublic: _isPublic,
        minimumKarma: _minimumKarma,
        searchRadiusKm: _searchRadiusKm,
        quotePreview: _quotePreview ?? GetIt.instance<ReservationCubit>().currentQuote,
        formatDate: _formatDate,
        formatTime: _formatTimeOfDay,
        getSlotLabel: _getSlotLabel,
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
      timeSlot: _selectedTimeSlot,
      preferredStartTime: _preferredStartTime != null
          ? '${_preferredStartTime!.hour.toString().padLeft(2, '0')}:'
              '${_preferredStartTime!.minute.toString().padLeft(2, '0')}:00'
          : null,
      preferredEndTime: _preferredEndTime != null
          ? '${_preferredEndTime!.hour.toString().padLeft(2, '0')}:'
              '${_preferredEndTime!.minute.toString().padLeft(2, '0')}:00'
          : null,
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
                        selectedTimeSlot: _selectedTimeSlot,
                        preferredStartTime: _preferredStartTime,
                        preferredEndTime: _preferredEndTime,
                        availableSlots: _availableSlots,
                        onDateSelected: _onDateSelected,
                        onOpenDatePicker: () => _openDatePicker(context),
                        onTimeSlotChanged: _onTimeSlotChanged,
                        onPreferredTimeTap: () => _selectPreferredTime(context),
                        onPreferredEndTimeTap: () => _selectPreferredEndTime(context),
                        formatDate: _formatDate,
                        formatTime: _formatTimeOfDay,
                        getSlotStartTime: _getSlotStartTime,
                        getSlotEndTime: _getSlotEndTime,
                        getSlotLabel: _getSlotLabel,
                        getSlotShortLabel: _getSlotShortLabel,
                        getSlotIcon: _getSlotIcon,
                        getSlotColor: _getSlotColor,
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
                        selectedTimeSlot: _selectedTimeSlot,
                        preferredStartTime: _preferredStartTime,
                        preferredEndTime: _preferredEndTime,
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
                        getSlotLabel: _getSlotLabel,
                        getSlotShortLabel: _getSlotShortLabel,
                        getSlotIcon: _getSlotIcon,
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