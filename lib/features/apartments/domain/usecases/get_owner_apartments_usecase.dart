import 'package:sakani/features/apartments/domain/entities/apartment_entity.dart';
import 'package:sakani/features/apartments/domain/repositories/apartment_repository.dart';

class GetOwnerApartmentsUseCase {
  final ApartmentRepository repository;

  GetOwnerApartmentsUseCase(this.repository);

  Stream<List<ApartmentEntity>> call(String ownerId) {
    return repository.getOwnerApartments(ownerId);
  }
}
