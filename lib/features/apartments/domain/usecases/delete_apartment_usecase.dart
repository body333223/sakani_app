import 'package:sakani/core/usecase/usecase.dart';
import 'package:sakani/core/utils/result.dart';
import 'package:sakani/features/apartments/domain/repositories/apartment_repository.dart';

class DeleteApartmentUseCase implements UseCase<void, String> {
  final ApartmentRepository repository;

  DeleteApartmentUseCase(this.repository);

  @override
  Future<Result<void>> call(String apartmentId) {
    return repository.deleteApartment(apartmentId);
  }
}
