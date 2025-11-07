class ClueAnswer {
  ClueAnswer({required this.answer, required this.confidence});
  final String answer;
  final double confidence;

  ClueAnswer copyWith({String? answer, double? confidence}) => ClueAnswer(
    answer: answer ?? this.answer,
    confidence: confidence ?? this.confidence,
  );
}
