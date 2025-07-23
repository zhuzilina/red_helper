class Assistant {
  final String userId;
  final String dateTime;
  final dynamic content;

  Assistant({
    required this.userId,
    required this.dateTime,
    required this.content,
});
  factory Assistant.fromJson(Map<String, dynamic> json) {
    return Assistant(
      userId: json['user_id'],
      dateTime: json['datetime'],
      content: json['content'],
    );
  }
}