import 'package:flutter/material.dart';

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
          const SizedBox(height: 10),
          CircularProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[350],
          ),
          const SizedBox(height: 5),
          Text("${(progress * 100).toStringAsFixed(1)}%"),
          Text(message),
        ],
      ),
    );
  }
}
