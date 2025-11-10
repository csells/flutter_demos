// Copyright 2025 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'clue.dart';
import 'crossword_grid.dart';

class CrosswordData {
  CrosswordData({
    required this.width,
    required this.height,
    required this.grid,
    required this.clues,
  });

  factory CrosswordData.fromJson(Map<String, dynamic> json) => CrosswordData(
    width: json['width'],
    height: json['height'],
    grid: CrosswordGrid.fromJson(json['grid']),
    clues: (json['clues'] as List)
        .map((clueJson) => Clue.fromJson(clueJson))
        .toList(),
  );
  final int width;
  final int height;
  final CrosswordGrid grid;
  final List<Clue> clues;

  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'grid': grid.toJson(),
    'clues': clues.map((clue) => clue.toJson()).toList(),
  };

  CrosswordData copyWith({
    int? width,
    int? height,
    CrosswordGrid? grid,
    List<Clue>? clues,
  }) => CrosswordData(
    width: width ?? this.width,
    height: height ?? this.height,
    grid: grid ?? this.grid,
    clues: clues ?? this.clues,
  );
}
