// Copyright 2025 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/crossword_screen.dart';
import 'services/gemini_service.dart';
import 'state/app_step_state.dart';
import 'state/puzzle_data_state.dart';
import 'state/puzzle_solver_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create instances of the services and state notifiers.
    final geminiService = GeminiService();
    final appStepState = AppStepState();
    final puzzleDataState = PuzzleDataState(geminiService: geminiService);
    final puzzleSolverState = PuzzleSolverState(
      puzzleDataState: puzzleDataState,
      geminiService: geminiService,
    );

    // Wire up the dependency between data changes and solver initialization.
    puzzleDataState.onDataChanged = puzzleSolverState.initializeTodos;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appStepState),
        ChangeNotifierProvider.value(value: puzzleDataState),
        ChangeNotifierProvider.value(value: puzzleSolverState),
      ],
      child: MaterialApp(
        theme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const CrosswordScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
