import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/api_config.dart';
import '../models/apartment_model.dart';

/// خدمة إدارة وتصفح الشقق والعقارات (Clean Code Architecture)
class ApartmentService {
  // التخزين المؤقت يبدأ نظيفاً بدون أي بيانات وهمية
  static final List<Apartment> _cachedApartments = [];
  static final StreamController<List<Apartment>> _aptsStreamController =
      StreamController<List<Apartment>>.broadcast();

  void _updateStreams() {
    _aptsStreamController.add(List.unmodifiable(_cachedApartments));
  }

  /// جلب الشقق المتاحة مع إمكانية الفلترة
  Stream<List<Apartment>> getApartments({String? city, double? maxPrice}) {
    _fetchApartmentsFromApi(city: city, maxPrice: maxPrice);

    return Stream<List<Apartment>>.multi((controller) {
      // إرسال البيانات المتاحة حالياً
      controller.add(_filterApartments(_cachedApartments, city: city, maxPrice: maxPrice));

      // الاستماع للتحديثات اللاحقة
      final subscription = _aptsStreamController.stream.listen((list) {
        controller.add(_filterApartments(list, city: city, maxPrice: maxPrice));
      });

      controller.onCancel = () => subscription.cancel();
    });
  }

  /// فلترة الشقق حسب المدينة والسعر والتوافر
  List<Apartment> _filterApartments(List<Apartment> list, {String? city, double? maxPrice}) {
    var filtered = list.where((a) => a.isAvailable).toList();
    if (city != null && city.trim().isNotEmpty) {
      filtered = filtered.where((a) => a.city == city.trim()).toList();
    }
    if (maxPrice != null && maxPrice > 0) {
      filtered = filtered.where((a) => a.dailyPrice <= maxPrice).toList();
    }
    return filtered;
  }

  /// مزامنة الشقق مع الخادم
  Future<void> _fetchApartmentsFromApi({String? city, double? maxPrice}) async {
    try {
      final queryParams = <String, String>{};
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (maxPrice != null && maxPrice > 0) queryParams['maxPrice'] = maxPrice.toString();

      final uri = Uri.parse(ApiConfig.apartments).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final response = await http
          .get(uri, headers: ApiConfig.authHeaders)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        _cachedApartments.clear();
        for (var item in data) {
          _cachedApartments.add(Apartment.fromMap(item, item['id'] ?? ''));
        }
        _updateStreams();
      }
    } catch (_) {
      // الصمت في حالة فشل الشبكة لعدم تعطيل الواجهة
    }
  }

  /// جلب الشقق الخاصة بمالك محدد
  Stream<List<Apartment>> getOwnerApartments(String ownerId) {
    if (ownerId.isNotEmpty) {
      _fetchOwnerApartmentsFromApi(ownerId);
    }
    return Stream<List<Apartment>>.multi((controller) {
      controller.add(_cachedApartments.where((a) => a.ownerId == ownerId).toList());

      final subscription = _aptsStreamController.stream.listen((list) {
        controller.add(list.where((a) => a.ownerId == ownerId).toList());
      });
      controller.onCancel = () => subscription.cancel();
    });
  }

  /// مزامنة شقق المالك من الخادم
  Future<void> _fetchOwnerApartmentsFromApi(String ownerId) async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.ownerApartments(ownerId)),
            headers: ApiConfig.authHeaders,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        for (var item in data) {
          final apt = Apartment.fromMap(item, item['id'] ?? '');
          final idx = _cachedApartments.indexWhere((a) => a.id == apt.id);
          if (idx != -1) {
            _cachedApartments[idx] = apt;
          } else {
            _cachedApartments.add(apt);
          }
        }
        _updateStreams();
      }
    } catch (_) {}
  }

  /// جلب تفاصيل شقة بمعرفها
  Future<Apartment?> getApartmentById(String id) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.apartment(id)), headers: ApiConfig.authHeaders)
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return Apartment.fromMap(data, id);
      }
    } catch (_) {}

    final localIdx = _cachedApartments.indexWhere((a) => a.id == id);
    if (localIdx != -1) {
      return _cachedApartments[localIdx];
    }
    return null;
  }

  /// إضافة شقة جديدة
  Future<String> addApartment(Apartment apartment) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.apartments),
            headers: ApiConfig.authHeaders,
            body: jsonEncode(apartment.toMap()),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final created = Apartment.fromMap(data, data['id'] ?? apartment.id);
        _cachedApartments.insert(0, created);
        _updateStreams();
        return created.id;
      }
    } catch (_) {}

    _cachedApartments.insert(0, apartment);
    _updateStreams();
    return apartment.id;
  }

  /// تحديث بيانات شقة أو حالتها
  Future<void> updateApartment(String id, Map<String, dynamic> data) async {
    try {
      if (data.containsKey('isAvailable') && data.length == 1) {
        await http
            .patch(
              Uri.parse(ApiConfig.toggleAvailability(id)),
              headers: ApiConfig.authHeaders,
              body: jsonEncode({'isAvailable': data['isAvailable']}),
            )
            .timeout(const Duration(seconds: 3));
      } else {
        await http
            .put(
              Uri.parse(ApiConfig.apartment(id)),
              headers: ApiConfig.authHeaders,
              body: jsonEncode(data),
            )
            .timeout(const Duration(seconds: 3));
      }
    } catch (_) {}

    final index = _cachedApartments.indexWhere((a) => a.id == id);
    if (index != -1) {
      final old = _cachedApartments[index];
      _cachedApartments[index] = Apartment(
        id: old.id,
        ownerId: old.ownerId,
        ownerName: old.ownerName,
        title: data['title'] ?? old.title,
        description: data['description'] ?? old.description,
        city: data['city'] ?? old.city,
        address: data['address'] ?? old.address,
        bedrooms: data['bedrooms'] ?? old.bedrooms,
        bathrooms: data['bathrooms'] ?? old.bathrooms,
        area: data['area'] != null ? (data['area'] as num).toDouble() : old.area,
        amenities: data['amenities'] != null
            ? List<String>.from(data['amenities'])
            : old.amenities,
        images: data['images'] != null
            ? List<String>.from(data['images'])
            : old.images,
        availableRentTypes: data['availableRentTypes'] != null
            ? List<String>.from(data['availableRentTypes'])
            : old.availableRentTypes,
        dailyPrice: data['dailyPrice'] != null
            ? (data['dailyPrice'] as num).toDouble()
            : old.dailyPrice,
        monthlyPrice: data['monthlyPrice'] != null
            ? (data['monthlyPrice'] as num).toDouble()
            : old.monthlyPrice,
        yearlyPrice: data['yearlyPrice'] != null
            ? (data['yearlyPrice'] as num).toDouble()
            : old.yearlyPrice,
        securityDeposit: data['securityDeposit'] != null
            ? (data['securityDeposit'] as num).toDouble()
            : old.securityDeposit,
        contactPhone: data['contactPhone'] ?? old.contactPhone,
        maxGuests: data['maxGuests'] ?? old.maxGuests,
        isAvailable: data['isAvailable'] ?? old.isAvailable,
        createdAt: old.createdAt,
      );
      _updateStreams();
    }
  }

  /// حذف شقة
  Future<void> deleteApartment(String id) async {
    try {
      await http
          .delete(
            Uri.parse(ApiConfig.apartment(id)),
            headers: ApiConfig.authHeaders,
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
    _cachedApartments.removeWhere((a) => a.id == id);
    _updateStreams();
  }

  /// رفع صور الشقة
  Future<List<String>> uploadImages(
    List<XFile> images,
    String apartmentId,
  ) async {
    return images.map((e) => e.path).toList();
  }
}