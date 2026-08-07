import 'package:flutter/material.dart';

import 'location_pick.dart';

/// Dialog cho phép user chọn vị trí đại diện (theo thành phố) để ghi lên
/// profile. Dùng khi thiết bị không có GPS hoặc app chưa tích hợp
/// `geolocator` — user chọn thành phố → lưu lat/lng tương ứng lên server.
///
/// Các tọa độ dưới đây là trung tâm thành phố lớn tại Việt Nam, đủ để
/// backend `/api/cafes/nearby/me` trả về quán trong bán kính 15 km mặc định.
class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({super.key});

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  /// Danh sách thành phố preset. Cập nhật/thêm nếu mở rộng khu vực.
  static const _presets = <LocationPick>[
    LocationPick(label: 'TP. Hồ Chí Minh', latitude: 10.7769, longitude: 106.7009),
    LocationPick(label: 'Hà Nội', latitude: 21.0285, longitude: 105.8542),
    LocationPick(label: 'Đà Nẵng', latitude: 16.0544, longitude: 108.2022),
    LocationPick(label: 'Hải Phòng', latitude: 20.8449, longitude: 106.6881),
    LocationPick(label: 'Cần Thơ', latitude: 10.0452, longitude: 105.7469),
    LocationPick(label: 'Nha Trang', latitude: 12.2388, longitude: 109.1967),
    LocationPick(label: 'Vũng Tàu', latitude: 10.3460, longitude: 107.0843),
  ];

  LocationPick? _selected = _presets.first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Cập nhật vị trí của bạn'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chọn khu vực để hệ thống tìm quán cafe xung quanh bạn.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LocationPick>(
              initialValue: _selected,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Khu vực',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final p in _presets)
                  DropdownMenuItem<LocationPick>(
                    value: p,
                    child: Text(p.label),
                  ),
              ],
              onChanged: (v) => setState(() => _selected = v),
            ),
            const SizedBox(height: 8),
            if (_selected != null)
              Text(
                'Lat ${_selected!.latitude.toStringAsFixed(4)}, '
                'Lng ${_selected!.longitude.toStringAsFixed(4)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(_selected),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}