// Copyright 2025 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'clue_answer.dart';

enum TodoStatus { notDone, inProgress, done }

class TodoItem {
  TodoItem({
    required this.id,
    required this.description,
    this.status = TodoStatus.notDone,
    this.answer,
    this.isWrong = false,
  });
  final String id;
  final String description;
  final TodoStatus status;
  final ClueAnswer? answer;
  final bool isWrong;
}
