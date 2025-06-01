import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  void _onCancel() {
    Navigator.of(context).maybePop();
  }

  void _onConfirm() {
    if (widget.isTimeLine) {
      if (widget.onConfirmTimeLine != null) {
        widget.onConfirmTimeLine!(_startController.text, _endController.text);
      }
    } else {
      if (widget.onConfirm != null) {
        widget.onConfirm!(_controller.text);
      }
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        width: 300,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              widget.isTimeLine
                  ? Column(
                      children: [
                        TextField(
                          controller: _startController,
                          keyboardType: TextInputType.number,
                          autofocus: false,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(","),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Start (Sec)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: _endController,
                          keyboardType: TextInputType.number,
                          autofocus: false,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(","),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'End (Sec)',
                            border: OutlineInputBorder(),
                          ),
                        )
                      ],
                    )
                  : TextField(
                      controller: _controller,
                      autofocus: false,
                      decoration: const InputDecoration(
                        labelText: 'Edit',
                        border: OutlineInputBorder(),
                      ),
                    ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _onCancel,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
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
}
