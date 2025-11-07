import 'clue_answer.dart';

enum TodoStatus { notDone, inProgress, done }

class TodoItem {
  TodoItem({
    required this.id,
    required this.description,
    this.status = TodoStatus.notDone,
    this.answer,
    this.isWrong = false,
  });
  final String id;
  final String description;
  final TodoStatus status;
  final ClueAnswer? answer;
  final bool isWrong;
}
