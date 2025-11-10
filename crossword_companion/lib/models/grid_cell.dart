// Copyright 2025 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

enum GridCellType { inactive, empty, numbered }

class GridCell {
  GridCell({
    this.type = GridCellType.empty,
    this.clueNumber,
    this.acrossLetter,
    this.downLetter,
    this.userLetter,
  });

  factory GridCell.fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String?;
    GridCellType type;
    switch (typeString) {
      case 'inactive':
        type = GridCellType.inactive;
      case 'numbered':
        type = GridCellType.numbered;
      case 'empty':
      default:
        type = GridCellType.empty;
    }

    return GridCell(
      type: type,
      clueNumber: json['clueNumber'] as int?,
      acrossLetter: json['acrossLetter'] as String?,
      downLetter: json['downLetter'] as String?,
      userLetter: json['userLetter'] as String?,
    );
  }
  final GridCellType type;
  final int? clueNumber;
  final String? acrossLetter;
  final String? downLetter;
  final String? userLetter;

  Map<String, dynamic> toJson() => {
    'type': type.toString().split('.').last,
    'clueNumber': clueNumber,
    'acrossLetter': acrossLetter,
    'downLetter': downLetter,
    'userLetter': userLetter,
  };

  GridCell copyWith({
    GridCellType? type,
    int? clueNumber,
    bool clearClueNumber = false,
    String? acrossLetter,
    bool clearAcrossLetter = false,
    String? downLetter,
    bool clearDownLetter = false,
    String? userLetter,
    bool clearUserLetter = false,
  }) => GridCell(
    type: type ?? this.type,
    clueNumber: clearClueNumber ? null : clueNumber ?? this.clueNumber,
    acrossLetter: clearAcrossLetter ? null : acrossLetter ?? this.acrossLetter,
    downLetter: clearDownLetter ? null : downLetter ?? this.downLetter,
    userLetter: clearUserLetter ? null : userLetter ?? this.userLetter,
  );
}
