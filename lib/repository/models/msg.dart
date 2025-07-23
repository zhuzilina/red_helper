import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';
import 'package:red_helper/repository/models/uint8list_converter.dart';

part 'msg.g.dart';

@JsonSerializable(converters: [Uint8ListConverter()])
class Msg {
  final bool isUser;
  String msg;
  Uint8List? image;

  Msg({required this.isUser, required this.msg, this.image});

  // 从JSON反序列化
  factory Msg.fromJson(Map<String, dynamic> json) => _$MsgFromJson(json);

  // 序列化为JSON
  Map<String, dynamic> toJson() => _$MsgToJson(this);
}
