// 用于处理用户对象的模块
import 'package:flutter/material.dart';

// 朋友对象
class Friend {
  final int userid;
  final String nikename;
  final int points;
  final String avatarUrl;

  Friend({
    required this.userid,
    required this.nikename,
    required this.points,
    required this.avatarUrl,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      userid: json['id'] ?? 0,
      nikename: json['nickname'] ?? json['username'] ?? '',
      points: json['points'] ?? 0,
      avatarUrl: json['avatar'] ?? 'https://via.placeholder.com/50',
    );
  }
}

class PointsCategory {
  final String category;
  final int points;
  final Color color;

  PointsCategory({
    required this.category,
    required this.points,
    required this.color,
  });

  factory PointsCategory.fromJson(Map<String, dynamic> json, int index) {
    return PointsCategory(
      category: json['category'] ?? '',
      points: json['points'] ?? 0,
      color: _parseColor(
        json['color'] ??
            _getRandomElement([
              '#FF6384', // 1. 活力珊瑚红 (原RGB 255,99,132)
              '#FF9F40', // 2. 明亮橙 (原RGB 255,159,64)
              '#FFCD56', // 3. 阳光黄 (原RGB 255,205,86)
              '#4BC0C0', // 4. 热带蓝绿 (原RGB 75,192,192)
              '#36A2EB', // 5. 宝石蓝 (原RGB 54,162,235)
              '#9966FF', // 6. 电光紫 (原RGB 153,102,255)
              '#FF66CC', // 7. 霓虹粉 (原RGB 255,102,204)
            ], index),
      ),
    );
  }

  static String _getRandomElement(List list, int index) {
    if (list.isEmpty) return '#0000ff';
    return list[index];
  }

  static Color _parseColor(dynamic colorData) {
    if (colorData is String) {
      // 处理十六进制颜色 例如："#FF2196F3" 或 "2196F3"
      String hexString = colorData;
      if (hexString.startsWith('#')) {
        hexString = hexString.substring(1);
      }
      if (hexString.length == 6) {
        hexString = 'FF$hexString'; // 添加不透明度
      }
      return Color(int.parse(hexString, radix: 16));
    }
    // 处理其他格式或默认颜色
    return Colors.blue;
  }
}

class Book {
  final int bookid; // 书籍ID
  final String title; // 书名
  final String author; // 作者
  final String coverUrl; // 封面图片URL
  final String description; // 简介
  final String category; // 分类

  Book({
    required this.bookid,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.description,
    required this.category,
  });
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      bookid: json['id'] ?? 0,
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      coverUrl: json['cover'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
    );
  }
}

class Product {
  final String name;
  final int points;
  final String imageUrl;
  Product(this.name, this.points, this.imageUrl);
}

// 支撑方法
class SequentialElementPicker<T> {
  final List<T> _elements;
  final int _currentIndex = 0;

  // 构造函数（自动去重并校验空列表）
  SequentialElementPicker(List<T> list)
    : _elements = List<T>.from(list).toSet().toList() {
    if (_elements.isEmpty) {
      throw ArgumentError('Cannot create picker from empty list');
    }
  }
}

class DailyTask {
  final int id;
  final String title;
  final int points;
  bool completed;

  DailyTask(this.id, this.title, this.points, this.completed);
  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      json['id'] ?? 0,
      json['title'] ?? '',
      json['points'] ?? 0,
      json['is_completed'] == 1 ? true : false,
    );
  }
}

class CozeApiRequest {
  final String botId;
  final String userId;
  final bool stream;
  final bool autoSaveHistory;
  List<CozeMessage> additionalMessages;

  CozeApiRequest({
    required this.botId,
    required this.userId,
    required this.stream,
    required this.autoSaveHistory,
    required this.additionalMessages,
  });

  Map<String, dynamic> toJson() {
    return {
      'bot_id': botId,
      'user_id': userId,
      'stream': stream,
      'auto_save_history': autoSaveHistory,
      'additional_messages': additionalMessages
          .map((msg) => msg.toJson())
          .toList(),
    };
  }
}

class CozeMessage {
  final String role;
  final String content;
  final String contentType;

  CozeMessage({
    required this.role,
    required this.content,
    required this.contentType,
  });

  Map<String, dynamic> toJson() {
    return {'role': role, 'content': content, 'content_type': contentType};
  }
}
