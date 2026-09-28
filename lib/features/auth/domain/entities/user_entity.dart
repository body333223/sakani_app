import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String role; // 'owner' or 'tenant'
  final String? photoUrl;
  final DateTime createdAt;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.photoUrl,
    required this.createdAt,
  });

  bool get isOwner => role == 'owner';
  bool get isTenant => role == 'tenant';

  @override
  List<Object?> get props => [uid, email, name, phone, role, photoUrl, createdAt];
}
