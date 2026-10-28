import 'package:flutter/foundation.dart';

class User {
  const User({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.gender,
    this.email,
    this.image,
});
  final int id;
  final String username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? image;


  String get fullName {
    final name = [firstName, lastName]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ');
    return name.isEmpty ? username : name;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      gender: json['gender'] as String?,
      image: json['image'] as String?,
    );
  }
}
