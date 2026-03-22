import 'package:flutter/material.dart';
import 'package:test_audio_analysis_app/core/services/model_manager.dart';

void showModelSelectionDialog({
  required BuildContext context,
  required Function(String modelDir) onModelSelected,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return _ModelSelectionDialog(onModelSelected: onModelSelected);
    },
  );
}

class _ModelSelectionDialog extends StatefulWidget {
  final Function(String modelDir) onModelSelected;

  const _ModelSelectionDialog({required this.onModelSelected});

  @override
  State<_ModelSelectionDialog> createState() => _ModelSelectionDialogState();
}

class _ModelSelectionDialogState extends State<_ModelSelectionDialog> {
  Map<String, bool> downloadStatus = {};
  String? downloadingModel;
  double downloadProgress = 0;
  String downloadStatusText = '';

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    for (final model in availableModels) {
      final downloaded = await ModelManager.isModelDownloaded(model);
      if (mounted) {
        setState(() {
          downloadStatus[model.name] = downloaded;
        });
      }
    }
  }

  Future<void> _downloadModel(WhisperModel model) async {
    setState(() {
      downloadingModel = model.name;
      downloadProgress = 0;
    });

    try {
      await ModelManager.downloadModel(
        model,
        onProgress: (progress, status) {
          if (mounted) {
            setState(() {
              downloadProgress = progress;
              downloadStatusText = status;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          downloadStatus[model.name] = true;
          downloadingModel = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          downloadingModel = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Speech Model'),
      content: SizedBox(
        width: double.maxFinite,
        height: 200,
        child: ListView.builder(
          itemCount: availableModels.length,
          itemBuilder: (context, index) {
            final model = availableModels[index];
            final isDownloaded = downloadStatus[model.name] ?? false;
            final isDownloading = downloadingModel == model.name;

            return Card(
              child: ListTile(
                title: Text(model.displayName),
                subtitle: isDownloading
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(value: downloadProgress),
                          const SizedBox(height: 4),
                          Text(
                            downloadStatusText,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      )
                    : Text(isDownloaded ? 'Ready' : 'Not downloaded'),
                trailing: isDownloading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : isDownloaded
                        ? Icon(Icons.check_circle,
                            color: Theme.of(context).primaryColor)
                        : IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () => _downloadModel(model),
                          ),
                onTap: isDownloaded
                    ? () async {
                        final dir = await ModelManager.modelDir(model);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          widget.onModelSelected(dir);
                        }
                      }
                    : null,
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: downloadingModel == null
              ? () => Navigator.of(context).pop()
              : null,
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
