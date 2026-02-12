import 'dart:convert';
import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';

// 自定义 Uint8List 与 Base64 字符串的转换器
class Uint8ListConverter implements JsonConverter<Uint8List?, String?> {
  const Uint8ListConverter();

  @override
  Uint8List? fromJson(String? json) {
    if (json == null) return null;
    return base64Decode(json); // 将 Base64 字符串解码为 Uint8List
  }

  @override
  String? toJson(Uint8List? object) {
    if (object == null) return null;
    return base64Encode(object); // 将 Uint8List 编码为 Base64 字符串
  }
}
