import 'package:sakani/core/usecase/usecase.dart';
import 'package:sakani/core/utils/result.dart';
import 'package:sakani/features/apartments/domain/entities/apartment_entity.dart';
import 'package:sakani/features/apartments/domain/repositories/apartment_repository.dart';

class AddApartmentUseCase implements UseCase<String, ApartmentEntity> {
  final ApartmentRepository repository;

  AddApartmentUseCase(this.repository);

  @override
  Future<Result<String>> call(ApartmentEntity params) {
    return repository.addApartment(params);
  }
}
