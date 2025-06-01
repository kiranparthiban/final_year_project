import 'package:flutter/material.dart';

List<String> modelNames = [
  "vosk-model-small-en-us-0.15",
  "vosk-model-small-en-in-0.4",
  "vosk-model-small-hi-0.22",
];

void showModelSelectionDialog({
  required BuildContext context,
  required Function(String) onModelSelected,
}) {
  String selectedModel = "vosk-model-small-en-us-0.15";

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Select a Model'),
            content: SizedBox(
              width: double.maxFinite,
              height: 250,
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  itemCount: modelNames.length,
                  itemBuilder: (context, index) {
                    return RadioListTile<String>(
                      value: modelNames[index],
                      groupValue: selectedModel,
                      title: Text(modelNames[index]),
                      onChanged: (value) {
                        setState(() {
                          selectedModel = value!;
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onModelSelected(selectedModel);
                },
                style: ButtonStyle(
                    backgroundColor:
                        WidgetStatePropertyAll(Theme.of(context).primaryColor),
                    foregroundColor: WidgetStatePropertyAll(Colors.white)),
                child: Text('Select'),
              ),
            ],
          );
        },
      );
    },
  );
}
