import 'dart:typed_data';
import 'package:flutter/material.dart';

class ZoomableImage extends StatefulWidget {
  final Uint8List imageBytes;
  final BoxFit fit;
  final String title;

  const ZoomableImage({
    Key? key,
    required this.imageBytes,
    this.fit = BoxFit.contain,
    required this.title,
  }) : super(key: key);

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showZoomableDialog(context);
      },
      child: Image.memory(
        widget.imageBytes,
        fit: widget.fit,
      ),
    );
  }

  void _showZoomableDialog(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(8),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: screenSize.height * 0.85,
            maxWidth: screenSize.width * 0.95,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.memory(
                      widget.imageBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
