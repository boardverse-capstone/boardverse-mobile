import 'package:flutter/material.dart';

class GpsWarningBanner extends StatelessWidget {
  final VoidCallback? onEnableGps;
  final VoidCallback? onEnterManually;

  const GpsWarningBanner({
    super.key,
    this.onEnableGps,
    this.onEnterManually,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_off,
                color: Colors.amber.shade800,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GPS đang tắt',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bật GPS để xem các quán cafe gần bạn hoặc nhập vị trí thủ công.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.amber.shade900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onEnableGps,
                  icon: const Icon(Icons.gps_fixed, size: 18),
                  label: const Text('Bật GPS'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEnterManually,
                  icon: const Icon(Icons.edit_location_alt, size: 18),
                  label: const Text('Nhập tay'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
