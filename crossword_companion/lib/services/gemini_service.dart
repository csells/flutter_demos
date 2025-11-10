// ignore_for_file: avoid_dynamic_calls

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
    // The model for inferring crossword data from images.
    _crosswordModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-pro',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _crosswordSchema,
      ),
    );

    final clueSolverSystemInstructionContent = Content.text(
      clueSolverSystemInstruction,
    );

    // The model for solving clues, including functions the model can call to
    // get more information about potential answers.
    _clueSolverModelWithFunctions = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: clueSolverSystemInstructionContent,
      tools: [
        Tool.functionDeclarations([_getWordMetadataFunction]),
      ],
    );

    // The model for solving clues, but without the tools and only for returning
    // the final JSON response with the answer and confidence score.
    _clueSolverModelWithSchema = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: clueSolverSystemInstructionContent,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _clueSolverSchema,
      ),
    );
  }

  late final GenerativeModel _crosswordModel;
  late final GenerativeModel _clueSolverModelWithFunctions;
  late final GenerativeModel _clueSolverModelWithSchema;
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

  static final _getWordMetadataFunction = FunctionDeclaration(
    'getWordMetadata',
    'Gets metadata for a word, like its part of speech.',
    parameters: {
      'word': Schema(SchemaType.string, description: 'The word to look up.'),
    },
  );

  static String get clueSolverSystemInstruction =>
      '''
You are an expert crossword puzzle solver.

**Follow these rules at all times:**
1.  **Prefer Common Words:** Prioritize common English words and proper nouns. Avoid obscure, archaic, or highly technical terms unless the clue strongly implies them.
2.  **Match the Clue:** Ensure your answer strictly matches the clue's tense, plurality (singular vs. plural), and part of speech.
3.  **Verify Grammatically:** If a clue implies a part of speech, use the `getWordMetadata` tool to verify your candidate answer has the correct part of speech.
4.  **Be Confident:** Provide a confidence score from 0.0 to 1.0 indicating your certainty.
5.  **Trust the Clue Over the Pattern:** The provided letter pattern is only a suggestion based on other potentially incorrect answers. Your primary goal is to find the best word that fits the **clue text**. If you are confident in an answer that contradicts the provided pattern, you should use that answer.
6.  **Format Correctly:** You must return your answer in the specified JSON format.

---

### Tool: `getWordMetadata`

You have a tool to get grammatical information about a word.

**When to use:**
- Use this tool when a clue implies a part of speech (e.g., "To run," "An object," "Happily") to confirm your answer matches.

**Function signature:**
```json
${jsonEncode(_getWordMetadataFunction.toJson())}
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

  Future<ClueAnswer?> solveClue(Clue clue, int length, String pattern) async {
    // Cancel any previous, in-flight request.
    await cancelCurrentSolve();

    // Generate JSON response with functions and schema.
    final json = await _generateJsonWithFunctionsAndSchema(
      modelWithFunctions: _clueSolverModelWithFunctions,
      modelWithSchema: _clueSolverModelWithSchema,
      prompt: getSolverPrompt(clue, length, pattern),
      onFunctionCall: (functionCall) async => switch (functionCall.name) {
        'getWordMetadata' => await getWordMetadataFromApi(
          functionCall.args['word'] as String,
        ),
        _ => throw Exception('Unknown function call: ${functionCall.name}'),
      },
    );

    return ClueAnswer(
      answer: json['answer'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Future<Map<String, dynamic>> getWordMetadataFromApi(String word) async {
    debugPrint('Looking up metadata for word: "$word"');
    final url = Uri.parse(
      'https://api.dictionaryapi.dev/api/v2/entries/en/${Uri.encodeComponent(word)}',
    );

    final response = await http.get(url);
    return response.statusCode == 200
        ? {'result': jsonDecode(response.body)}
        : {'error': 'Could not find a definition for "$word".'};
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

  Future<Map<String, dynamic>> _generateJsonWithFunctionsAndSchema({
    required GenerativeModel modelWithFunctions,
    required GenerativeModel modelWithSchema,
    required String prompt,
    required Future<Map<String, dynamic>> Function(FunctionCall) onFunctionCall,
  }) async {
    // 1. Let the model generate a text response with as many function calls as
    //    it wants. Use a chat session to support multiple request/response
    //    pairs, which is needed to support function calls. Also, we'll need the
    //    history to generate the final JSON response with the schema.
    final chat = modelWithFunctions.startChat();
    var response = await chat.sendMessage(Content.text(prompt));

    while (true) {
      // If no function calls were collected, we're done
      if (response.functionCalls.isEmpty) break;

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

    // 2. Generate the final JSON response with the schema. We do that by
    //    trimming the last two messages from the history (the last prompt/tool
    //    response and the last LLM response) and sending it to the model
    //    without the functions but with the schema. Essentially, we're asking
    //    the model to generate the response to the last prompt we gave it,
    //    including all of the function call results (if there are any), and
    //    then generate the same response again, but this time with the JSON
    //    schema.
    final history = chat.history.toList();
    final lastModelMessage = history.removeLast();
    final lastUserMessage = history.removeLast();
    assert(
      lastUserMessage.role == 'user' || lastUserMessage.role == 'function',
    );
    assert(lastModelMessage.role == 'model');
    final jsonResponse = await modelWithSchema
        .startChat(history: history)
        .sendMessage(lastUserMessage);
    return jsonDecode(jsonResponse.text!) as Map<String, dynamic>;
  }
}
