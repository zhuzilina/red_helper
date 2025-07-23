import 'package:flutter/foundation.dart';

class TaskState with ChangeNotifier {
  int _unfinished = 3;
  int get unfinishedCount => _unfinished;

  void completeTask() {
    _unfinished--;
    notifyListeners();
  }
}