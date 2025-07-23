// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'msg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Msg _$MsgFromJson(Map<String, dynamic> json) => Msg(
  isUser: json['isUser'] as bool,
  msg: json['msg'] as String,
  image: const Uint8ListConverter().fromJson(json['image'] as String?),
);

Map<String, dynamic> _$MsgToJson(Msg instance) => <String, dynamic>{
  'isUser': instance.isUser,
  'msg': instance.msg,
  'image': const Uint8ListConverter().toJson(instance.image),
};
