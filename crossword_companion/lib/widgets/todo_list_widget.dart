import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../styles.dart';

class TodoListWidget extends StatelessWidget {
  const TodoListWidget({required this.todos, super.key});
  final List<TodoItem> todos;

  @override
  Widget build(BuildContext context) => ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: todos.length,
    itemBuilder: (context, index) {
      final todo = todos[index];
      final confidence = todo.answer?.confidence ?? 0;
      final confidenceString = '(${(confidence * 100).toStringAsFixed(0)}%)';

      return ListTile(
        title: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: <TextSpan>[
              TextSpan(
                text: todo.description,
                style: TextStyle(color: _getColorForStatus(todo.status)),
              ),
              if (todo.answer != null)
                TextSpan(
                  text: ': ${todo.answer!.answer} $confidenceString',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              if (todo.isWrong)
                const TextSpan(
                  text: ' -- WRONG',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: conflictColor,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  Color _getColorForStatus(TodoStatus status) {
    switch (status) {
      case TodoStatus.done:
        return matchingColor;
      case TodoStatus.inProgress:
        return defaultLetterColor;
      case TodoStatus.notDone:
        return conflictColor;
    }
  }
}
