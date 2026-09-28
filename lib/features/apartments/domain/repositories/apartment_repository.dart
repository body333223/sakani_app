import 'package:image_picker/image_picker.dart';
import 'package:sakani/core/utils/result.dart';
import 'package:sakani/features/apartments/domain/entities/apartment_entity.dart';

abstract class ApartmentRepository {
  Stream<List<ApartmentEntity>> getApartments({String? city, double? maxPrice});

  Stream<List<ApartmentEntity>> getOwnerApartments(String ownerId);

  Future<Result<ApartmentEntity?>> getApartmentById(String id);

  Future<Result<String>> addApartment(ApartmentEntity apartment);

  Future<Result<void>> updateApartment(String id, Map<String, dynamic> data);

  Future<Result<void>> deleteApartment(String id);

  Future<Result<List<String>>> uploadImages(List<XFile> images, String apartmentId);
}
