import 'package:equatable/equatable.dart';

/// Entity mô tả bộ lọc tìm kiếm
class SearchFilterEntity extends Equatable {
  // Game filters
  final String? query;
  final String? category;
  final int? minPlayers;
  final int? maxPlayers;
  final int? estimatedMinutesMax;

  // Location filters (BR-10)
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final int? minKarma; // Lọc theo điểm uy tín tối thiểu

  // Time filter
  final DateTime? scheduledTime;
  final DateTime? scheduledDate;

  const SearchFilterEntity({
    this.query,
    this.category,
    this.minPlayers,
    this.maxPlayers,
    this.estimatedMinutesMax,
    this.latitude,
    this.longitude,
    this.radiusKm,
    this.minKarma,
    this.scheduledTime,
    this.scheduledDate,
  });

  /// Tạo bộ lọc mặc định
  static const SearchFilterEntity empty = SearchFilterEntity();

  /// Kiểm tra xem có bất kỳ filter nào không
  bool get hasActiveFilters =>
      query != null ||
      category != null ||
      minPlayers != null ||
      maxPlayers != null ||
      estimatedMinutesMax != null ||
      radiusKm != null ||
      minKarma != null ||
      scheduledTime != null ||
      scheduledDate != null;

  /// Tạo bản sao với các giá trị mới
  SearchFilterEntity copyWith({
    String? query,
    String? category,
    int? minPlayers,
    int? maxPlayers,
    int? estimatedMinutesMax,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int? minKarma,
    DateTime? scheduledTime,
    DateTime? scheduledDate,
    bool clearQuery = false,
    bool clearCategory = false,
    bool clearMinPlayers = false,
    bool clearMaxPlayers = false,
    bool clearEstimatedMinutesMax = false,
    bool clearRadiusKm = false,
    bool clearMinKarma = false,
    bool clearScheduledTime = false,
    bool clearScheduledDate = false,
  }) {
    return SearchFilterEntity(
      query: clearQuery ? null : (query ?? this.query),
      category: clearCategory ? null : (category ?? this.category),
      minPlayers: clearMinPlayers ? null : (minPlayers ?? this.minPlayers),
      maxPlayers: clearMaxPlayers ? null : (maxPlayers ?? this.maxPlayers),
      estimatedMinutesMax: clearEstimatedMinutesMax
          ? null
          : (estimatedMinutesMax ?? this.estimatedMinutesMax),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: clearRadiusKm ? null : (radiusKm ?? this.radiusKm),
      minKarma: clearMinKarma ? null : (minKarma ?? this.minKarma),
      scheduledTime: clearScheduledTime ? null : (scheduledTime ?? this.scheduledTime),
      scheduledDate:
          clearScheduledDate ? null : (scheduledDate ?? this.scheduledDate),
    );
  }

  /// Reset tất cả filters
  SearchFilterEntity clear() => const SearchFilterEntity();

  @override
  List<Object?> get props => [
        query,
        category,
        minPlayers,
        maxPlayers,
        estimatedMinutesMax,
        latitude,
        longitude,
        radiusKm,
        minKarma,
        scheduledTime,
        scheduledDate,
      ];
}
