import 'package:flutter/material.dart';
import 'package:test_audio_analysis_app/core/theme/app_colors.dart';

class LoadingIndicator extends StatelessWidget {
  final double progress;
  final String message;

  const LoadingIndicator({
    super.key,
    required this.progress,
    this.message = "Loading...",
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.graphic_eq_rounded,
            size: 40,
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.bgSurface,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "${(progress * 100).toStringAsFixed(0)}%",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
