import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:sakani/core/error/exceptions.dart';
import 'package:sakani/core/error/failures.dart';
import 'package:sakani/core/utils/result.dart';
import 'package:sakani/features/apartments/data/datasources/apartment_remote_data_source.dart';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';
import 'package:sakani/features/apartments/domain/entities/apartment_entity.dart';
import 'package:sakani/features/apartments/domain/repositories/apartment_repository.dart';

class ApartmentRepositoryImpl implements ApartmentRepository {
  final ApartmentRemoteDataSource remoteDataSource;
  final List<ApartmentModel> _cache = [];
  final StreamController<List<ApartmentEntity>> _streamController =
      StreamController<List<ApartmentEntity>>.broadcast();

  ApartmentRepositoryImpl({required this.remoteDataSource});

  void _notify() {
    _streamController.add(List.unmodifiable(_cache));
  }

  @override
  Stream<List<ApartmentEntity>> getApartments({String? city, double? maxPrice}) {
    _fetchRemote(city: city, maxPrice: maxPrice);

    return Stream<List<ApartmentEntity>>.multi((controller) {
      controller.add(_filter(_cache, city: city, maxPrice: maxPrice));

      final sub = _streamController.stream.listen((list) {
        controller.add(_filter(list, city: city, maxPrice: maxPrice));
      });

      controller.onCancel = () => sub.cancel();
    });
  }

  List<ApartmentEntity> _filter(List<ApartmentEntity> list, {String? city, double? maxPrice}) {
    var filtered = list.where((a) => a.isAvailable).toList();
    if (city != null && city.trim().isNotEmpty) {
      filtered = filtered.where((a) => a.city == city.trim()).toList();
    }
    if (maxPrice != null && maxPrice > 0) {
      filtered = filtered.where((a) => a.dailyPrice <= maxPrice).toList();
    }
    return filtered;
  }

  Future<void> _fetchRemote({String? city, double? maxPrice}) async {
    try {
      final remoteList = await remoteDataSource.getApartments(city: city, maxPrice: maxPrice);
      _cache.clear();
      _cache.addAll(remoteList);
      _notify();
    } catch (_) {}
  }

  @override
  Stream<List<ApartmentEntity>> getOwnerApartments(String ownerId) {
    _fetchOwnerRemote(ownerId);

    return Stream<List<ApartmentEntity>>.multi((controller) {
      controller.add(_cache.where((a) => a.ownerId == ownerId).toList());

      final sub = _streamController.stream.listen((list) {
        controller.add(list.where((a) => a.ownerId == ownerId).toList());
      });

      controller.onCancel = () => sub.cancel();
    });
  }

  Future<void> _fetchOwnerRemote(String ownerId) async {
    try {
      final ownerList = await remoteDataSource.getOwnerApartments(ownerId);
      for (final apt in ownerList) {
        final idx = _cache.indexWhere((a) => a.id == apt.id);
        if (idx != -1) {
          _cache[idx] = apt;
        } else {
          _cache.add(apt);
        }
      }
      _notify();
    } catch (_) {}
  }

  @override
  Future<Result<ApartmentEntity?>> getApartmentById(String id) async {
    try {
      final apt = await remoteDataSource.getApartmentById(id);
      if (apt != null) {
        final idx = _cache.indexWhere((a) => a.id == id);
        if (idx != -1) {
          _cache[idx] = apt;
        } else {
          _cache.add(apt);
        }
        _notify();
        return Success(apt);
      }
      final local = _cache.where((a) => a.id == id).firstOrNull;
      return Success(local);
    } catch (e) {
      final local = _cache.where((a) => a.id == id).firstOrNull;
      return Success(local);
    }
  }

  @override
  Future<Result<String>> addApartment(ApartmentEntity apartment) async {
    try {
      final model = ApartmentModel.fromEntity(apartment);
      final id = await remoteDataSource.addApartment(model);
      final updated = model.copyWith(id: id);
      _cache.insert(0, updated);
      _notify();
      return Success(id);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e) {
      return FailureResult(ServerFailure('حدث خطأ أثناء إضافة الشقة: $e'));
    }
  }

  @override
  Future<Result<void>> updateApartment(String id, Map<String, dynamic> data) async {
    try {
      await remoteDataSource.updateApartment(id, data);
      final idx = _cache.indexWhere((a) => a.id == id);
      if (idx != -1) {
        final old = _cache[idx];
        final updated = old.copyWith(
          title: data['title'] ?? old.title,
          description: data['description'] ?? old.description,
          city: data['city'] ?? old.city,
          address: data['address'] ?? old.address,
          dailyPrice: data['dailyPrice'] != null ? (data['dailyPrice'] as num).toDouble() : old.dailyPrice,
          monthlyPrice: data['monthlyPrice'] != null ? (data['monthlyPrice'] as num).toDouble() : old.monthlyPrice,
          isAvailable: data['isAvailable'] ?? old.isAvailable,
        );
        _cache[idx] = updated;
        _notify();
      }
      return const Success(null);
    } catch (e) {
      return FailureResult(ServerFailure('فشل في تعديل بيانات الشقة: $e'));
    }
  }

  @override
  Future<Result<void>> deleteApartment(String id) async {
    try {
      await remoteDataSource.deleteApartment(id);
      _cache.removeWhere((a) => a.id == id);
      _notify();
      return const Success(null);
    } catch (e) {
      return FailureResult(ServerFailure('فشل في حذف الشقة: $e'));
    }
  }

  @override
  Future<Result<List<String>>> uploadImages(List<XFile> images, String apartmentId) async {
    try {
      final urls = await remoteDataSource.uploadImages(images, apartmentId);
      return Success(urls);
    } catch (e) {
      return FailureResult(ServerFailure('فشل في رفع الصور: $e'));
    }
  }
}
