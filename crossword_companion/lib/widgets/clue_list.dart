import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/clue.dart';

class ClueList extends StatelessWidget {
  const ClueList({required this.clues, required this.onClueUpdated, super.key});
  final List<Clue> clues;
  final Function(Clue) onClueUpdated;

  @override
  Widget build(BuildContext context) {
    final acrossClues = clues
        .where((c) => c.direction == ClueDirection.across)
        .toList();
    final downClues = clues
        .where((c) => c.direction == ClueDirection.down)
        .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Across', style: Theme.of(context).textTheme.headlineSmall),
              ...acrossClues.map((c) => _buildClueItem(context, c)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Down', style: Theme.of(context).textTheme.headlineSmall),
              ...downClues.map((c) => _buildClueItem(context, c)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClueItem(BuildContext context, Clue clue) => InkWell(
    onTap: () => _editClue(context, clue),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('${clue.number}. ${clue.text}'),
    ),
  );

  void _editClue(BuildContext context, Clue clue) {
    final textController = TextEditingController(text: clue.text);
    final numberController = TextEditingController(
      text: clue.number.toString(),
    );
    final focusNode = FocusNode();

    unawaited(
      showDialog(
        context: context,
        builder: (context) => KeyboardListener(
          focusNode: focusNode,
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.of(context).pop();
              } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                final newClue = clue.copyWith(
                  text: textController.text,
                  number: int.tryParse(numberController.text) ?? clue.number,
                );
                onClueUpdated(newClue);
                Navigator.of(context).pop();
              }
            }
          },
          child: AlertDialog(
            title: Text('Edit Clue ${clue.number} ${clue.direction.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(labelText: 'Clue Number'),
                  keyboardType: TextInputType.number,
                  autofocus: true,
                ),
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(labelText: 'Clue Text'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final newClue = clue.copyWith(
                    text: textController.text,
                    number: int.tryParse(numberController.text) ?? clue.number,
                  );
                  onClueUpdated(newClue);
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
