import 'package:sakani/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.name,
    required super.phone,
    required super.role,
    super.photoUrl,
    required super.createdAt,
    super.nationalId,
    super.idFrontPath,
    super.idBackPath,
    super.isApproved = true,
    super.isIdVerified = false,
    super.inviteCode,
    super.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'nationalId': nationalId,
      'idFrontPath': idFrontPath,
      'idBackPath': idBackPath,
      'isApproved': isApproved,
      'isIdVerified': isIdVerified,
      'inviteCode': inviteCode,
      'status': status,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    final role = map['role'] ?? 'tenant';
    final isApprovedDefault = role == 'tenant';
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: role,
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      nationalId: map['nationalId'],
      idFrontPath: map['idFrontPath'],
      idBackPath: map['idBackPath'],
      isApproved: map['isApproved'] is bool ? map['isApproved'] : (map['isApproved'] == 1 || isApprovedDefault),
      isIdVerified: map['isIdVerified'] is bool ? map['isIdVerified'] : (map['isIdVerified'] == 1 || map['isIdVerified'] == true),
      inviteCode: map['inviteCode'],
      status: map['status'] ?? (role == 'owner' && map['isApproved'] != true ? 'pending_approval' : 'active'),
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    String? role,
    String? photoUrl,
    DateTime? createdAt,
    String? nationalId,
    String? idFrontPath,
    String? idBackPath,
    bool? isApproved,
    bool? isIdVerified,
    String? inviteCode,
    String? status,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      nationalId: nationalId ?? this.nationalId,
      idFrontPath: idFrontPath ?? this.idFrontPath,
      idBackPath: idBackPath ?? this.idBackPath,
      isApproved: isApproved ?? this.isApproved,
      isIdVerified: isIdVerified ?? this.isIdVerified,
      inviteCode: inviteCode ?? this.inviteCode,
      status: status ?? this.status,
    );
  }
}

/// Backwards compatibility alias
typedef AppUser = UserModel;

