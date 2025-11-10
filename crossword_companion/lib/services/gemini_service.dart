// ignore_for_file: avoid_dynamic_calls

import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/clue.dart';
import '../models/clue_answer.dart';
import '../models/crossword_data.dart';
import '../models/crossword_grid.dart';
import '../models/grid_cell.dart';

class GeminiService {
  GeminiService() {
    // The model for inferring crossword data from images.
    _crosswordModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-pro',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _crosswordSchema,
      ),
    );

    // The model for solving clues.
    _clueSolverModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.text(clueSolverSystemInstruction),
      tools: [
        Tool.functionDeclarations([
          _getWordMetadataFunction,
          _returnResultFunction,
        ]),
      ],
    );
  }

  late final GenerativeModel _crosswordModel;
  late final GenerativeModel _clueSolverModel;
  StreamSubscription<GenerateContentResponse>? _clueSolverSubscription;

  Future<void> cancelCurrentSolve() async {
    await _clueSolverSubscription?.cancel();
    _clueSolverSubscription = null;
  }

  static final _getWordMetadataFunction = FunctionDeclaration(
    'getWordMetadata',
    'Gets grammatical metadata for a word, like its part of speech. '
        'Best used to verify a candidate answer against a clue that implies a '
        'grammatical constraint.',
    parameters: {
      'word': Schema(SchemaType.string, description: 'The word to look up.'),
    },
  );

  static final _returnResultFunction = FunctionDeclaration(
    'returnResult',
    'Returns the final result of the clue solving process.',
    parameters: {
      'answer': Schema(
        SchemaType.string,
        description: 'The answer to the clue.',
      ),
      'confidence': Schema(
        SchemaType.number,
        description: 'The confidence score in the answer from 0.0 to 1.0.',
      ),
    },
  );

  static String get clueSolverSystemInstruction =>
      '''
You are an expert crossword puzzle solver.

**Follow these rules at all times:**
1.  **Prefer Common Words:** Prioritize common English words and proper nouns. Avoid obscure, archaic, or highly technical terms unless the clue strongly implies them.
2.  **Match the Clue:** Ensure your answer strictly matches the clue's tense, plurality (singular vs. plural), and part of speech.
3.  **Verify Grammatically:** If a clue implies a specific part of speech (e.g., it's a verb, adverb, or plural), it's a good idea to use the `getWordMetadata` tool to verify your candidate answer matches. However, avoid using it for every clue.
4.  **Be Confident:** Provide a confidence score from 0.0 to 1.0 indicating your certainty.
5.  **Trust the Clue Over the Pattern:** The provided letter pattern is only a suggestion based on other potentially incorrect answers. Your primary goal is to find the best word that fits the **clue text**. If you are confident in an answer that contradicts the provided pattern, you should use that answer.
6.  **Format Correctly:** You must return your answer in the specified JSON format.

---

### Tool: `getWordMetadata`

You have a tool to get grammatical information about a word.

**When to use:**
- This tool is most helpful as a verification step after you have a likely answer.
- Consider using this tool when a clue contains a grammatical hint that could be ambiguous.
- **Good candidates for verification:**
    - Clues that seem to be verbs (e.g., "To run," "Waving").
    - Clues that are adverbs (e.g., "Happily," "Quickly").
    - Clues that specify a plural form.
- **Try to avoid using the tool for:**
    - Simple definitions (e.g., "A small dog").
    - Fill-in-the-blank clues (e.g., "___ and flow").
    - Proper nouns (e.g., "Capital of France").

**Function signature:**
```json
${jsonEncode(_getWordMetadataFunction.toJson())}
```

### Tool: `returnResult`

You have a tool to return the final result of the clue solving process.

**When to use:**
- Use this tool when you have a final answer and confidence score to return. You
  must use this tool exactly once, and only once, to return the final result.

**Function signature:**
```json
${jsonEncode(_returnResultFunction.toJson())}
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

    final response = await _crosswordModel.generateContent(content);

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

  // Buffer for the result of the clue solving process.
  final _returnResult = <String, dynamic>{};

  Future<ClueAnswer?> solveClue(Clue clue, int length, String pattern) async {
    // Cancel any previous, in-flight request.
    await cancelCurrentSolve();

    // Clear the return result cache; this is where the result will be stored.
    _returnResult.clear();

    // Generate JSON response with functions and schema.
    await _clueSolverModel.generateContentWithFunctions(
      prompt: getSolverPrompt(clue, length, pattern),
      onFunctionCall: (functionCall) async => switch (functionCall.name) {
        'getWordMetadata' => await _getWordMetadataFromApi(
          functionCall.args['word'] as String,
        ),
        'returnResult' => _cacheReturnResult(functionCall.args),
        _ => throw Exception('Unknown function call: ${functionCall.name}'),
      },
    );

    assert(_returnResult.isNotEmpty, 'The return result cache is empty.');
    return ClueAnswer(
      answer: _returnResult['answer'] as String,
      confidence: (_returnResult['confidence'] as num).toDouble(),
    );
  }

  // Look up the metadata for a word in the dictionary API.
  Future<Map<String, dynamic>> _getWordMetadataFromApi(String word) async {
    debugPrint('Looking up metadata for word: "$word"');
    final url = Uri.parse(
      'https://api.dictionaryapi.dev/api/v2/entries/en/${Uri.encodeComponent(word)}',
    );

    final response = await http.get(url);
    return response.statusCode == 200
        ? {'result': jsonDecode(response.body)}
        : {'error': 'Could not find a definition for "$word".'};
  }

  // Cache the return result of the clue solving process via a function call.
  // This is how we get JSON responses from the model with functions, since the
  // model cannot return JSON directly when tools are used.
  Map<String, dynamic> _cacheReturnResult(Map<String, dynamic> returnResult) {
    debugPrint('Caching return result: ${jsonEncode(returnResult)}');
    assert(_returnResult.isEmpty, 'The return result cache is not empty.');
    _returnResult.addAll(returnResult);
    return {'status': 'success'};
  }

  String getSolverPrompt(Clue clue, int length, String pattern) =>
      buildSolverPrompt(clue, length, pattern);

  String buildSolverPrompt(Clue clue, int length, String pattern) =>
      '''
