import 'package:equatable/equatable.dart';

/// Khung thời gian chơi trung bình — map enum `PlayTimeRange` từ backend.
/// Dùng trong `SearchFilterEntity.durationRanges` (multi-select).
enum DurationRange {
  under30, // < 30 phút
  thirtyToSixty, // 30-60 phút
  over60, // > 60 phút
}

extension DurationRangeX on DurationRange {
  /// Tên enum theo chuẩn backend (upper camel case) — dùng khi serialize
  /// thành query string.
  String get apiValue {
    switch (this) {
      case DurationRange.under30:
        return 'Under30';
      case DurationRange.thirtyToSixty:
        return 'ThirtyToSixty';
      case DurationRange.over60:
        return 'Over60';
    }
  }

  /// Map từ chuỗi backend trả về → enum (fallback về `thirtyToSixty` nếu
  /// không nhận diện được).
  static DurationRange? tryFromApi(String? value) {
    switch (value) {
      case 'Under30':
        return DurationRange.under30;
      case 'ThirtyToSixty':
        return DurationRange.thirtyToSixty;
      case 'Over60':
        return DurationRange.over60;
      default:
        return null;
    }
  }
}

/// Entity mô tả bộ lọc tìm kiếm
class SearchFilterEntity extends Equatable {
  // Game filters
  final String? query;

  /// Tên category (String, dùng cho Mock UI). Ưu tiên dùng [categoryIds]
  /// cho backend mới.
  final String? category;

  /// Danh sách ID category (multi-select) — dùng cho `/api/v1/board-games?category_ids=...`
  final List<String>? categoryIds;

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

  /// Khung thời gian chơi (multi-select) — backend `duration_range`.
  final List<DurationRange>? durationRanges;

  // Pagination (cho API mới)
  final int? pageNumber;
  final int? pageSize;

  const SearchFilterEntity({
    this.query,
    this.category,
    this.categoryIds,
    this.minPlayers,
    this.maxPlayers,
    this.estimatedMinutesMax,
    this.latitude,
    this.longitude,
    this.radiusKm,
    this.minKarma,
    this.scheduledTime,
    this.scheduledDate,
    this.durationRanges,
    this.pageNumber,
    this.pageSize,
  });

  /// Tạo bộ lọc mặc định
  static const SearchFilterEntity empty = SearchFilterEntity();

  /// Kiểm tra xem có bất kỳ filter nào không
  bool get hasActiveFilters =>
      query != null ||
      category != null ||
      categoryIds != null ||
      minPlayers != null ||
      maxPlayers != null ||
      estimatedMinutesMax != null ||
      radiusKm != null ||
      minKarma != null ||
      scheduledTime != null ||
      scheduledDate != null ||
      durationRanges != null;

  /// Tạo bản sao với các giá trị mới
  SearchFilterEntity copyWith({
    String? query,
    String? category,
    List<String>? categoryIds,
    int? minPlayers,
    int? maxPlayers,
    int? estimatedMinutesMax,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int? minKarma,
    DateTime? scheduledTime,
    DateTime? scheduledDate,
    List<DurationRange>? durationRanges,
    int? pageNumber,
    int? pageSize,
    bool clearQuery = false,
    bool clearCategory = false,
    bool clearCategoryIds = false,
    bool clearMinPlayers = false,
    bool clearMaxPlayers = false,
    bool clearEstimatedMinutesMax = false,
    bool clearRadiusKm = false,
    bool clearMinKarma = false,
    bool clearScheduledTime = false,
    bool clearScheduledDate = false,
    bool clearDurationRanges = false,
  }) {
    return SearchFilterEntity(
      query: clearQuery ? null : (query ?? this.query),
      category: clearCategory ? null : (category ?? this.category),
      categoryIds:
          clearCategoryIds ? null : (categoryIds ?? this.categoryIds),
      minPlayers: clearMinPlayers ? null : (minPlayers ?? this.minPlayers),
      maxPlayers: clearMaxPlayers ? null : (maxPlayers ?? this.maxPlayers),
      estimatedMinutesMax: clearEstimatedMinutesMax
          ? null
          : (estimatedMinutesMax ?? this.estimatedMinutesMax),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: clearRadiusKm ? null : (radiusKm ?? this.radiusKm),
      minKarma: clearMinKarma ? null : (minKarma ?? this.minKarma),
      scheduledTime:
          clearScheduledTime ? null : (scheduledTime ?? this.scheduledTime),
      scheduledDate:
          clearScheduledDate ? null : (scheduledDate ?? this.scheduledDate),
      durationRanges: clearDurationRanges
          ? null
          : (durationRanges ?? this.durationRanges),
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  /// Reset tất cả filters
  SearchFilterEntity clear() => const SearchFilterEntity();

  @override
  List<Object?> get props => [
        query,
        category,
        categoryIds,
        minPlayers,
        maxPlayers,
        estimatedMinutesMax,
        latitude,
        longitude,
        radiusKm,
        minKarma,
        scheduledTime,
        scheduledDate,
        durationRanges,
        pageNumber,
        pageSize,
      ];
}
