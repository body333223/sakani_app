class SupportTicketModel {
  final String id;
  final String userId;
  final String userName;
  final String? userEmail;
  final String? userPhone;
  final String? assignedAgentId;
  final String? assignedAgentName;
  final String subject;
  final String status;
  final String shift;
  final String? lastMessage;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  SupportTicketModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userEmail,
    this.userPhone,
    this.assignedAgentId,
    this.assignedAgentName,
    required this.subject,
    required this.status,
    required this.shift,
    this.lastMessage,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userEmail: json['userEmail']?.toString(),
      userPhone: json['userPhone']?.toString(),
      assignedAgentId: json['assignedAgentId']?.toString(),
      assignedAgentName: json['assignedAgentName']?.toString(),
      subject: json['subject']?.toString() ?? 'طلب دعم فني',
      status: json['status']?.toString() ?? 'open',
      shift: json['shift']?.toString() ?? 'morning',
      lastMessage: json['lastMessage']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastUpdatedAt: json['lastUpdatedAt'] != null
          ? DateTime.tryParse(json['lastUpdatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'assignedAgentId': assignedAgentId,
      'assignedAgentName': assignedAgentName,
      'subject': subject,
      'status': status,
      'shift': shift,
      'lastMessage': lastMessage,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }
}

class SupportMessageModel {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String senderRole; // "customer", "agent", "admin"
  final String text;
  final DateTime timestamp;

  SupportMessageModel({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.timestamp,
  });

  bool get isFromAgent => senderRole == 'agent' || senderRole == 'admin';

  factory SupportMessageModel.fromJson(Map<String, dynamic> json) {
    return SupportMessageModel(
      id: json['id']?.toString() ?? '',
      ticketId: json['ticketId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? 'customer',
      text: json['text']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
