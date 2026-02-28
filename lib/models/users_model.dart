// class User {
//   final String userOid;
//   final String fullName;
//   final String email;
//   final String phone;
//   final String role;
//   final String status;
//   final String? avatarUrl;

//   User({
//     required this.userOid,
//     required this.fullName,
//     required this.email,
//     required this.phone,
//     required this.role,
//     required this.status,
//     this.avatarUrl,
//   });

//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       userOid: json['user_oid'] ?? '',
//       fullName: json['full_name'] ?? '',
//       email: json['email'] ?? '',
//       phone: json['phone'] ?? '',
//       role: json['role'] ?? '',
//       status: json['status'] ?? '',
//       avatarUrl: json['avatar_url'],
//     );
//   }
// }

class User {
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? role;

  User({this.fullName, this.email, this.phone, this.avatarUrl, this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      fullName: json['full_name'] ?? json['name'],
      email: json['email'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      role: json['role'],
    );
  }

  User copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? role,
  }) {
    return User(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
    );
  }
}
