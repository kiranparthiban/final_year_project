import 'package:flutter/material.dart';

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
    return SizedBox(
      height: 70,
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
            child: Card(
              color: isNow ? Theme.of(context).primaryColor : null,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text(
                      word,
                      style: TextStyle(
                        fontSize: 18,
                        color: isNow ? Colors.white : Colors.black,
                        fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      "${start.toStringAsFixed(2)}s - ${end.toStringAsFixed(2)}s",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
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
