import 'package:firebase_ai/firebase_ai.dart';

var geminiModels = GeminiModelsNano();

class GeminiModel {
  final String name;
  final String description;
  final GenerativeModel model;
  final String defaultPrompt;

  GeminiModel({
    required this.name,
    required this.description,
    required this.model,
    required this.defaultPrompt,
  });
}

class GeminiModelsNano {
  String selectedModelName = 'gemini-2.5-flash-image-preview';
  GeminiModel get selectedModel => models[selectedModelName]!;

  /// A map of Gemini models that can be used in the Chat Demo.
  Map<String, GeminiModel> models = {
    'gemini-2.5-flash-image-preview': GeminiModel(
      name: 'gemini-2.5-flash-image-preview',
      description:
          'Our standard Flash model upgraded for rapid creative workflows with image generation and conversational, multi-turn editing capabilities.',
      model: FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash-image-preview',
        generationConfig: GenerationConfig(
          responseModalities: [
            ResponseModalities.text,
            ResponseModalities.image,
          ],
        ),
      ),
      defaultPrompt:
          'Hot air balloons rising over the San Francisco Bay at golden hour '
          'with a view of the Golden Gate Bridge. Make it anime style.',
    ),
  };

  GeminiModel selectModel(String modelName) {
    if (models.containsKey(modelName)) {
      selectedModelName = modelName;
    } else {
      throw Exception('Model $modelName not found');
    }
    return selectedModel;
  }

  List<String> get modelNames => models.keys.toList();
  GeminiModel operator [](String name) => models[name]!;
}
