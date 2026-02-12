import 'package:flutter/material.dart';
import 'package:red_helper/repository/models/model.dart';

class TaskItem extends StatelessWidget {
  final DailyTask task;
  final VoidCallback onComplete;

  const TaskItem({super.key, required this.task, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.star, color: Colors.amber[700]),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontFamily: 'blockLetter',
            fontSize: 16,
            fontWeight: task.completed ? FontWeight.w500 : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '+${task.points}积分',
          style: TextStyle(color: Colors.amber[700]),
        ),
        trailing:
            task.completed
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffcc5d4e),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onPressed: onComplete,
                  child: const Text(
                    '去完成',
                    style: TextStyle(
                      fontFamily: 'blockLetter',
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
      ),
    );
  }
}
