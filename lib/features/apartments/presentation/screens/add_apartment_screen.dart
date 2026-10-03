import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sakani/core/config/constants.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';
import 'package:sakani/features/apartments/presentation/providers/apartment_provider.dart';
import 'package:sakani/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakani/core/widgets/gradient_button.dart';
import 'package:sakani/core/widgets/section_header.dart';
import 'package:sakani/core/widgets/app_snackbar.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_cubit.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakani/features/auth/data/services/auth_service.dart';
import 'package:sakani/core/security/security_sanitizer.dart';
import 'package:sakani/core/localization/app_localizations.dart';

class AddApartmentScreen extends StatefulWidget {
  const AddApartmentScreen({super.key});

  @override
  State<AddApartmentScreen> createState() => _AddApartmentScreenState();
}

class _AddApartmentScreenState extends State<AddApartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _cityCtl = TextEditingController();
  final _addressCtl = TextEditingController();
  final _dailyPriceCtl = TextEditingController();
  final _monthlyPriceCtl = TextEditingController();
  final _yearlyPriceCtl = TextEditingController();
  final _depositCtl = TextEditingController();
  final _phoneCtl = TextEditingController();

  int _bedrooms = 1, _bathrooms = 1, _maxGuests = 2;
  double _area = 100;
  final List<String> _selectedAmenities = [];
  final List<String> _availableRentTypes = ['شهري'];

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];

  Future<void> _pickImages() async {
    final List<XFile> picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _images.addAll(picked));
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _descCtl.dispose();
    _cityCtl.dispose();
    _addressCtl.dispose();
    _dailyPriceCtl.dispose();
    _monthlyPriceCtl.dispose();
    _yearlyPriceCtl.dispose();
    _depositCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('minImagesRequired'))),
      );
      return;
    }
    if (_availableRentTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('selectRentTypeMin'))),
      );
      return;
    }
    final authCubit = context.read<AuthCubit>();
    final authProv = context.read<AuthProvider>();
    final direct = AuthService.currentUser;
    final user = authCubit.currentUser ?? authProv.user ?? direct;

    if (user == null || (!user.isOwner && user.role != 'owner')) {
      AppSnackbar.show(
        context,
        message: 'عذراً، إضافة العقارات مقتصرة على أصحاب العقارات والتجار فقط.',
        type: ToastType.error,
      );
      return;
    }

    final daily = double.tryParse(_dailyPriceCtl.text) ?? 0;
    final monthly = double.tryParse(_monthlyPriceCtl.text) ?? 0;
    final yearly = double.tryParse(_yearlyPriceCtl.text) ?? 0;
    final deposit = double.tryParse(_depositCtl.text) ?? 0;

    if (daily < 0 || monthly < 0 || yearly < 0 || deposit < 0) {
      AppSnackbar.show(
        context,
        message: 'القيم المالية لا يمكن أن تكون سالبة',
        type: ToastType.error,
      );
      return;
    }

    final aptProv = context.read<ApartmentProvider>();
    final apartment = Apartment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      ownerId: user.uid,
      ownerName: SecuritySanitizer.sanitizeSql(user.name.isNotEmpty ? user.name : 'مالك عقار'),
      title: SecuritySanitizer.sanitizeSql(_titleCtl.text.trim()),
      description: SecuritySanitizer.sanitizeSql(_descCtl.text.trim()),
      city: SecuritySanitizer.sanitizeSql(_cityCtl.text.trim()),
      address: SecuritySanitizer.sanitizeSql(_addressCtl.text.trim()),
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      area: _area,
      amenities: _selectedAmenities,
      images: _images.map((e) => e.path).toList(),
      availableRentTypes: _availableRentTypes,
      dailyPrice: _availableRentTypes.contains('يومي') ? daily : 0,
      monthlyPrice: _availableRentTypes.contains('شهري') ? monthly : 0,
      yearlyPrice: _availableRentTypes.contains('سنوي') ? yearly : 0,
      securityDeposit: deposit,
      contactPhone: SecuritySanitizer.sanitizeSql(_phoneCtl.text.trim()),
      maxGuests: _maxGuests,
    );
    await aptProv.addApartment(apartment);
    if (!mounted) return;
    try {
      context.read<ApartmentCubit>().loadApartments();
      context.read<ApartmentCubit>().loadOwnerApartments(user.uid);
    } catch (_) {}
    AppSnackbar.show(
      context,
      message: context.tr('propertyAddedSuccess'),
      type: ToastType.success,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = context.watch<AuthCubit>();
    final authProv = context.watch<AuthProvider>();
    final direct = AuthService.currentUser;
    final user = authCubit.currentUser ?? authProv.user ?? direct;
    final isOwner = user != null && (user.isOwner || user.role == 'owner');

    if (!isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('صلاحية غير مصرح بها')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security_rounded, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                const Text(
                  'خاصية إضافة العقارات مقتصرة على أصحاب العقارات والتجار فقط.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('العودة للرئيسية'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('addNewApartment'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Apartment Info ──
              SectionHeader(title: context.tr('propertyInfo')),
              const SizedBox(height: 4),
              TextFormField(
                controller: _titleCtl,
                decoration: InputDecoration(labelText: context.tr('propertyTitle')),
                validator: (v) =>
                    v != null && v.isNotEmpty ? null : context.tr('propertyTitleRequired'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtl,
                decoration: InputDecoration(labelText: context.tr('propertyDescription')),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityCtl,
                decoration: InputDecoration(
                  labelText: context.tr('cityGovernorate'),
                  hintText: context.tr('cityPlaceholder'),
                  prefixIcon: const Icon(Icons.location_city_rounded),
                ),
                validator: (v) =>
                    v != null && v.trim().isNotEmpty ? null : context.tr('cityRequired'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtl,
                decoration: InputDecoration(
                  labelText: context.tr('detailedAddress'),
                  prefixIcon: const Icon(Icons.place_outlined),
                ),
                validator: (v) =>
                    v != null && v.trim().isNotEmpty ? null : context.tr('detailedAddressRequired'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtl,
                decoration: InputDecoration(
                  labelText: context.tr('phoneContact'),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 28),

              // ── Details ──
              SectionHeader(title: context.tr('propertySpecs')),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _Counter(
                      label: context.tr('bedroomsCount'),
                      value: _bedrooms,
                      onChanged: (v) => setState(() => _bedrooms = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Counter(
                      label: context.tr('bathroomsCount'),
                      value: _bathrooms,
                      onChanged: (v) => setState(() => _bathrooms = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Counter(
                      label: context.tr('maxGuestsCount'),
                      value: _maxGuests,
                      onChanged: (v) => setState(() => _maxGuests = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: context.tr('areaSqm'),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: '100',
                      onChanged: (v) => _area = double.tryParse(v) ?? 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Images ──
              SectionHeader(title: context.tr('propertyImagesMin')),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._images.asMap().entries.map((e) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: AppRadius.smBr,
                          child: Image.file(
                            File(e.value.path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: InkWell(
                            onTap: () => _removeImage(e.key),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  InkWell(
                    onTap: _pickImages,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: AppRadius.smBr,
                        border: Border.all(
                          color: context.borderColor,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Icon(
                        Icons.add_a_photo_rounded,
                        color: context.textSecondary,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Rent Types & Prices ──
              SectionHeader(title: context.tr('rentTypeAndPrices')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  {'key': 'يومي', 'label': context.tr('daily')},
                  {'key': 'شهري', 'label': context.tr('monthly')},
                  {'key': 'سنوي', 'label': context.tr('yearly')},
                ].map((item) {
                  final key = item['key']!;
                  final label = item['label']!;
                  final selected = _availableRentTypes.contains(key);
                  return FilterChip(
                    label: Text(label),
                    selected: selected,
                    selectedColor: context.accentColor.withValues(alpha: 0.2),
                    checkmarkColor: context.accentColor,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _availableRentTypes.add(key);
                        } else {
                          _availableRentTypes.remove(key);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (_availableRentTypes.contains('يومي')) ...[
                TextFormField(
                  controller: _dailyPriceCtl,
                  decoration: InputDecoration(labelText: context.tr('dailyPrice')),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v != null && v.isNotEmpty ? null : context.tr('dailyPriceRequired'),
                ),
                const SizedBox(height: 12),
              ],
              if (_availableRentTypes.contains('شهري')) ...[
                TextFormField(
                  controller: _monthlyPriceCtl,
                  decoration: InputDecoration(labelText: context.tr('monthlyPrice')),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v != null && v.isNotEmpty ? null : context.tr('monthlyPriceRequired'),
                ),
                const SizedBox(height: 12),
              ],
              if (_availableRentTypes.contains('سنوي')) ...[
                TextFormField(
                  controller: _yearlyPriceCtl,
                  decoration: InputDecoration(labelText: context.tr('yearlyPrice')),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v != null && v.isNotEmpty ? null : context.tr('yearlyPriceRequired'),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _depositCtl,
                decoration: InputDecoration(labelText: context.tr('securityDeposit')),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 28),

              // ── Amenities ──
              SectionHeader(title: context.tr('amenitiesAndFacilities')),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.amenities.map((a) {
                  final selected = _selectedAmenities.contains(a);
                  return FilterChip(
                    label: Text(a),
                    selected: selected,
                    selectedColor: context.accentColor.withValues(alpha: 0.2),
                    checkmarkColor: context.accentColor,
                    backgroundColor: context.cardColor,
                    labelStyle: TextStyle(
                      color: selected
                          ? context.accentColor
                          : context.textSecondary,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.pillBr,
                      side: BorderSide(
                        color: selected
                            ? context.accentColor.withValues(alpha: 0.3)
                            : context.borderColor,
                      ),
                    ),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedAmenities.add(a);
                        } else {
                          _selectedAmenities.remove(a);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),

              // ── Submit Button ──
              Consumer<ApartmentProvider>(
                builder: (context, prov, _) => GradientButton(
                  text: context.tr('submitAddProperty'),
                  isLoading: prov.isLoading,
                  onPressed: prov.isLoading ? null : _submit,
                  icon: Icons.add_home_rounded,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _Counter({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: AppRadius.mdBr,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: context.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  '$value',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              InkWell(
                onTap: () => onChanged(value + 1),
                borderRadius: AppRadius.xsBr,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.add_rounded,
                    color: context.accentColor,
                    size: 20,
                  ),
                ),
              ),
              InkWell(
                onTap: () => onChanged(value > 1 ? value - 1 : 1),
                borderRadius: AppRadius.xsBr,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.remove_rounded,
                    color: context.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
