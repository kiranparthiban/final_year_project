import 'package:flutter/material.dart';
import 'package:test_audio_analysis_app/core/theme/app_colors.dart';

class WordListView extends StatelessWidget {
  final List<Map<String, dynamic>> words;
  final int highlightedIndex;
  final PageController pageController;
  final Function(int) onWordTap;

  const WordListView({
    super.key,
    required this.words,
    required this.highlightedIndex,
    required this.pageController,
    required this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: PageView.builder(
        itemCount: words.length,
        controller: pageController,
        itemBuilder: (context, index) {
          final wordData = words[index];
          final start = wordData['start'] as double;
          final end = wordData['end'] as double;
          final word = wordData['word'] as String;
          final isNow = index == highlightedIndex;

          return GestureDetector(
            onTap: () => onWordTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: isNow ? AppColors.primaryGradient : null,
                color: isNow ? null : AppColors.bgSurface,
                border: isNow
                    ? null
                    : Border.all(color: AppColors.border.withOpacity(0.5)),
                boxShadow: isNow
                    ? [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      word,
                      style: TextStyle(
                        fontSize: isNow ? 18 : 15,
                        color: isNow ? Colors.white : AppColors.textSecondary,
                        fontWeight: isNow ? FontWeight.bold : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${start.toStringAsFixed(2)}s - ${end.toStringAsFixed(2)}s",
                      style: TextStyle(
                        fontSize: 10,
                        color: isNow
                            ? Colors.white.withOpacity(0.7)
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
