// Copyright 2025 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/clue.dart';
import '../models/crossword_data.dart';
import '../models/grid_cell.dart';
import '../services/gemini_service.dart';

class PuzzleDataState with ChangeNotifier {
  PuzzleDataState({required GeminiService geminiService})
    : _geminiService = geminiService;

  final GeminiService _geminiService;

  VoidCallback? onDataChanged;

  final List<XFile> _selectedCrosswordImages = [];
  List<XFile> get selectedCrosswordImages => _selectedCrosswordImages;

  final List<Uint8List> _selectedCrosswordImagesData = [];
  List<Uint8List> get selectedCrosswordImagesData =>
      _selectedCrosswordImagesData;

  CrosswordData? _crosswordData;
  CrosswordData? get crosswordData => _crosswordData;

  bool get isGridClear =>
      _crosswordData?.grid.cells.every(
        (cell) => cell.acrossLetter == null && cell.downLetter == null,
      ) ??
      true;

  void updateCrosswordData(CrosswordData? newData) {
    if (newData != null &&
        _crosswordData != null &&
        (newData.width != _crosswordData!.width ||
            newData.height != _crosswordData!.height)) {
      final oldGrid = _crosswordData!.grid;
      final newCells = <GridCell>[];

      for (var y = 0; y < newData.height; y++) {
        for (var x = 0; x < newData.width; x++) {
          if (x < oldGrid.width && y < oldGrid.height) {
            // This cell existed in the old grid, so copy it.
            final oldIndex = y * oldGrid.width + x;
            newCells.add(oldGrid.cells[oldIndex]);
          } else {
            // This is a new cell, create a default one.
            newCells.add(GridCell());
          }
        }
      }

      final newGrid = _crosswordData!.grid.copyWith(
        width: newData.width,
        height: newData.height,
        cells: newCells,
      );
      _crosswordData = newData.copyWith(grid: newGrid);
    } else {
      _crosswordData = newData;
    }
    onDataChanged?.call();
    notifyListeners();
  }

  List<String> validateGridAndClues() {
    if (_crosswordData == null) return [];

    final errors = <String>[];

    // Rule 1: Unique Grid Numbers
    final gridNumbers = _crosswordData!.grid.cells
        .where((c) => c.clueNumber != null)
        .map((c) => c.clueNumber!)
        .toList();
    final uniqueGridNumbers = gridNumbers.toSet();
    if (gridNumbers.length != uniqueGridNumbers.length) {
      final duplicates = gridNumbers
          .fold<Map<int, int>>({}, (map, n) {
            map[n] = (map[n] ?? 0) + 1;
            return map;
          })
          .entries
          .where((e) => e.value > 1)
          .map((e) => e.key)
          .toList();
      for (final duplicate in duplicates) {
        errors.add('Duplicate number in grid: #$duplicate');
      }
    }

    // Rule 2 & 3: Parity between clues and grid numbers
    final clueNumbers = _crosswordData!.clues.map((c) => c.number).toSet();

    final cluesWithoutGridEntry = clueNumbers.difference(uniqueGridNumbers);
    for (final number in cluesWithoutGridEntry) {
      final missingClues = _crosswordData!.clues.where(
        (c) => c.number == number,
      );
      for (final clue in missingClues) {
        errors.add(
          "Clue '${clue.number} ${clue.direction.name}' exists, "
          'but #${clue.number} is not in the grid.',
        );
      }
    }

    final gridEntriesWithoutClue = uniqueGridNumbers.difference(clueNumbers);
    for (final number in gridEntriesWithoutClue) {
      errors.add('Grid contains #$number, but there is no clue for it.');
    }

    return errors;
  }

  void updateClue(Clue updatedClue) {
    if (_crosswordData == null) return;

    final newClues = List<Clue>.from(_crosswordData!.clues);
    final index = newClues.indexWhere((c) => c.id == updatedClue.id);
    if (index != -1) {
      newClues[index] = updatedClue;
      _crosswordData = _crosswordData!.copyWith(clues: newClues);
      onDataChanged?.call();
      notifyListeners();
    }
  }

  bool _isInferringCrosswordData = false;
  bool get isInferringCrosswordData => _isInferringCrosswordData;

