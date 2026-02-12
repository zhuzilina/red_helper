import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:red_helper/repository/models/msg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MsgState extends ChangeNotifier {
  List<Msg> messages = [];

  // 缓存方法
  // 加载数据
  Future<void> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('messages');
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      messages = jsonList.map((json) => Msg.fromJson(json)).toList();
      notifyListeners();
    }
  }

  // 保存数据到缓存
  Future<void> saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = messages.map((msg) => msg.toJson()).toList();
    prefs.setString('messages', json.encode(jsonList));
  }

  // 更新方法
  bool addMessage(Msg botMsg, Msg userMsg) {
    try {
      messages.add(userMsg);
      messages.add(botMsg);
      return true;
    } catch (e) {
      throw ('更新消息时发生了错误:$e');
    }
  }
}
