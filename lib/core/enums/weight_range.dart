/// Weight range enum theo chuẩn BGG complexity weight.
///
/// Backend dùng số nguyên 1-5 tương ứng với các mức độ phức tạp của game.
/// Được dùng trong request body của Survey, Solo-Personalized, Group Discovery.
///
/// ## BGG Weight Scale
/// - Weight 1.0–1.99: Light (party, abstract)
/// - Weight 2.0–2.99: Medium-Light đến Medium (gateway games)
/// - Weight 3.0–3.49: Medium-Heavy (strategy)
/// - Weight 3.5–4.49: Heavy (deep strategy)
/// - Weight 4.5–5.0:   Very Heavy (epic experience)
///
/// Backend enum mapping: Light=1, MediumLight=2, Medium=3, MediumHeavy=4, Heavy=5
enum WeightRange {
  light,
  mediumLight,
  medium,
  mediumHeavy,
  heavy,
}

extension WeightRangeX on WeightRange {
  /// Giá trị gửi lên backend (số nguyên 1-5).
  int get apiValue {
    switch (this) {
      case WeightRange.light:
        return 1;
      case WeightRange.mediumLight:
        return 2;
      case WeightRange.medium:
        return 3;
      case WeightRange.mediumHeavy:
        return 4;
      case WeightRange.heavy:
        return 5;
    }
  }

  /// Nhãn hiển thị tiếng Việt.
  String get displayLabel {
    switch (this) {
      case WeightRange.light:
        return 'Nhẹ';
      case WeightRange.mediumLight:
        return 'Trung bình - Nhẹ';
      case WeightRange.medium:
        return 'Trung bình';
      case WeightRange.mediumHeavy:
        return 'Trung bình - Nặng';
      case WeightRange.heavy:
        return 'Nặng';
    }
  }

  /// Khoảng BGG weight để hiển thị.
  String get displayRange {
    switch (this) {
      case WeightRange.light:
        return '1.0 – 1.99';
      case WeightRange.mediumLight:
        return '2.0 – 2.99';
      case WeightRange.medium:
        return '3.0 – 3.49';
      case WeightRange.mediumHeavy:
        return '3.5 – 3.99';
      case WeightRange.heavy:
        return '4.0+';
    }
  }

  /// Icon tương ứng để hiển thị.
  String get icon {
    switch (this) {
      case WeightRange.light:
        return '🌱';
      case WeightRange.mediumLight:
        return '⚡';
      case WeightRange.medium:
        return '🎯';
      case WeightRange.mediumHeavy:
        return '🔥';
      case WeightRange.heavy:
        return '💎';
    }
  }

  /// Map từ giá trị backend (int 1-5) sang enum.
  /// Trả về null nếu giá trị không hợp lệ.
  static WeightRange? tryFromApiValue(int? value) {
    if (value == null) return null;
    switch (value) {
      case 1:
        return WeightRange.light;
      case 2:
        return WeightRange.mediumLight;
      case 3:
        return WeightRange.medium;
      case 4:
        return WeightRange.mediumHeavy;
      case 5:
        return WeightRange.heavy;
      default:
        return null;
    }
  }

  /// Chuyển weight number (BGG weight) sang enum gần nhất.
  /// Ví dụ: weight 2.5 → MediumLight (range 2.0-2.99)
  static WeightRange fromWeightValue(double? weight) {
    if (weight == null) return WeightRange.medium; // default
    if (weight <= 1.99) return WeightRange.light;
    if (weight <= 2.99) return WeightRange.mediumLight;
    if (weight <= 3.49) return WeightRange.medium;
    if (weight <= 3.99) return WeightRange.mediumHeavy;
    return WeightRange.heavy;
  }
}
