import 'package:equatable/equatable.dart';

/// Entity cho request gọi Survey / Solo Personalized / Group Discovery.
///
/// Tất cả fields đều optional — backend sẽ filter theo những trường được set.
///
/// File này được tách riêng để làm entry-point duy nhất cho mọi request DTO
/// của Discovery API, tránh vòng lặp import ngược giữa entity và model.
class DiscoveryRequestEntity extends Equatable {
  /// Số người chơi mong muốn.
  final int? playerCount;

  /// Danh sách category IDs để lọc.
  final List<String>? categoryIds;

  /// Danh sách khung thời gian chơi.
  /// Giá trị: 'under30', '30to60', 'over60' (theo backend enum).
  final List<String>? preferredDurations;

  /// Danh sách weight ranges (1=Light, 2=MediumLight, 3=Medium, 4=MediumHeavy, 5=Heavy).
  final List<int>? weightRanges;

  /// Trình độ người chơi (1=Beginner, 2=Casual, 3=Intermediate, 4=Advanced, 5=Expert).
  final int? experienceLevel;

  /// Từ khóa tìm kiếm.
  final String? searchKeyword;

  const DiscoveryRequestEntity({
    this.playerCount,
    this.categoryIds,
    this.preferredDurations,
    this.weightRanges,
    this.experienceLevel,
    this.searchKeyword,
  });

  /// Kiểm tra có filter nào đang active không.
  bool get hasFilters =>
      playerCount != null ||
      (categoryIds != null && categoryIds!.isNotEmpty) ||
      (preferredDurations != null && preferredDurations!.isNotEmpty) ||
      (weightRanges != null && weightRanges!.isNotEmpty) ||
      experienceLevel != null ||
      (searchKeyword != null && searchKeyword!.isNotEmpty);

  @override
  List<Object?> get props => [
        playerCount, categoryIds, preferredDurations,
        weightRanges, experienceLevel, searchKeyword,
      ];
}
