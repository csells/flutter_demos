// Copyright 2025 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:uuid/uuid.dart';

enum ClueDirection { across, down }

class Clue {
  Clue({required this.number, required this.direction, required this.text})
    : id = const Uuid().v4();

  Clue.private({
    required this.id,
    required this.number,
    required this.direction,
    required this.text,
  });

  factory Clue.fromJson(Map<String, dynamic> json) => Clue(
    number: json['number'],
    direction: ClueDirection.values.byName(json['direction']),
    text: json['text'],
  );
  String id;
  int number;
  ClueDirection direction;
  String text;

  Clue copyWith({int? number, ClueDirection? direction, String? text}) =>
      Clue.private(
        id: id,
        number: number ?? this.number,
        direction: direction ?? this.direction,
        text: text ?? this.text,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'direction': direction.toString().split('.').last,
    'text': text,
  };
}
