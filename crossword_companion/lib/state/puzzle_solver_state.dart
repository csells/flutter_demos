import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/clue.dart';
import '../models/clue_answer.dart';
import '../models/grid_cell.dart';
import '../models/todo_item.dart';
import '../services/gemini_service.dart';
import '../services/puzzle_solver.dart';
import 'puzzle_data_state.dart';

class PuzzleSolverState with ChangeNotifier {
  PuzzleSolverState({
    required PuzzleDataState puzzleDataState,
    required GeminiService geminiService,
  }) //
  : _puzzleDataState = puzzleDataState,
       _geminiService = geminiService;

  final PuzzleDataState _puzzleDataState;
  final GeminiService _geminiService;
  final _puzzleSolver = PuzzleSolver();

  List<TodoItem> _todos = [];
  List<TodoItem> get todos => _todos;

  void setTodos(List<TodoItem> newTodos) {
    _todos = newTodos;
    notifyListeners();
  }

  void updateTodoStatus(
    String todoId,
    TodoStatus newStatus, {
    ClueAnswer? answer,
    bool isWrong = false,
  }) {
    final index = _todos.indexWhere((todo) => todo.id == todoId);
    if (index != -1) {
      _todos[index] = TodoItem(
        id: _todos[index].id,
        description: _todos[index].description,
        status: newStatus,
        answer: answer ?? _todos[index].answer,
        isWrong: isWrong,
      );
      notifyListeners();
    }
  }

  bool _isSolving = false;
  bool get isSolving => _isSolving;
  set isSolving(bool value) {
    _isSolving = value;
    notifyListeners();
  }

  Future<void> pauseSolving() async {
    isSolving = false;
    await _geminiService.cancelCurrentSolve();
  }

  Future<void> resumeSolving() => solvePuzzle(isResuming: true);

  Future<void> restartSolving() async {
    if (_puzzleDataState.crosswordData == null) return;

    // Stop any existing solving loops and invalidate their results.
    await pauseSolving();

    // Clear AI-generated letters from the grid, preserving user-entered letters
    final newCells = _puzzleDataState.crosswordData!.grid.cells
        .map(
          (cell) =>
              cell.copyWith(clearAcrossLetter: true, clearDownLetter: true),
        )
        .toList();
    final newGrid = _puzzleDataState.crosswordData!.grid.copyWith(
      cells: newCells,
    );
    _puzzleDataState.updateCrosswordData(
      _puzzleDataState.crosswordData!.copyWith(grid: newGrid),
    );

    // Reset todos
    initializeTodos();

    // Start solving
    unawaited(solvePuzzle());
  }

  Future<void> solvePuzzle({bool isResuming = false}) => _puzzleSolver.solve(
    this,
    _puzzleDataState,
    _geminiService,
    isResuming: isResuming,
  );

  void resetSolution() {
    if (_puzzleDataState.crosswordData == null) return;

    // Clear letters from the grid by creating new cells
    final newCells = _puzzleDataState.crosswordData!.grid.cells
        .map(
          (cell) => GridCell(
            type: cell.type,
            clueNumber: cell.clueNumber,
            acrossLetter: null,
            downLetter: null,
            userLetter: null,
          ),
        )
        .toList();
    final newGrid = _puzzleDataState.crosswordData!.grid.copyWith(
      cells: newCells,
    );
    _puzzleDataState.updateCrosswordData(
      _puzzleDataState.crosswordData!.copyWith(grid: newGrid),
    );

    // Reset todos
    initializeTodos();

    notifyListeners();
  }

  void initializeTodos() {
    if (_puzzleDataState.crosswordData == null) {
      _todos = [];
      notifyListeners();
      return;
    }

    final newTodos = _puzzleDataState.crosswordData!.clues
        .map(
          (clue) => TodoItem(
            id: clue.id,
            description:
                '${clue.number}'
                '${clue.direction == ClueDirection.across ? 'A' : 'D'}. '
                '${clue.text}',
          ),
        )
        .toList();

    setTodos(newTodos);
  }

  void reset() {
    _todos = [];
    _isSolving = false;
    notifyListeners();
  }
}
