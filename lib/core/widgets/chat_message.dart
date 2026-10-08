/// Shared chat message domain model — mirrors chatService.js's
/// `formatMessage()` shape: {id, from, text, imagePath, date, time,
/// timestamp, isRead}. Used by the affiliate chat screen, the manager
/// support inbox, and the admin support screen (all three talk to the same
/// message shape, just different endpoints).
class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.from,
    required this.text,
    this.imagePath,
    this.date,
    this.time,
    this.timestamp,
    this.isRead = false,
  });

  final int id;
  final String from; // 'user' | 'admin'
  final String text;
  final String? imagePath;
  final String? date;
  final String? time;
  final int? timestamp;
  final bool isRead;

  bool get isMine => from != 'admin'; // overridden per-screen via fromSelf

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) => ChatMessageModel(
        id: json['id'] as int,
        from: json['from']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        imagePath: json['imagePath']?.toString(),
        date: json['date']?.toString(),
        time: json['time']?.toString(),
        timestamp: json['timestamp'] is int ? json['timestamp'] as int : null,
        isRead: json['isRead'] == true,
      );
}
