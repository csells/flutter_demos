import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_step_state.dart';
import '../state/puzzle_data_state.dart';
import '../styles.dart';
import 'selected_images_view.dart';
import 'step_activation_mixin.dart';

class StepTwoVerifyGridSize extends StatefulWidget {
  const StepTwoVerifyGridSize({required this.isActive, super.key});

  final bool isActive;

  @override
  State<StepTwoVerifyGridSize> createState() => _StepTwoVerifyGridSizeState();
}

class _StepTwoVerifyGridSizeState extends State<StepTwoVerifyGridSize>
    with StepActivationMixin<StepTwoVerifyGridSize> {
  int? _newWidth;
  int? _newHeight;

  @override
  bool get isActive => widget.isActive;

  @override
  void onActivated() {
    final puzzleDataState = Provider.of<PuzzleDataState>(
      context,
      listen: false,
    );
    assert(puzzleDataState.isGridClear);

    if (puzzleDataState.selectedCrosswordImages.isNotEmpty &&
        puzzleDataState.crosswordData == null &&
        !puzzleDataState.isInferringCrosswordData &&
        puzzleDataState.inferenceError == null) {
      unawaited(puzzleDataState.inferCrosswordData());
    }
  }

  @override
  Widget build(BuildContext context) {
    final puzzleDataState = Provider.of<PuzzleDataState>(context);
    final appStepState = Provider.of<AppStepState>(context);

    if (puzzleDataState.isInferringCrosswordData) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 16),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Inferring crossword data...'),
            SizedBox(height: 8),
            Text('(This could take a couple of minutes)'),
          ],
        ),
      );
    }

    if (puzzleDataState.inferenceError != null) {
      return Column(
        children: [
          Text(
            'Error: ${puzzleDataState.inferenceError}\n'
            'Please go back and try again.',
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: appStepState.previousStep,
                child: const Text('Back'),
              ),
            ],
          ),
        ],
      );
    }

    if (puzzleDataState.crosswordData == null) {
      // This can happen if the inference fails.
      return Column(
        children: [
          const Text(
            'Could not infer crossword data. Please go back and try again.',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: appStepState.previousStep,
                child: const Text('Back'),
              ),
            ],
          ),
        ],
      );
    }

    final crosswordData = puzzleDataState.crosswordData!;
    _newWidth ??= crosswordData.width;
    _newHeight ??= crosswordData.height;

    assert(puzzleDataState.selectedCrosswordImagesData.isNotEmpty);

    return Column(
      children: [
        SelectedImagesView(
          imagesData: puzzleDataState.selectedCrosswordImagesData,
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 32,
            runSpacing: 32,
            children: [
              // Rows Stepper
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      _buildCircularChevronButton(
                        icon: Icons.keyboard_arrow_up,
                        onPressed: () {
                          setState(() {
                            _newHeight = (_newHeight ?? 0) + 1;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildCircularChevronButton(
                        icon: Icons.keyboard_arrow_down,
                        onPressed: () {
                          if ((_newHeight ?? 0) > 1) {
                            setState(() {
                              _newHeight = (_newHeight ?? 0) - 1;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_newHeight ?? 0} Rows',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              // Columns Stepper
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildCircularChevronButton(
                    icon: Icons.keyboard_arrow_left,
                    onPressed: () {
                      if ((_newWidth ?? 0) > 1) {
                        setState(() {
                          _newWidth = (_newWidth ?? 0) - 1;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_newWidth ?? 0} Columns',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  _buildCircularChevronButton(
                    icon: Icons.keyboard_arrow_right,
                    onPressed: () {
                      setState(() {
                        _newWidth = (_newWidth ?? 0) + 1;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
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
              onPressed: puzzleDataState.crosswordData != null
                  ? () {
                      final currentData = puzzleDataState.crosswordData!;
                      puzzleDataState.updateCrosswordData(
                        currentData.copyWith(
                          width: _newWidth ?? currentData.width,
                          height: _newHeight ?? currentData.height,
                        ),
                      );

                      appStepState.nextStep();
                    }
                  : null,
              style: primaryActionButtonStyle,
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircularChevronButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      shape: const CircleBorder(),
      padding: const EdgeInsets.all(8),
      side: const BorderSide(color: Colors.black),
      backgroundColor: Colors.transparent,
    ),
    child: Icon(icon, color: Colors.black),
  );
}
