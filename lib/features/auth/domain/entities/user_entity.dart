import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String role; // 'owner' or 'tenant'
  final String? photoUrl;
  final DateTime createdAt;
  final String? nationalId;
  final String? idFrontPath;
  final String? idBackPath;
  final bool isApproved;
  final bool isIdVerified;
  final String? inviteCode;
  final String status; // 'active', 'pending_approval', 'rejected'

  const UserEntity({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.photoUrl,
    required this.createdAt,
    this.nationalId,
    this.idFrontPath,
    this.idBackPath,
    this.isApproved = true,
    this.isIdVerified = false,
    this.inviteCode,
    this.status = 'active',
  });

  bool get isOwner => role == 'owner';
  bool get isTenant => role == 'tenant';
  bool get isOwnerPendingApproval => isOwner && (!isApproved || status == 'pending_approval');

  @override
  List<Object?> get props => [
        uid,
        email,
        name,
        phone,
        role,
        photoUrl,
        createdAt,
        nationalId,
        idFrontPath,
        idBackPath,
        isApproved,
        isIdVerified,
        inviteCode,
        status,
      ];
}
