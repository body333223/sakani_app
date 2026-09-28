import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';
import 'package:sakani/features/apartments/data/services/apartment_service.dart';

class ApartmentProvider extends ChangeNotifier {
  final ApartmentService _apartmentService = ApartmentService();
  final List<Apartment> _apartments = [];
  List<Apartment> _ownerApartments = [];
  Apartment? _selectedApartment;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCity = '';
  StreamSubscription<List<Apartment>>? _apartmentsSubscription;
  StreamSubscription<List<Apartment>>? _ownerApartmentsSubscription;

  List<Apartment> get apartments => _filteredApartments;
  List<Apartment> get ownerApartments => _ownerApartments;
  Apartment? get selectedApartment => _selectedApartment;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCity => _selectedCity;

  /// استخراج قائمة المدن المتاحة ديناميكياً من العقارات المتاحة
  List<String> get availableCities {
    final cities = _apartments
        .map((a) => a.city.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    cities.sort();
    return cities;
  }

  List<Apartment> get _filteredApartments {
    var list = _apartments;
    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
            (a) =>
                a.title.contains(_searchQuery) ||
                a.city.contains(_searchQuery) ||
                a.address.contains(_searchQuery),
          )
          .toList();
    }
    if (_selectedCity.isNotEmpty) {
      list = list.where((a) => a.city == _selectedCity).toList();
    }
    list = list.where((a) => a.isAvailable).toList();
    return list;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCity(String city) {
    _selectedCity = city;
    notifyListeners();
  }

  Future<void> getOwnerApartments(String ownerId) async {
    if (_ownerApartments.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      await _ownerApartmentsSubscription?.cancel();
      _ownerApartmentsSubscription = _apartmentService.getOwnerApartments(ownerId).listen(
        (list) {
          _ownerApartments = list;
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          _error = e.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> addApartment(
    Apartment apartment, {
    List<dynamic>? images,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final id = await _apartmentService.addApartment(apartment);
      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteApartment(String id) async {
    try {
      await _apartmentService.deleteApartment(id);
      _ownerApartments.removeWhere((a) => a.id == id);
      _apartments.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> getApartments() async {
    if (_apartments.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      await _apartmentsSubscription?.cancel();
      _apartmentsSubscription = _apartmentService.getApartments().listen(
        (list) {
          _apartments.clear();
          _apartments.addAll(list);
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          _error = e.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleAvailability(String id, bool available) async {
    try {
      final idx = _ownerApartments.indexWhere((a) => a.id == id);
      if (idx != -1) {
        final old = _ownerApartments[idx];
        _ownerApartments[idx] = old.copyWith(isAvailable: available);
        notifyListeners();
      }
      await _apartmentService.updateApartment(id, {'isAvailable': available});
    } catch (e) {
      _error = e.toString();
    }
  }

  @override
  void dispose() {
    _apartmentsSubscription?.cancel();
    _ownerApartmentsSubscription?.cancel();
    super.dispose();
  }
}
