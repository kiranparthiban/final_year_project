import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> saveWaveformAsImage(
    {required BuildContext context, required GlobalKey waveformKey}) async {
  try {
    // Request storage permission
    print("Save Render...");
    var status = await Permission.manageExternalStorage.request();

    if (!status.isGranted) {
      print('Storage permission denied');
      return;
    }

    // Capture the widget as image
    RenderRepaintBoundary boundary =
        waveformKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ImageByteFormat.png);

    if (byteData != null) {
      final pngBytes = byteData.buffer.asUint8List();

      // Get Downloads directory
      final downloadsDir = Directory('/storage/emulated/0/Download');

      // Ensure directory exists
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Generate file path
      final filePath =
          '${downloadsDir.path}/waveform_${DateTime.now().millisecondsSinceEpoch}.png';

      final file = File(filePath);
      await file.writeAsBytes(pngBytes);
      print('✅ Waveform image saved to: $filePath');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Waveform saved to Downloads!")),
      );
    }
  } catch (e) {
    print("❌ Error saving waveform image: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to save waveform.")),
    );
  }
}
