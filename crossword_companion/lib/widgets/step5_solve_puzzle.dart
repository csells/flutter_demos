// Copyright 2025 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/todo_item.dart';
import '../state/app_step_state.dart';
import '../state/puzzle_data_state.dart';
import '../state/puzzle_solver_state.dart';
import '../styles.dart';
import 'grid_view.dart';
import 'step_activation_mixin.dart';
import 'todo_list_widget.dart';

class StepFiveSolvePuzzle extends StatefulWidget {
  const StepFiveSolvePuzzle({required this.isActive, super.key});

  final bool isActive;

  @override
  State<StepFiveSolvePuzzle> createState() => _StepFiveSolvePuzzleState();
}

class _StepFiveSolvePuzzleState extends State<StepFiveSolvePuzzle>
    with StepActivationMixin<StepFiveSolvePuzzle> {
  @override
  bool get isActive => widget.isActive;

  @override
  void onActivated() {
    final puzzleSolverState = Provider.of<PuzzleSolverState>(
      context,
      listen: false,
    );

    // Start solving only if we are not already solving and there are todos.
    if (!puzzleSolverState.isSolving &&
        puzzleSolverState.todos.any((t) => t.status != TodoStatus.done)) {
      unawaited(puzzleSolverState.solvePuzzle());
    }
  }

  void _showEditLetterDialog(BuildContext context, int index) {
    final puzzleDataState = Provider.of<PuzzleDataState>(
      context,
      listen: false,
    );
    final controller = TextEditingController();
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
                puzzleDataState.updateCellLetter(index, controller.text);
                Navigator.pop(context);
              }
            }
          },
          child: AlertDialog(
            title: const Text('Letter'),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLength: 1,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  puzzleDataState.updateCellLetter(index, '');
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  puzzleDataState.updateCellLetter(index, controller.text);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puzzleDataState = Provider.of<PuzzleDataState>(context);
    final puzzleSolverState = Provider.of<PuzzleSolverState>(context);
    final appStepState = Provider.of<AppStepState>(context);

    if (puzzleDataState.crosswordData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final crosswordData = puzzleDataState.crosswordData!;
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (puzzleSolverState.isSolving)
                    ElevatedButton(
                      onPressed: puzzleSolverState.pauseSolving,
                      child: const Text('Pause'),
                    ),
                  if (!puzzleSolverState.isSolving &&
                      puzzleSolverState.todos.any(
                        (t) => t.status != TodoStatus.done,
                      ))
                    ElevatedButton(
                      onPressed: puzzleSolverState.resumeSolving,
                      child: const Text('Resume'),
                    ),
                  ElevatedButton(
                    onPressed: puzzleSolverState.restartSolving,
                    child: const Text('Restart'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (puzzleSolverState.isSolving) {
                        await puzzleSolverState.pauseSolving();
                      }
                      puzzleSolverState.resetSolution();
                      appStepState.previousStep();
                    },
                    style: secondaryActionButtonStyle,
                    child: const Text('Back'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      appStepState.reset();
                      puzzleDataState.reset();
                      puzzleSolverState.reset();
                    },
                    style: primaryActionButtonStyle,
                    child: const Text('New Puzzle'),
                  ),
                ],
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // Narrow screen: stack grid and clues vertically
                return Column(
                  children: [
                    CrosswordGridView(
                      grid: crosswordData.grid,
                      onCellTapped: (index) =>
                          _showEditLetterDialog(context, index),
                    ),
                    const SizedBox(height: 16),
                    TodoListWidget(todos: puzzleSolverState.todos),
                  ],
                );
              } else {
                // Wide screen: display grid and clues side-by-side
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: CrosswordGridView(
                          grid: crosswordData.grid,
                          onCellTapped: (index) =>
                              _showEditLetterDialog(context, index),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TodoListWidget(todos: puzzleSolverState.todos),
                    ),
                  ],
                );
              }
            },
          ),
          if (puzzleSolverState.isSolving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Solving puzzle...'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
