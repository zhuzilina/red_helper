// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Topic _$TopicFromJson(Map<String, dynamic> json) => Topic(
  topic: json['topic'] as String,
  detail: json['detail'] as String,
  questions: (json['questions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$TopicToJson(Topic instance) => <String, dynamic>{
  'topic': instance.topic,
  'detail': instance.detail,
  'questions': instance.questions,
};
