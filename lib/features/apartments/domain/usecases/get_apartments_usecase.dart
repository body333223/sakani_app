import 'package:equatable/equatable.dart';
import 'package:sakani/features/apartments/domain/entities/apartment_entity.dart';
import 'package:sakani/features/apartments/domain/repositories/apartment_repository.dart';

class GetApartmentsParams extends Equatable {
  final String? city;
  final double? maxPrice;

  const GetApartmentsParams({this.city, this.maxPrice});

  @override
  List<Object?> get props => [city, maxPrice];
}

class GetApartmentsUseCase {
  final ApartmentRepository repository;

  GetApartmentsUseCase(this.repository);

  Stream<List<ApartmentEntity>> call([GetApartmentsParams? params]) {
    return repository.getApartments(
      city: params?.city,
      maxPrice: params?.maxPrice,
    );
  }
}