Your task is to solve the following crossword clue.

**Clue:** "${clue.text}"

**Constraints:**
- The answer is a **$length-letter** word.
- The current letter pattern is `$pattern`, where `_` represents an unknown letter.

Return your answer and confidence score in the required JSON format.
''';
}

extension on GenerativeModel {
  Future<String> generateContentWithFunctions({
    required String prompt,
    required Future<Map<String, dynamic>> Function(FunctionCall) onFunctionCall,
  }) async {
    // Use a chat session to support multiple request/response pairs, which is
    // needed to support function calls.
    final chat = startChat();
    final buffer = StringBuffer();
    var response = await chat.sendMessage(Content.text(prompt));

    while (true) {
      // Append the response text to the buffer.
      buffer.write(response.text ?? '');

      // If no function calls were collected, we're done
      if (response.functionCalls.isEmpty) break;

      // Append a newline to separate responses.
      buffer.write('\n');

      // Execute all function calls
      final functionResponses = <FunctionResponse>[];
      for (final functionCall in response.functionCalls) {
        try {
          functionResponses.add(
            FunctionResponse(
              functionCall.name,
              await onFunctionCall(functionCall),
            ),
          );
        } catch (ex) {
          functionResponses.add(
            FunctionResponse(functionCall.name, {'error': ex.toString()}),
          );
        }
      }

      // Get the next response stream with function results
      response = await chat.sendMessage(
        Content.functionResponses(functionResponses),
      );
    }

    return buffer.toString();
  }
}
