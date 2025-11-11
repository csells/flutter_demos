// Copyright 2025 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

bool isMobile() => Platform.isIOS || Platform.isAndroid;
bool isDesktop() => Platform.isWindows || Platform.isMacOS || Platform.isLinux;
