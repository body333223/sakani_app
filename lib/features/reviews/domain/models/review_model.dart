/// نموذج التقييم المتبادل الموثق (Mutual Review Model)
class ReviewModel {
  final String id;
  final String bookingId;
  final String apartmentId;
  final String apartmentTitle;

  // المقيم
  final String reviewerId;
  final String reviewerName;
  final String reviewerRole; // 'tenant' أو 'owner'

  // المستهدف بالتقييم
  final String targetId;
  final String targetRole; // 'owner' أو 'tenant'

  // التقييمات التفصيلية (من 1 إلى 5)
  final double overallRating;
  final double cleanlinessRating;
  final double communicationRating;
  final double commitmentRating; // الالتزام المالي / دقة الوصف

  final String comment;
  final List<String> tags; // الشارات السريعة مثل ['نظيف جداً', 'ملتزم بالمواعيد']
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.apartmentId,
    required this.apartmentTitle,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerRole,
    required this.targetId,
    required this.targetRole,
    required this.overallRating,
    required this.cleanlinessRating,
    required this.communicationRating,
    required this.commitmentRating,
    required this.comment,
    this.tags = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'apartmentId': apartmentId,
      'apartmentTitle': apartmentTitle,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerRole': reviewerRole,
      'targetId': targetId,
      'targetRole': targetRole,
      'overallRating': overallRating,
      'cleanlinessRating': cleanlinessRating,
      'communicationRating': communicationRating,
      'commitmentRating': commitmentRating,
      'comment': comment,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] ?? '',
      bookingId: map['bookingId'] ?? '',
      apartmentId: map['apartmentId'] ?? '',
      apartmentTitle: map['apartmentTitle'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      reviewerName: map['reviewerName'] ?? '',
      reviewerRole: map['reviewerRole'] ?? 'tenant',
      targetId: map['targetId'] ?? '',
      targetRole: map['targetRole'] ?? 'owner',
      overallRating: (map['overallRating'] ?? 5.0).toDouble(),
      cleanlinessRating: (map['cleanlinessRating'] ?? 5.0).toDouble(),
      communicationRating: (map['communicationRating'] ?? 5.0).toDouble(),
      commitmentRating: (map['commitmentRating'] ?? 5.0).toDouble(),
      comment: map['comment'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

/// بيانات شارة الثقة المحسوبة
class TrustBadgeData {
  final String title;
  final String subtitle;
  final double score;
  final int totalReviews;
  final bool isVerified;

  const TrustBadgeData({
    required this.title,
    required this.subtitle,
    required this.score,
    required this.totalReviews,
    this.isVerified = true,
  });
}
