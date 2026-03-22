import 'package:flutter/material.dart';
import 'package:test_audio_analysis_app/core/services/model_manager.dart';
import 'package:test_audio_analysis_app/core/theme/app_colors.dart';

void showModelSelectionDialog({
  required BuildContext context,
  required Function(String modelDir, WhisperModel model) onModelSelected,
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
  final Function(String modelDir, WhisperModel model) onModelSelected;

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
    return Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.accentGradient.createShader(bounds),
                  child: const Icon(Icons.model_training,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Select Speech Model',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose a Whisper model for transcription',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            ...availableModels.map((model) {
              final isDownloaded = downloadStatus[model.name] ?? false;
              final isDownloading = downloadingModel == model.name;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: isDownloaded
                        ? () async {
                            final dir = await ModelManager.modelDir(model);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              widget.onModelSelected(dir, model);
                            }
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: AppColors.bgSurface,
                        border: Border.all(
                          color: isDownloaded
                              ? AppColors.primaryColor.withOpacity(0.3)
                              : AppColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  model.displayName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDownloaded
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              if (isDownloading)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryColor,
                                  ),
                                )
                              else if (isDownloaded)
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.accentGreen, size: 20)
                              else
                                GestureDetector(
                                  onTap: () => _downloadModel(model),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.accentBlue.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.download_rounded,
                                            color: AppColors.accentBlue,
                                            size: 14),
                                        SizedBox(width: 4),
                                        Text(
                                          'Download',
                                          style: TextStyle(
                                            color: AppColors.accentBlue,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (isDownloading) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: downloadProgress,
                                minHeight: 4,
                                backgroundColor: AppColors.bgCard,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryColor),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              downloadStatusText,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: downloadingModel == null
                    ? () => Navigator.of(context).pop()
                    : null,
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
