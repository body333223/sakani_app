import 'package:equatable/equatable.dart';
import 'package:sakani/core/usecase/usecase.dart';
import 'package:sakani/core/utils/result.dart';
import 'package:sakani/features/apartments/domain/repositories/apartment_repository.dart';

class UpdateApartmentParams extends Equatable {
  final String id;
  final Map<String, dynamic> data;

  const UpdateApartmentParams({required this.id, required this.data});

  @override
  List<Object?> get props => [id, data];
}

class UpdateApartmentUseCase implements UseCase<void, UpdateApartmentParams> {
  final ApartmentRepository repository;

  UpdateApartmentUseCase(this.repository);

  @override
  Future<Result<void>> call(UpdateApartmentParams params) {
    return repository.updateApartment(params.id, params.data);
  }
}
