import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:sakani/core/config/api_config.dart';
import 'package:sakani/core/error/exceptions.dart';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';

abstract class ApartmentRemoteDataSource {
  Future<List<ApartmentModel>> getApartments({String? city, double? maxPrice});
  Future<List<ApartmentModel>> getOwnerApartments(String ownerId);
  Future<ApartmentModel?> getApartmentById(String id);
  Future<String> addApartment(ApartmentModel apartment);
  Future<void> updateApartment(String id, Map<String, dynamic> data);
  Future<void> deleteApartment(String id);
  Future<List<String>> uploadImages(List<XFile> images, String apartmentId);
}

class ApartmentRemoteDataSourceImpl implements ApartmentRemoteDataSource {
  final http.Client client;

  ApartmentRemoteDataSourceImpl({required this.client});

  @override
  Future<List<ApartmentModel>> getApartments({String? city, double? maxPrice}) async {
    try {
      final queryParams = <String, String>{};
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (maxPrice != null && maxPrice > 0) queryParams['maxPrice'] = maxPrice.toString();

      final uri = Uri.parse(ApiConfig.apartments).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await client
          .get(uri, headers: ApiConfig.authHeaders)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((item) => ApartmentModel.fromMap(item, item['id'] ?? '')).toList();
      } else {
        throw ServerException('فشل في جلب قائمة الشقق', response.statusCode);
      }
    } on http.ClientException {
      throw const NetworkException('تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت');
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ApartmentModel>> getOwnerApartments(String ownerId) async {
    try {
      final response = await client
          .get(
            Uri.parse(ApiConfig.ownerApartments(ownerId)),
            headers: ApiConfig.authHeaders,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((item) => ApartmentModel.fromMap(item, item['id'] ?? '')).toList();
      } else {
        throw ServerException('فشل في جلب شقق المالك', response.statusCode);
      }
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ApartmentModel?> getApartmentById(String id) async {
    try {
      final response = await client
          .get(Uri.parse(ApiConfig.apartment(id)), headers: ApiConfig.authHeaders)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return ApartmentModel.fromMap(data, id);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> addApartment(ApartmentModel apartment) async {
    try {
      final response = await client
          .post(
            Uri.parse(ApiConfig.apartments),
            headers: ApiConfig.authHeaders,
            body: jsonEncode(apartment.toMap()),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['id'] ?? apartment.id;
      }
      return apartment.id;
    } catch (_) {
      return apartment.id;
    }
  }

  @override
  Future<void> updateApartment(String id, Map<String, dynamic> data) async {
    try {
      if (data.containsKey('isAvailable') && data.length == 1) {
        await client
            .patch(
              Uri.parse(ApiConfig.toggleAvailability(id)),
              headers: ApiConfig.authHeaders,
              body: jsonEncode({'isAvailable': data['isAvailable']}),
            )
            .timeout(const Duration(seconds: 4));
      } else {
        await client
            .put(
              Uri.parse(ApiConfig.apartment(id)),
              headers: ApiConfig.authHeaders,
              body: jsonEncode(data),
            )
            .timeout(const Duration(seconds: 4));
      }
    } catch (_) {}
  }

  @override
  Future<void> deleteApartment(String id) async {
    try {
      await client
          .delete(
            Uri.parse(ApiConfig.apartment(id)),
            headers: ApiConfig.authHeaders,
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  @override
  Future<List<String>> uploadImages(List<XFile> images, String apartmentId) async {
    return images.map((e) => e.path).toList();
  }
}
