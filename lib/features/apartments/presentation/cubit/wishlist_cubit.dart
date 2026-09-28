import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakani/core/security/secure_storage_service.dart';

class WishlistCubit extends Cubit<Set<String>> {
  static const String _storageKey = '__sakani_user_wishlist_ids__';

  WishlistCubit() : super({}) {
    _loadFavorites();
  }

  void _loadFavorites() {
    final raw = SecureStorageService.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List).map((e) => e.toString()).toSet();
        emit(list);
      } catch (_) {
        emit({});
      }
    }
  }

  bool isFavorite(String apartmentId) => state.contains(apartmentId);

  void toggleFavorite(String apartmentId) {
    final updated = Set<String>.from(state);
    if (updated.contains(apartmentId)) {
      updated.remove(apartmentId);
    } else {
      updated.add(apartmentId);
    }
    emit(updated);
    _saveFavorites(updated);
  }

  void _saveFavorites(Set<String> favorites) {
    SecureStorageService.setString(_storageKey, jsonEncode(favorites.toList()));
  }
}
