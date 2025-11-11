// Copyright 2025 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class ClueAnswer {
  ClueAnswer({required this.answer, required this.confidence});
  final String answer;
  final double confidence;

  ClueAnswer copyWith({String? answer, double? confidence}) => ClueAnswer(
    answer: answer ?? this.answer,
    confidence: confidence ?? this.confidence,
  );
}
