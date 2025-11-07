import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/grid_cell.dart';
import '../state/app_step_state.dart';
import '../state/puzzle_data_state.dart';
import '../styles.dart';
import 'grid_view.dart';
import 'selected_images_view.dart';
import 'step_activation_mixin.dart';

class StepThreeVerifyGridContents extends StatefulWidget {
  const StepThreeVerifyGridContents({required this.isActive, super.key});

  final bool isActive;

  @override
  State<StepThreeVerifyGridContents> createState() =>
      _StepThreeVerifyGridContentsState();
}

class _StepThreeVerifyGridContentsState
    extends State<StepThreeVerifyGridContents>
    with StepActivationMixin<StepThreeVerifyGridContents> {
  @override
  bool get isActive => widget.isActive;

  @override
  void onActivated() {
    final puzzleDataState = Provider.of<PuzzleDataState>(
      context,
      listen: false,
    );
    assert(puzzleDataState.isGridClear);
  }

  void _showEditCellDialog(BuildContext context, int index) {
    final puzzleDataState = Provider.of<PuzzleDataState>(
      context,
      listen: false,
    );
    unawaited(
      showDialog(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Edit Cell'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                puzzleDataState.setCellType(
                  index,
                  GridCellType.empty,
                  clearClueNumber: true,
                );
                Navigator.pop(context);
              },
              child: const Text('Empty (white)'),
            ),
            SimpleDialogOption(
              onPressed: () {
                puzzleDataState.setCellType(
                  index,
                  GridCellType.inactive,
                  clearClueNumber: true,
                );
                Navigator.pop(context);
              },
              child: const Text('Inactive (black)'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _showEnterNumberDialog(context, index);
              },
              child: const Text('Numbered'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEnterNumberDialog(BuildContext context, int index) {
    final puzzleDataState = Provider.of<PuzzleDataState>(
      context,
      listen: false,
    );
    final controller = TextEditingController();
    final errorNotifier = ValueNotifier<String?>(null);
    final focusNode = FocusNode();

    unawaited(
      showDialog(
        context: context,
        builder: (context) => KeyboardListener(
          focusNode: focusNode,
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.pop(context);
              } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                final number = int.tryParse(controller.text);
                if (number != null) {
                  puzzleDataState.setCellType(
                    index,
                    GridCellType.empty,
                    clueNumber: number,
                  );
                  Navigator.pop(context);
                }
              }
            }
          },
          child: ValueListenableBuilder<String?>(
            valueListenable: errorNotifier,
            builder: (context, errorText, child) => AlertDialog(
              title: const Text('Enter Number'),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(errorText: errorText),
                onChanged: (value) {
                  if (int.tryParse(value) == null) {
                    errorNotifier.value = 'Invalid number';
                  } else {
                    errorNotifier.value = null;
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: errorText == null
                      ? () {
                          final number = int.tryParse(controller.text);
                          if (number != null) {
                            puzzleDataState.setCellType(
                              index,
                              GridCellType.empty,
                              clueNumber: number,
                            );
                            Navigator.pop(context);
                          }
                        }
                      : null,
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      Consumer2<PuzzleDataState, AppStepState>(
        builder: (context, puzzleDataState, appStepState, child) {
          if (puzzleDataState.crosswordData == null) {
            return const SizedBox.shrink();
          }
          assert(puzzleDataState.selectedCrosswordImagesData.isNotEmpty);
          return Column(
            children: [
              SelectedImagesView(
                imagesData: puzzleDataState.selectedCrosswordImagesData,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: CrosswordGridView(
                        key: ValueKey(puzzleDataState.crosswordData!.grid),
                        grid: puzzleDataState.crosswordData!.grid,
                        onCellTapped: (index) {
                          _showEditCellDialog(context, index);
                        },
                      ),
                    ),
                    Text(
                      'Tap a cell to correct its contents.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: appStepState.previousStep,
                    style: secondaryActionButtonStyle,
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: appStepState.nextStep,
                    style: primaryActionButtonStyle,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ],
          );
        },
      );
}
