import 'dart:async';
import 'package:sakani/core/error/exceptions.dart';
import 'package:sakani/core/error/failures.dart';
import 'package:sakani/core/utils/result.dart';
import 'package:sakani/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:sakani/features/bookings/data/models/booking_model.dart';
import 'package:sakani/features/bookings/domain/entities/booking_entity.dart';
import 'package:sakani/features/bookings/domain/repositories/booking_repository.dart';
import 'package:sakani/features/auth/data/services/auth_service.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;
  final List<BookingModel> _cache = [];
  final StreamController<List<BookingEntity>> _streamController =
      StreamController<List<BookingEntity>>.broadcast();

  BookingRepositoryImpl({required this.remoteDataSource});

  void _notify() {
    _streamController.add(List.unmodifiable(_cache));
  }

  @override
  Stream<List<BookingEntity>> getTenantBookings(String tenantId) {
    _fetchTenantRemote(tenantId);

    return Stream<List<BookingEntity>>.multi((controller) {
      final initial = _cache.where((b) => b.tenantId == tenantId).toList();
      initial.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(initial);

      final sub = _streamController.stream.listen((list) {
        final filtered = list.where((b) => b.tenantId == tenantId).toList();
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        controller.add(filtered);
      });

      controller.onCancel = () => sub.cancel();
    });
  }

  Future<void> _fetchTenantRemote(String tenantId) async {
    try {
      final remoteList = await remoteDataSource.getTenantBookings(tenantId);
      for (final item in remoteList) {
        final idx = _cache.indexWhere((b) => b.id == item.id);
        if (idx != -1) {
          _cache[idx] = item;
        } else {
          _cache.add(item);
        }
      }
      _notify();
    } catch (_) {}
  }

  @override
  Stream<List<BookingEntity>> getOwnerBookings(String ownerId) {
    _fetchOwnerRemote(ownerId);

    return Stream<List<BookingEntity>>.multi((controller) {
      final initial = _cache.where((b) => b.ownerId == ownerId).toList();
      initial.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(initial);

      final sub = _streamController.stream.listen((list) {
        final filtered = list.where((b) => b.ownerId == ownerId).toList();
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        controller.add(filtered);
      });

      controller.onCancel = () => sub.cancel();
    });
  }

  Future<void> _fetchOwnerRemote(String ownerId) async {
    try {
      final remoteList = await remoteDataSource.getOwnerBookings(ownerId);
      for (final item in remoteList) {
        final idx = _cache.indexWhere((b) => b.id == item.id);
        if (idx != -1) {
          _cache[idx] = item;
        } else {
          _cache.add(item);
        }
      }
      _notify();
    } catch (_) {}
  }

  @override
  Future<Result<String>> createBooking(BookingEntity booking) async {
    if (booking.tenantId.trim().isEmpty || booking.tenantId == booking.ownerId) {
      return FailureResult(ServerFailure('لا يمكنك حجز عقار مسجل باسمك.'));
    }
    final directUser = AuthService.currentUser;
    if (directUser != null && (directUser.role == 'owner' || directUser.isOwner)) {
      return FailureResult(ServerFailure('عذراً، حسابات التجار مخصصة للإدارة فقط ولا يمكن إجراء حجز منها.'));
    }

    try {
      final model = BookingModel.fromEntity(booking);
      final id = await remoteDataSource.createBooking(model);
      final created = BookingModel(
        id: id,
        apartmentId: model.apartmentId,
        apartmentTitle: model.apartmentTitle,
        tenantId: model.tenantId,
        tenantName: model.tenantName,
        ownerId: model.ownerId,
        startDate: model.startDate,
        endDate: model.endDate,
        periodType: model.periodType,
        totalAmount: model.totalAmount,
        commissionAmount: model.commissionAmount,
        securityDeposit: model.securityDeposit,
        status: model.status,
        guests: model.guests,
        createdAt: model.createdAt,
      );
      _cache.insert(0, created);
      _notify();
      return Success(id);
    } catch (e) {
      return FailureResult(ServerFailure('حدث خطأ أثناء إتمام الحجز: $e'));
    }
  }

  @override
  Future<Result<void>> updateBookingStatus(String bookingId, String status) async {
    try {
      await remoteDataSource.updateBookingStatus(bookingId, status);
      final idx = _cache.indexWhere((b) => b.id == bookingId);
      if (idx != -1) {
        final old = _cache[idx];
        _cache[idx] = BookingModel(
          id: old.id,
          apartmentId: old.apartmentId,
          apartmentTitle: old.apartmentTitle,
          tenantId: old.tenantId,
          tenantName: old.tenantName,
          ownerId: old.ownerId,
          startDate: old.startDate,
          endDate: old.endDate,
          periodType: old.periodType,
          totalAmount: old.totalAmount,
          commissionAmount: old.commissionAmount,
          securityDeposit: old.securityDeposit,
          status: status,
          guests: old.guests,
          createdAt: old.createdAt,
        );
        _notify();
      }
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e) {
      return FailureResult(ServerFailure('فشل في تحديث الحجز: $e'));
    }
  }
}
