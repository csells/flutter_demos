// ignore_for_file: avoid_dynamic_calls

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../models/clue.dart';
import '../models/clue_answer.dart';
import '../models/crossword_data.dart';
import '../models/crossword_grid.dart';
import '../models/grid_cell.dart';
import '../platform/platform.dart';

class GeminiService {
  GeminiService() {
    _crosswordJsonModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-pro',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _crosswordSchema,
      ),
    );

    _clueSolverJsonModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _clueSolverSchema,
      ),
      systemInstruction: Content.text(systemInstruction),
    );
  }
  late final GenerativeModel _crosswordJsonModel;
  late final GenerativeModel _clueSolverJsonModel;
  StreamSubscription<GenerateContentResponse>? _clueSolverSubscription;

  Future<void> cancelCurrentSolve() async {
    await _clueSolverSubscription?.cancel();
    _clueSolverSubscription = null;
  }

  static final _clueSolverSchema = Schema(
    SchemaType.object,
    properties: {
      'answer': Schema(SchemaType.string),
      'confidence': Schema(SchemaType.number),
    },
  );

  String get systemInstruction => '''
You are an expert crossword puzzle solver. Your goal is to determine the correct word for a given clue based on the provided constraints.

**Follow these rules at all times:**
1.  **Prefer Common Words:** Prioritize common English words and proper nouns. Avoid obscure, archaic, or highly technical terms unless the clue strongly implies them.
2.  **Match the Clue:** Ensure your answer strictly matches the clue's tense, plurality (singular vs. plural), and part of speech.
3.  **Be Confident:** Provide a confidence score from 0.0 to 1.0 indicating your certainty.
4.  **Trust the Clue Over the Pattern:** The provided letter pattern is only a suggestion based on other potentially incorrect answers. Your primary goal is to find the best word that fits the **clue text**. If you are confident in an answer that contradicts the provided pattern, you should use that answer.
5.  **Format Correctly:** You must return your answer in the specified JSON format.

---

### Example Task

Here is an example of a task you will receive:

```
Your task is to solve the following crossword clue.

**Clue:** "The opposite of `down`"

**Constraints:**
- The answer is a **2-letter** word.
- The current letter pattern is `_P`, where `_` represents an unknown letter.

Return your answer and confidence score in the required JSON format.
```

### Example Response

Here is the correct response for the example task above:

```json
{"answer": "UP", "confidence": 1.0}
```
''';

  static final _crosswordSchema = Schema(
    SchemaType.object,
    properties: {
      'width': Schema(SchemaType.integer),
      'height': Schema(SchemaType.integer),
      'grid': Schema(
        SchemaType.array,
        items: Schema(
          SchemaType.array,
          items: Schema(
            SchemaType.object,
            properties: {
              'color': Schema(SchemaType.string),
              'clueNumber': Schema(SchemaType.integer, nullable: true),
            },
          ),
        ),
      ),
      'clues': Schema(
        SchemaType.object,
        properties: {
          'across': Schema(
            SchemaType.array,
            items: Schema(
              SchemaType.object,
              properties: {
                'number': Schema(SchemaType.integer),
                'text': Schema(SchemaType.string),
              },
            ),
          ),
          'down': Schema(
            SchemaType.array,
            items: Schema(
              SchemaType.object,
              properties: {
                'number': Schema(SchemaType.integer),
                'text': Schema(SchemaType.string),
              },
            ),
          ),
        },
      ),
    },
  );

  Future<CrosswordData> inferCrosswordData(List<XFile> images) async {
    // Caching is supported in debug mode on desktop.
    if (!kIsWeb && kDebugMode && isDesktop()) {
      try {
        final paths = images.map((image) => image.path).toList()..sort();
        final key = paths.join(';').hashCode.toString();
        final jsonPath = '${path.join(path.dirname(paths.first), key)}.json';
        final jsonFile = File(jsonPath);

        if (jsonFile.existsSync()) {
          debugPrint('Found cached crossword data at $jsonPath');
          final jsonString = await jsonFile.readAsString();
          return CrosswordData.fromJson(jsonDecode(jsonString));
        } else {
          final crosswordData = await _inferCrosswordDataFromApi(images);
          final jsonString = jsonEncode(crosswordData.toJson());
          await jsonFile.writeAsString(jsonString);
          debugPrint('Saved inferred crossword data to $jsonPath');
          return crosswordData;
        }
      } on Exception catch (e) {
        debugPrint('Error with file-based caching: $e');
      }
    }

    return _inferCrosswordDataFromApi(images);
  }

  Future<CrosswordData> _inferCrosswordDataFromApi(List<XFile> images) async {
    final imageParts = <Part>[];
    for (final image in images) {
      final imageBytes = await image.readAsBytes();
      imageParts.add(InlineDataPart('image/jpeg', imageBytes));
    }

    final content = [
      Content.multi([
        TextPart('''
Analyze the following crossword puzzle images and return a JSON object
representing the grid size, contents, and clues. The images may contain
different parts of the same puzzle (e.g., the grid the across clues, the down
clues). Combine them to form a complete puzzle.
The JSON schema is as follows: ${jsonEncode(_crosswordSchema.toJson())}
          '''),
        ...imageParts,
      ]),
    ];

    final response = await _crosswordJsonModel.generateContent(content);

    final json = jsonDecode(response.text!);

    final width = json['width'] as int;
    final height = json['height'] as int;
    final gridData = json['grid'] as List;
    final cluesData = json['clues'] as Map<String, dynamic>;

    final cells = gridData
        .expand(
          (row) => (row as List).map((cellData) {
            final isBlack = cellData['color'] == 'black';
            final type = isBlack ? GridCellType.inactive : GridCellType.empty;
            final clueNumber = isBlack ? null : cellData['clueNumber'] as int?;
            return GridCell(type: type, clueNumber: clueNumber);
          }),
        )
        .toList();

    final grid = CrosswordGrid(width: width, height: height, cells: cells);

    final acrossClues = (cluesData['across'] as List).map(
      (clueData) => Clue(
        number: clueData['number'],
        direction: ClueDirection.across,
        text: clueData['text'],
      ),
    );

    final downClues = (cluesData['down'] as List).map(
      (clueData) => Clue(
        number: clueData['number'],
        direction: ClueDirection.down,
        text: clueData['text'],
      ),
    );

    final clues = [...acrossClues, ...downClues];

    return CrosswordData(
      width: width,
      height: height,
      grid: grid,
      clues: clues,
    );
  }

  Future<ClueAnswer?> solveClue(Clue clue, int length, String pattern) async {
    // Cancel any previous, in-flight request.
    await cancelCurrentSolve();

    final prompt = getSolverPrompt(clue, length, pattern);
    final stream = _clueSolverJsonModel.generateContentStream([
      Content.text(prompt),
    ]);

    try {
      final buffer = StringBuffer();
      _clueSolverSubscription = stream.listen((response) {
        buffer.write(response.text);
      });

      // Await the subscription to complete.
      await _clueSolverSubscription!.asFuture<void>();

      final responseText = buffer.toString();
      if (responseText.isEmpty) return null;

      final json = jsonDecode(responseText) as Map<String, dynamic>;
      final answer = json['answer'] as String?;
      final confidence = (json['confidence'] as num?)?.toDouble();

      if (answer == null || confidence == null) return null;

      return ClueAnswer(answer: answer, confidence: confidence);
    } on Exception catch (e) {
      // This block will be entered if the subscription is cancelled.
      debugPrint('Clue solver stream cancelled or failed: $e');
      return null;
    } finally {
      _clueSolverSubscription = null;
    }
  }

  String getSolverPrompt(Clue clue, int length, String pattern) =>
      _buildSolverPrompt(clue, length, pattern);

  String _buildSolverPrompt(Clue clue, int length, String pattern) =>
      '''
Your task is to solve the following crossword clue.

**Clue:** "${clue.text}"

**Constraints:**
- The answer is a **$length-letter** word.
- The current letter pattern is `$pattern`, where `_` represents an unknown letter.

Return your answer and confidence score in the required JSON format.
''';
}
