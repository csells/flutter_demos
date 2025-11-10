// Copyright 2025 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_step_state.dart';
import '../state/puzzle_data_state.dart';
import '../styles.dart';
import 'clue_list.dart';
import 'selected_images_view.dart';

class StepFourVerifyClueText extends StatefulWidget {
  const StepFourVerifyClueText({required this.isActive, super.key});

  final bool isActive;

  @override
  State<StepFourVerifyClueText> createState() => _StepFourVerifyClueTextState();
}

class _StepFourVerifyClueTextState extends State<StepFourVerifyClueText> {
  @override
  Widget build(BuildContext context) {
    final puzzleDataState = Provider.of<PuzzleDataState>(context);
    final appStepState = Provider.of<AppStepState>(context);
    final areCluesSet =
        puzzleDataState.crosswordData != null &&
        puzzleDataState.crosswordData!.clues.isNotEmpty;

    if (puzzleDataState.crosswordData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final crosswordData = puzzleDataState.crosswordData!;
    assert(puzzleDataState.selectedCrosswordImagesData.isNotEmpty);

    return SingleChildScrollView(
      child: Column(
        children: [
          SelectedImagesView(
            imagesData: puzzleDataState.selectedCrosswordImagesData,
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClueList(
                clues: crosswordData.clues,
                onClueUpdated: puzzleDataState.updateClue,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap a clue to edit its text.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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
                onPressed: areCluesSet
                    ? () {
                        final errors = puzzleDataState.validateGridAndClues();
                        if (errors.isNotEmpty) {
                          unawaited(
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Validation Errors'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: errors
                                        .map((e) => Text('- $e'))
                                        .toList(),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          appStepState.nextStep();
                        }
                      }
                    : null,
                style: primaryActionButtonStyle,
                child: const Text('Solve'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
