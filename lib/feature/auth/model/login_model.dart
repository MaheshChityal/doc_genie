import 'dart:convert';

class LoginModel {
  const LoginModel({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String role;
  final UserModel? user;

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    final root = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return LoginModel(
      accessToken: (root['accessToken'] ?? root['token'] ?? '').toString(),
      refreshToken: (root['refreshToken'] ?? root['refresh_token'] ?? '')
          .toString(),
      role: (root['role'] ?? 'maker').toString(),
      user: root['user'] is Map<String, dynamic>
          ? UserModel.fromJson(root['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.employeeCode = '',
  });

  final String id;
  final String name;
  final String email;
  final String employeeCode;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: (json['id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    employeeCode: (json['employeeCode'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'employeeCode': employeeCode,
  };

  String encode() => jsonEncode(toJson());
}
