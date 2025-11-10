// Copyright 2025 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

const Color conflictColor = Colors.red;
const Color matchingColor = Colors.green;
const Color defaultLetterColor = Colors.black87;
const Color userLetterColor = Colors.blue;
const Color inactiveCellColor = Color(0xFFBDBDBD); // A light grey
const Color emptyCellColor = Colors.white;
const Color cellBorderColor = Colors.grey;

const TextStyle clueNumberStyle = TextStyle(fontSize: 8);
const TextStyle letterStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.bold,
);

final ButtonStyle secondaryActionButtonStyle = ElevatedButton.styleFrom(
  disabledBackgroundColor: Colors.transparent,
  disabledForegroundColor: const Color.fromRGBO(0, 0, 0, 0.7),
);

final ButtonStyle primaryActionButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: Colors.black,
  foregroundColor: Colors.white,
);
