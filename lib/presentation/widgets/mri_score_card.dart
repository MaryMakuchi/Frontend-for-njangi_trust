import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';

class MriScoreCard extends StatelessWidget {
  const MriScoreCard({
    super.key,
    required this.score,
    required this.trend,
    this.onTap,
    this.compact = false,
  });

  final double score;
  final double trend;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final gaugeSize = compact ? 64.0 : 80.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(compact ? 16 : 20),
        decoration: BoxDecoration(
          gradient: AppColors.richGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.indigo.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MRI Score',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reliability Index',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        Formatters.percentage(trend),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: gaugeSize,
              height: gaugeSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Solid backing disc for contrast
                  Container(
                    width: gaugeSize,
                    height: gaugeSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryDark.withValues(alpha: 0.55),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: gaugeSize - 6,
                    height: gaugeSize - 6,
                    child: CircularProgressIndicator(
                      value: score / 10,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColors.white.withValues(alpha: 0.35),
                      valueColor: const AlwaysStoppedAnimation(AppColors.white),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Formatters.mriScore(score),
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: compact ? 20 : 24,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          shadows: [
                            Shadow(
                              color: AppColors.primaryDark.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '/ 10',
                        style: TextStyle(
                          color: AppColors.blush,
                          fontSize: compact ? 10 : 11,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
