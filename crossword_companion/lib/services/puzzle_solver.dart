import '../models/clue.dart';
import '../models/grid_cell.dart';
import '../models/todo_item.dart';
import '../state/puzzle_data_state.dart';
import '../state/puzzle_solver_state.dart';
import 'gemini_service.dart';

class PuzzleSolver {
  Future<void> solve(
    PuzzleSolverState solverState,
    PuzzleDataState dataState,
    GeminiService geminiService, {
    bool isResuming = false,
  }) async {
    assert(
      solverState.todos.isNotEmpty,
      'The list of todos should not be empty when calling solvePuzzle',
    );
    if (!isResuming) {
      assert(dataState.isGridClear);
    }
    if (dataState.crosswordData == null) return;

    solverState.isSolving = true;

    while (solverState.isSolving &&
        solverState.todos.any((todo) => todo.status != TodoStatus.done)) {
      for (final todo in solverState.todos) {
        if (!solverState.isSolving) break;

        if (todo.status == TodoStatus.done) continue;

        solverState.updateTodoStatus(todo.id, TodoStatus.inProgress);

        final clue = dataState.crosswordData!.clues.firstWhere(
          (clue) => clue.id == todo.id,
        );

        final expectedLength = _getClueLength(dataState, clue);
        final pattern = _getCluePattern(dataState, clue);

        final clueAnswer = await geminiService.solveClue(
          clue,
          expectedLength,
          pattern,
        );

        if (!solverState.isSolving) break;

        if (clueAnswer != null) {
          if (clueAnswer.answer.length == expectedLength) {
            final conflicts = _getConflicts(dataState, clue, clueAnswer.answer);
            if (conflicts.isEmpty) {
              dataState.setSolution(
                clue.number,
                clue.direction,
                clueAnswer.answer,
              );
              solverState.updateTodoStatus(
                todo.id,
                TodoStatus.done,
                answer: clueAnswer,
              );
            } else {
              solverState.updateTodoStatus(
                todo.id,
                TodoStatus.notDone,
                answer: clueAnswer.copyWith(
                  answer: '-- CONFLICTS WITH YOUR LETTER',
                ),
                isWrong: true,
              );
            }
          } else {
            solverState.updateTodoStatus(
              todo.id,
              TodoStatus.notDone,
              answer: clueAnswer,
              isWrong: true,
            );
          }
        } else {
          solverState.updateTodoStatus(todo.id, TodoStatus.notDone);
        }
      }
    }

    solverState.isSolving = false;
  }

  // Helper method to execute a callback for each cell in a clue.
  void _traverseClue(
    PuzzleDataState dataState,
    Clue clue,
    void Function(GridCell) onCell,
  ) {
    final grid = dataState.crosswordData!.grid;
    final startIndex = grid.cells.indexWhere(
      (c) => c.clueNumber == clue.number,
    );
    if (startIndex == -1) return;

    if (clue.direction == ClueDirection.across) {
      final startRow = startIndex ~/ grid.width;
      for (var i = startIndex; i < grid.cells.length; i++) {
        final currentRow = i ~/ grid.width;
        if (currentRow != startRow ||
            grid.cells[i].type == GridCellType.inactive) {
          break;
        }
        onCell(grid.cells[i]);
      }
    } else {
      for (var i = startIndex; i < grid.cells.length; i += grid.width) {
        if (grid.cells[i].type == GridCellType.inactive) {
          break;
        }
        onCell(grid.cells[i]);
      }
    }
  }

  int _getClueLength(PuzzleDataState dataState, Clue clue) {
    var length = 0;
    _traverseClue(dataState, clue, (cell) {
      if (cell.type != GridCellType.inactive) {
        length++;
      }
    });
    return length;
  }

  String _getCluePattern(PuzzleDataState dataState, Clue clue) {
    var pattern = '';
    _traverseClue(dataState, clue, (cell) {
      if (cell.userLetter != null) {
        pattern += cell.userLetter!;
      } else if (clue.direction == ClueDirection.across) {
        pattern += cell.downLetter ?? '_';
      } else {
        pattern += cell.acrossLetter ?? '_';
      }
    });
    return pattern;
  }

  List<int> _getConflicts(PuzzleDataState dataState, Clue clue, String answer) {
    final conflicts = <int>[];
    var i = 0;
    _traverseClue(dataState, clue, (cell) {
      if (cell.userLetter != null &&
          i < answer.length &&
          cell.userLetter != answer[i]) {
        conflicts.add(i);
      }
      i++;
    });
    return conflicts;
  }
}
