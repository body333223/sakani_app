import 'package:equatable/equatable.dart';

/// Base Failure class for Clean Architecture.
/// All domain-level errors extend this class.
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'حدث خطأ في الخادم، يرجى المحاولة لاحقاً',
    int? statusCode,
  ]) : super(statusCode: statusCode);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'تعذر الاتصال بالشبكة، يرجى التحقق من اتصال الإنترنت',
  ]);
}

class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'فشل في تسجيل الدخول أو انتهاء صلاحية الجلسة',
    int? statusCode,
  ]) : super(statusCode: statusCode);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'فشل في استرجاع البيانات المحفوظة محلياً']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'البيانات المدخلة غير صحيحة']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'العنصر المطلوب غير موجود']);
}
