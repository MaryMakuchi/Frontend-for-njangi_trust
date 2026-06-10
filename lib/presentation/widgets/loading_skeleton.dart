import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius = 8,
  });

  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.white,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: const [
          LoadingSkeleton(height: 120, borderRadius: 16),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: LoadingSkeleton(height: 80, borderRadius: 12)),
              SizedBox(width: 12),
              Expanded(child: LoadingSkeleton(height: 80, borderRadius: 12)),
            ],
          ),
          SizedBox(height: 16),
          LoadingSkeleton(height: 200, borderRadius: 16),
        ],
      ),
    );
  }
}
