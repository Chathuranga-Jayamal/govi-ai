class AuthUser {
  const AuthUser({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.preferredLanguage,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    userId: json['user_id'] as int,
    fullName: json['full_name'] as String,
    email: json['email'] as String,
    phoneNumber: json['phone_number'] as String?,
    preferredLanguage: json['preferred_language'] as String?,
  );

  final int userId;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? preferredLanguage;
}
