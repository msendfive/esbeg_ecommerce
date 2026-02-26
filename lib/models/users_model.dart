class User {
  final String userOid;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String? avatarUrl;

  User({
    required this.userOid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userOid: json['user_oid'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }
}
