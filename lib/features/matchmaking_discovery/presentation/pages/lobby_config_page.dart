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
import '../../domain/entities/default_time_slot_entity.dart';
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

  /// Khung giờ load từ `GET /api/v1/manager/time-slots/defaults`. Nếu API
  /// lỗi / mạng chậm thì fallback về [_fallbackSlotOptions] (hardcode
  /// khớp với default backend) — UI vẫn render được ngay khi mở trang.
  List<TimeSlotOption> _slotOptions = _fallbackSlotOptions;

  /// Hardcode khớp với `DefaultTimeSlotDto` trong backend (morning=06-12,
  /// afternoon=12-17, evening=17-23, lateNight=23-06). Chỉ dùng khi API
  /// không trả data — không phải single source of truth.
  ///
  /// Bao gồm cả `lateNight` (khớp với backend) — UI hiển thị 4 slot giống
  /// quán mở 24/24. Khi user chọn `lateNight`, mapping sang `TimeSlot.night`
  /// (local enum) để gọi reservation API.
  static const List<TimeSlotOption> _fallbackSlotOptions = [
    TimeSlotOption(
      slot: TimeSlot.morning,
      shortLabel: 'Sáng',
      timeRangeLabel: '06:00 - 12:00',
      icon: Icons.wb_sunny,
      color: Colors.orange,
    ),
    TimeSlotOption(
      slot: TimeSlot.afternoon,
      shortLabel: 'Chiều',
      timeRangeLabel: '12:00 - 17:00',
      icon: Icons.wb_cloudy,
      color: Colors.amber,
    ),
    TimeSlotOption(
      slot: TimeSlot.evening,
      shortLabel: 'Tối',
      timeRangeLabel: '17:00 - 23:00',
      icon: Icons.nights_stay,
      color: Colors.indigo,
    ),
    TimeSlotOption(
      slot: TimeSlot.night,
      shortLabel: 'Khuya',
      timeRangeLabel: '23:00 - 06:00',
      icon: Icons.bedtime,
      color: Colors.deepPurple,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
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
    // Load 4 khung giờ cố định từ backend. Nếu thất bại → vẫn dùng
    // `_fallbackSlotOptions` (UI render ngay được).
    _loadDefaultTimeSlots();
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

  TimeOfDay _getSlotStartTime(TimeSlot slot) {
    // Ưu tiên giá trị từ server (load trong `_loadDefaultTimeSlots`). Nếu
    // chưa load xong / API lỗi thì rơi về hardcode fallback bên dưới — đảm
    // bảo UI luôn có giá trị dùng được ngay từ frame đầu tiên.
    final serverValue = _serverSlotStartTimes[slot];
    if (serverValue != null) return serverValue;
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
    final serverValue = _serverSlotEndTimes[slot];
    if (serverValue != null) return serverValue;
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

  /// Parse `HH:mm:ss` (hoặc `HH:mm`) thành [TimeOfDay]. Trả về null nếu
  /// format lỗi — caller dùng fallback.
  TimeOfDay? _parseServerTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    // `24:00` tương đương `00:00` ngày hôm sau — encode thành `00:00`.
    // Không xử lý special ở đây, chỉ clamp về TimeOfDay hợp lệ (0–23).
    final clampedHour = h == 24 ? 0 : h.clamp(0, 23);
    return TimeOfDay(hour: clampedHour, minute: m);
  }

  /// Map `TimeSlotKey` (server) sang `TimeSlot` (local enum).
  ///
  /// Lưu ý: backend dùng `lateNight` (khuya) còn local enum dùng `night`.
  /// Hai tên khác nhau nhưng cùng đại diện 1 slot thực tế — mapping này
  /// đảm bảo reservation API nhận đúng `Night` (PascalCase) khi gửi quote.
  TimeSlot _toLocalSlot(TimeSlotKey key) {
    switch (key) {
      case TimeSlotKey.morning:
        return TimeSlot.morning;
      case TimeSlotKey.afternoon:
        return TimeSlot.afternoon;
      case TimeSlotKey.evening:
        return TimeSlot.evening;
      case TimeSlotKey.lateNight:
        return TimeSlot.night;
    }
  }

  /// Format `HH:mm:ss` thành `HH:mm` (bỏ phần giây) cho UI.
  String _formatServerTimeLabel(String raw) {
    final parts = raw.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return raw;
  }

  Future<void> _loadDefaultTimeSlots() async {
    final slots = await widget.matchmakingCubit.loadDefaultTimeSlots();
    if (!mounted || slots == null) return;
    // Server có thể trả 4 slot theo bất kỳ thứ tự nào — sort theo thứ tự
    // BR-NEW-15 (morning → afternoon → evening → lateNight) để UI hiển thị
    // ổn định.
    final ordered = [...slots]..sort((a, b) {
        return a.slot.index.compareTo(b.slot.index);
      });
    final options = <TimeSlotOption>[];
    for (final dto in ordered) {
      final localSlot = _toLocalSlot(dto.slot);
      final start = _parseServerTime(dto.defaultStartTime) ??
          _getSlotStartTime(localSlot);
      final end = _parseServerTime(dto.defaultEndTime) ??
          _getSlotEndTime(localSlot);
      // Override `_getSlotStartTime` / `_getSlotEndTime` cho slot này —
      // dùng giá trị server khi parse được, fallback local nếu lỗi.
      _serverSlotStartTimes[localSlot] = start;
      _serverSlotEndTimes[localSlot] = end;

      options.add(TimeSlotOption(
        slot: localSlot,
        shortLabel: dto.displayName,
        timeRangeLabel:
            '${_formatServerTimeLabel(dto.defaultStartTime)} - '
            '${_formatServerTimeLabel(dto.defaultEndTime)}',
        icon: _getSlotIcon(localSlot),
        color: _getSlotColor(localSlot, null),
      ));
    }
    if (!mounted) return;
    setState(() => _slotOptions = options);
  }

  /// Cache startTime / endTime do server trả về, key theo `TimeSlot`.
  /// `_getSlotStartTime` / `_getSlotEndTime` sẽ ưu tiên giá trị ở đây
  /// trước khi rơi về hardcode fallback.
  final Map<TimeSlot, TimeOfDay> _serverSlotStartTimes = {};
  final Map<TimeSlot, TimeOfDay> _serverSlotEndTimes = {};

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

  /// Phát hiện `TimeSlot` chứa giờ user vừa chọn. Dùng server data nếu
  /// đã load (qua `_serverSlotStartTimes` / `_serverSlotEndTimes`), nếu
  /// không thì rơi về heuristic 9/13/18/23.
  TimeSlot _detectTimeSlotFromTime(TimeOfDay time) {
    final pickedHour = time.hour + time.minute / 60;

    // Ưu tiên match với server slot — sort theo start time để kiểm tra
    // từ "sớm" đến "muộn".
    final candidates = _serverSlotStartTimes.entries.toList()
      ..sort((a, b) => a.value.hour.compareTo(b.value.hour));
    for (final entry in candidates) {
      final start = entry.value.hour + entry.value.minute / 60;
      final end = _serverSlotEndTimes[entry.key];
      if (end == null) continue;
      // End có thể là 0 (LateNight overnight) — xử lý bằng cách coi 0 là 24.
      final endHour =
          end.hour == 0 ? 24.0 : end.hour + end.minute / 60;
      if (pickedHour >= start && pickedHour < endHour) {
        return entry.key;
      }
    }

    // Fallback heuristic khi server data chưa load / API lỗi.
    if (pickedHour >= 9 && pickedHour < 13) return TimeSlot.morning;
    if (pickedHour >= 13 && pickedHour < 18) return TimeSlot.afternoon;
    if (pickedHour >= 18 && pickedHour < 23) return TimeSlot.evening;
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
      // End có thể là 0 (sau khi clamp từ `24:00:00`) hoặc > start (overnight).
      // Để kiểm tra "picked có trong slot không", so sánh theo 2 case:
      // - Slot không qua đêm (end > start): picked trong [start, end).
      // - Slot qua đêm (end < start, vd LateNight 23→06): picked thuộc
      //   [start, 24) hoặc [0, end).
      final endHour = endTime.hour + endTime.minute / 60;
      final isOvernight = endHour < startHour;
      bool isWithinCurrentSlot;
      if (isOvernight) {
        isWithinCurrentSlot =
            pickedHour >= startHour || pickedHour < endHour;
      } else {
        isWithinCurrentSlot = pickedHour >= startHour && pickedHour < endHour;
      }
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
      final endMinutes = slotEndTime.hour * 60 + slotEndTime.minute;
      // Slot qua đêm (LateNight): endMinutes < startMinutes (vd 23:00 → 06:00).
      // Trong trường hợp này, end "thuộc ngày hôm sau" → accept khi
      // pickedMinutes > startMinutes HOẶC pickedMinutes < endMinutes
      // (vì user có thể chọn 02:00 vẫn muốn kết thúc 06:00).
      final isOvernight = endMinutes < startMinutes;
      final isValidEnd = isOvernight
          ? (pickedMinutes > startMinutes || pickedMinutes < endMinutes)
          : (pickedMinutes > startMinutes);

      if (isValidEnd) {
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

  Color _getSlotColor(TimeSlot slot, ColorScheme? colorScheme) {
    // Màu sắc là hardcode theo slot — không phụ thuộc theme vì đã được
    // chọn tay để phân biệt trực quan giữa morning/afternoon/evening/late
    // night trên cả light/dark mode. Theme chỉ truyền vào nếu caller muốn
    // override (không dùng ở thời điểm hiện tại — giữ null-safe để gọi được
    // từ `_loadDefaultTimeSlots` lúc build xong options).
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
                        slotOptions: _slotOptions,
                        onDateSelected: _onDateSelected,
                        onOpenDatePicker: () => _openDatePicker(context),
                        onTimeSlotChanged: _onTimeSlotChanged,
                        onPreferredTimeTap: () => _selectPreferredTime(context),
                        onPreferredEndTimeTap: () => _selectPreferredEndTime(context),
                        formatDate: _formatDate,
                        formatTime: _formatTimeOfDay,
                        getSlotStartTime: _getSlotStartTime,
                        getSlotEndTime: _getSlotEndTime,
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