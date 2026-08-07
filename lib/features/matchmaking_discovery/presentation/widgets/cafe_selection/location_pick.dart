/// Kết quả trả về từ [LocationPickerDialog].
class LocationPick {
  final String label;
  final double latitude;
  final double longitude;

  const LocationPick({
    required this.label,
    required this.latitude,
    required this.longitude,
  });
}