  String? _inferenceError;
  String? get inferenceError => _inferenceError;

  Future<void> inferCrosswordData() async {
    if (_selectedCrosswordImages.isEmpty) {
      return;
    }

    _isInferringCrosswordData = true;
    _inferenceError = null;
    notifyListeners();

    try {
      _crosswordData = await _geminiService.inferCrosswordData(
        _selectedCrosswordImages,
      );
      onDataChanged?.call();
    } on Exception catch (e) {
      _inferenceError = e.toString();
    }

    _isInferringCrosswordData = false;
    notifyListeners();
  }

  Future<void> addSelectedCrosswordImages(List<XFile> images) async {
    _selectedCrosswordImages.addAll(images);
    _crosswordData = null; // Clear old crossword data

    for (final image in images) {
      _selectedCrosswordImagesData.add(await image.readAsBytes());
    }
    onDataChanged?.call();
    notifyListeners();
  }

  void removeSelectedCrosswordImage(int index) {
    _selectedCrosswordImages.removeAt(index);
    _selectedCrosswordImagesData.removeAt(index);
    _crosswordData = null; // Clear old crossword data
    onDataChanged?.call();
    notifyListeners();
  }

  void setCellType(
    int index,
    GridCellType type, {
    int? clueNumber,
    bool clearClueNumber = false,
  }) {
    if (_crosswordData != null) {
      final newCells = List<GridCell>.from(_crosswordData!.grid.cells);
      final oldCell = newCells[index];

      newCells[index] = GridCell(
        type: type,
        clueNumber: clearClueNumber ? null : clueNumber ?? oldCell.clueNumber,
        acrossLetter: oldCell.acrossLetter,
        downLetter: oldCell.downLetter,
        userLetter: oldCell.userLetter,
      );

      final newGrid = _crosswordData!.grid.copyWith(cells: newCells);
      _crosswordData = _crosswordData!.copyWith(grid: newGrid);
      notifyListeners();
    }
  }

  void updateCellLetter(int index, String letter) {
    if (_crosswordData != null) {
      final newCells = List<GridCell>.from(_crosswordData!.grid.cells);
      final oldCell = newCells[index];

      if (oldCell.type == GridCellType.inactive) return;

      if (letter.isEmpty) {
        newCells[index] = oldCell.copyWith(
          clearUserLetter: true,
          clearAcrossLetter: true,
          clearDownLetter: true,
        );
      } else {
        newCells[index] = oldCell.copyWith(
          userLetter: letter.toUpperCase(),
          clearAcrossLetter: true,
          clearDownLetter: true,
        );
      }

      final newGrid = _crosswordData!.grid.copyWith(cells: newCells);
      _crosswordData = _crosswordData!.copyWith(grid: newGrid);
      notifyListeners();
    }
  }

  void setSolution(int clueNumber, ClueDirection direction, String? answer) {
    if (_crosswordData == null) return;

    final newCells = List<GridCell>.from(_crosswordData!.grid.cells);
    final startIndex = newCells.indexWhere(
      (cell) => cell.clueNumber == clueNumber,
    );

    if (startIndex != -1 && answer != null) {
      for (var i = 0; i < answer.length; i++) {
        int cellIndex;
        if (direction == ClueDirection.across) {
          cellIndex = startIndex + i;
        } else {
          cellIndex = startIndex + (i * _crosswordData!.width);
        }

        if (cellIndex < newCells.length &&
            newCells[cellIndex].type != GridCellType.inactive &&
            newCells[cellIndex].userLetter == null) {
          final oldCell = newCells[cellIndex];
          newCells[cellIndex] = direction == ClueDirection.across
              ? oldCell.copyWith(acrossLetter: answer[i].toUpperCase())
              : oldCell.copyWith(downLetter: answer[i].toUpperCase());
        }
      }
    }

    final newGrid = _crosswordData!.grid.copyWith(cells: newCells);
    _crosswordData = _crosswordData!.copyWith(grid: newGrid);

    notifyListeners();
  }

  void reset() {
    _selectedCrosswordImages.clear();
    _selectedCrosswordImagesData.clear();
    _crosswordData = null;
    _isInferringCrosswordData = false;
    _inferenceError = null;
    notifyListeners();
  }
}
