import '../../../core/network/role.dart';

class AppUser {
  const AppUser({
    required this.userId,
    required this.name,
    required this.status,
    this.email,
    this.mobile,
  });

  final String userId;
  final String name;
  final String status;
  final String? email;
  final String? mobile;

  AppRole get role => AppRole.fromStatus(status);

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
        name: (json['name'] as String?) ?? '',
        status: json['status']?.toString() ?? '',
        email: json['email'] as String?,
        mobile: json['mobile'] as String?,
      );
}
