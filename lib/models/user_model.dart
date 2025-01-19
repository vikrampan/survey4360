// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role;
  final String name;
  final DateTime createdAt;
  final bool isActive;
  final String? phone; // Add this line

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    required this.createdAt,
    this.isActive = true,
    this.phone, // Add this parameter
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      role: map['role'] ?? 'surveyor',
      name: map['name'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
      phone: map['phone'], // Add this line
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'name': name,
      'createdAt': createdAt,
      'isActive': isActive,
      'phone': phone, // Add this line
    };
  }
}