import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_audio_analysis_app/core/theme/app_colors.dart';

class EditDrawer extends StatefulWidget {
  final String title;
  final String initialValue;
  final bool isTimeLine;
  final void Function(String)? onConfirm;
  final void Function(String, String)? onConfirmTimeLine;

  const EditDrawer({
    super.key,
    required this.title,
    this.initialValue = '',
    this.onConfirm,
    this.isTimeLine = false,
    this.onConfirmTimeLine,
  });

  @override
  State<EditDrawer> createState() => _EditDrawerState();
}

class _EditDrawerState extends State<EditDrawer> {
  late TextEditingController _controller;
  late TextEditingController _startController;
  late TextEditingController _endController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    if (widget.isTimeLine && widget.initialValue.contains(' - ')) {
      final parts = widget.initialValue.split(' - ');
      _startController = TextEditingController(text: parts[0]);
      _endController =
          TextEditingController(text: parts.length > 1 ? parts[1] : '');
    } else {
      _startController = TextEditingController();
      _endController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _onCancel() => Navigator.of(context).maybePop();

  void _onConfirm() {
    if (widget.isTimeLine) {
      widget.onConfirmTimeLine?.call(_startController.text, _endController.text);
    } else {
      widget.onConfirm?.call(_controller.text);
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        backgroundColor: AppColors.bgCard,
        width: 300,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              widget.isTimeLine
                  ? Column(
                      children: [
                        _buildField(_startController, 'Start (Sec)'),
                        const SizedBox(height: 12),
                        _buildField(_endController, 'End (Sec)'),
                      ],
                    )
                  : _buildField(_controller, 'Edit'),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _onCancel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onConfirm,
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: label.contains('Sec') ? TextInputType.number : null,
      autofocus: false,
      inputFormatters: label.contains('Sec')
          ? [FilteringTextInputFormatter.deny(",")]
          : null,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryColor),
        ),
        filled: true,
        fillColor: AppColors.bgSurface,
      ),
    );
  }
}
