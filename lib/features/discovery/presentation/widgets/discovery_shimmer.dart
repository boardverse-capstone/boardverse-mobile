import 'package:flutter/material.dart';

import '../../../../core/theme/app_shimmer.dart';

/// Shimmer skeleton cho discovery results.
class DiscoveryShimmer extends StatelessWidget {
  final int itemCount;

  const DiscoveryShimmer({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const _DiscoveryCardShimmer(),
    );
  }
}

class _DiscoveryCardShimmer extends StatelessWidget {
  const _DiscoveryCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          AppShimmer.box(
            context: context,
            width: 80,
            height: 80,
            borderRadius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer.box(
                  context: context,
                  width: 140,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AppShimmer.box(
                      context: context,
                      width: 60,
                      height: 12,
                      borderRadius: 4,
                    ),
                    const SizedBox(width: 8),
                    AppShimmer.box(
                      context: context,
                      width: 50,
                      height: 12,
                      borderRadius: 4,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AppShimmer.box(
                      context: context,
                      width: 80,
                      height: 20,
                      borderRadius: 10,
                    ),
                    const SizedBox(width: 8),
                    AppShimmer.box(
                      context: context,
                      width: 50,
                      height: 20,
                      borderRadius: 10,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
