// Copyright 2025 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

mixin StepActivationMixin<T extends StatefulWidget> on State<T> {
  bool get isActive;

  @override
  void initState() {
    super.initState();
    if (isActive) {
      onActivated();
    }
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIsActive = (oldWidget as dynamic).isActive as bool;
    if (!oldIsActive && isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onActivated());
    }
  }

  void onActivated();
}
