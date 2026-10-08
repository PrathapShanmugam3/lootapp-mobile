class AppNotification {
  const AppNotification({required this.id, required this.title, required this.message, required this.isRead, this.createdAt});

  final dynamic id;
  final String title;
  final String message;
  final bool isRead;
  final String? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'],
        title: (json['title'] ?? json['heading'] ?? '').toString(),
        message: (json['message'] ?? json['body'] ?? json['text'] ?? '').toString(),
        isRead: json['isRead'] == true || json['is_read'] == 1 || json['is_read'] == true,
        createdAt: (json['createdAt'] ?? json['date'] ?? json['created_at'])?.toString(),
      );
}
