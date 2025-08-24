import 'package:json_annotation/json_annotation.dart';

part 'topic.g.dart';

@JsonSerializable()
class Topic {
  final String topic;
  final String detail;
  final List<String> questions;

  Topic({required this.topic, required this.detail, required this.questions});

  // 从JSON反序列化
  factory Topic.fromJson(Map<String, dynamic> json) => _$TopicFromJson(json);

  // 序列化为JSON
  Map<String, dynamic> toJson() => _$TopicToJson(this);

  // 从generate.dart的parseOutputText结果创建Topic对象
  factory Topic.fromParseResult(Map<String, dynamic> parseResult) {
    if (parseResult.containsKey('error')) {
      throw Exception('解析错误: ${parseResult['error']}');
    }

    return Topic(
      topic: parseResult['topic'] ?? '',
      detail: parseResult['detail'] ?? '',
      questions: List<String>.from(parseResult['questions'] ?? []),
    );
  }

  @override
  String toString() {
    return 'Topic{topic: $topic, detail: $detail, questions: $questions}';
  }
}
