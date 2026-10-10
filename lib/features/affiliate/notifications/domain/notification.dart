class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
    this.type,
    this.imageUrl,
    this.link,
  });

  final dynamic id;
  final String title;
  final String message;
  final bool isRead;
  final String? createdAt;

  /// `offer`, `success`, `error`, `info`, …
  final String? type;

  /// Offer banner/logo for "new offer" notifications.
  final String? imageUrl;

  /// Web-style link the notification points at, e.g. `/offer-detail?o=abc123`.
  final String? link;

  /// Offer to open when tapped, taken from [link].
  String? get offId {
    final o = Uri.tryParse(link ?? '')?.queryParameters['o'];
    return (o == null || o.isEmpty) ? null : o;
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    String? str(dynamic v) => (v == null || v.toString().isEmpty) ? null : v.toString();
    return AppNotification(
      id: json['id'],
      title: (json['title'] ?? json['heading'] ?? '').toString(),
      message: (json['message'] ?? json['body'] ?? json['text'] ?? '').toString(),
      isRead: json['isRead'] == true || json['is_read'] == 1 || json['is_read'] == true,
      createdAt: (json['createdAt'] ?? json['date'] ?? json['created_at'])?.toString(),
      type: str(json['type']),
      imageUrl: str(json['imageUrl'] ?? json['image_url']),
      link: str(json['link']),
    );
  }
}
