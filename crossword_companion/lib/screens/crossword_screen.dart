// Copyright 2025 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:vector_graphics/vector_graphics.dart';

import '../state/app_step_state.dart';
import '../widgets/step1_select_image.dart';
import '../widgets/step2_verify_grid_size.dart';
import '../widgets/step3_verify_grid_contents.dart';
import '../widgets/step4_verify_clue_text.dart';
import '../widgets/step5_solve_puzzle.dart';

const _showScreenWidth = false;

class CrosswordScreen extends StatelessWidget {
  const CrosswordScreen({super.key});

  @override
  Widget build(BuildContext context) => Consumer<AppStepState>(
    builder: (context, appStepState, child) {
      final steps = [
        Step(
          title: const Text('Select crossword image'),
          content: StepOneSelectImage(isActive: appStepState.currentStep == 0),
        ),
        Step(
          title: const Text('Verify grid size'),
          content: StepTwoVerifyGridSize(
            isActive: appStepState.currentStep == 1,
          ),
        ),
        Step(
          title: const Text('Verify grid contents'),
          content: StepThreeVerifyGridContents(
            isActive: appStepState.currentStep == 2,
          ),
        ),
        Step(
          title: const Text('Verify grid clues'),
          content: StepFourVerifyClueText(
            isActive: appStepState.currentStep == 3,
          ),
        ),
        Step(
          title: const Text('Solve the puzzle'),
          content: StepFiveSolvePuzzle(isActive: appStepState.currentStep == 4),
        ),
      ];

      return Scaffold(
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 32, right: 32, top: 64),
              child: SvgPicture(
                AssetBytesLoader('assets/cc-title.svg.vec'),
                height: 100,
              ),
            ),
            Expanded(
              child: Stepper(
                currentStep: appStepState.currentStep,
                onStepTapped: null,
                onStepContinue: null,
                onStepCancel: null,
                // Hide the default buttons
                controlsBuilder: (_, _) => const SizedBox.shrink(),
                steps: steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  return Step(
                    title: step.title,
                    content: step.content,
                    state: appStepState.currentStep > index
                        ? StepState.complete
                        : StepState.indexed,
                    isActive: appStepState.currentStep == index,
                  );
                }).toList(),
              ),
            ),
            if (_showScreenWidth)
              Container(
                color: Colors.grey[200],
                padding: const EdgeInsets.all(8),
                child: LayoutBuilder(
                  builder: (context, constraints) => Center(
                    child: Text(
                      'Screen width: '
                      '${constraints.maxWidth.toStringAsFixed(0)}px',
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
