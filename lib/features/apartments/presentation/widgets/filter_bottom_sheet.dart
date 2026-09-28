import 'package:flutter/material.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/gradient_button.dart';
import 'package:sakani/features/apartments/presentation/models/apartment_filter_options.dart';

class FilterBottomSheet extends StatefulWidget {
  final ApartmentFilterOptions initialOptions;
  final ValueChanged<ApartmentFilterOptions> onApply;
  final VoidCallback onReset;
  final int matchingCount;

  const FilterBottomSheet({
    super.key,
    required this.initialOptions,
    required this.onApply,
    required this.onReset,
    required this.matchingCount,
  });

  static Future<void> show({
    required BuildContext context,
    required ApartmentFilterOptions initialOptions,
    required ValueChanged<ApartmentFilterOptions> onApply,
    required VoidCallback onReset,
    required int matchingCount,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        initialOptions: initialOptions,
        onApply: onApply,
        onReset: onReset,
        matchingCount: matchingCount,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RangeValues _priceRange;
  late String _rentType;
  late int _minBedrooms;
  late List<String> _selectedAmenities;

  static const List<String> _allAmenities = [
    'واي فاي',
    'تكييف',
    'موقف سيارات',
    'مطبخ',
    'غسالة',
    'تلفزيون',
    'مسبح',
    'صالة رياضية',
    'مصعد',
    'أمن',
  ];

  static const List<String> _rentTypes = [
    'الكل',
    'يومي',
    'شهري',
    'سنوي',
  ];

  @override
  void initState() {
    super.initState();
    _priceRange = RangeValues(
      widget.initialOptions.minPrice.clamp(0, 25000),
      widget.initialOptions.maxPrice.clamp(0, 25000),
    );
    _rentType = widget.initialOptions.rentType;
    _minBedrooms = widget.initialOptions.minBedrooms;
    _selectedAmenities = List.from(widget.initialOptions.amenities);
  }

  void _apply() {
    final updated = widget.initialOptions.copyWith(
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end,
      rentType: _rentType,
      minBedrooms: _minBedrooms,
      amenities: _selectedAmenities,
    );
    widget.onApply(updated);
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _priceRange = const RangeValues(0, 25000);
      _rentType = 'الكل';
      _minBedrooms = 0;
      _selectedAmenities.clear();
    });
    widget.onReset();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: Column(
        children: [
          // ── Drag Handle & Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: context.borderColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تصفية وفلترة الشقق',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: _reset,
                      child: Text(
                        'إعادة ضبط',
                        style: TextStyle(
                          color: context.accentColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Scrollable Filter Options ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Price Range Section
                  _buildSectionTitle('نطاق السعر الشهري'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_priceRange.start.round()} ج.م',
                        style: TextStyle(
                          color: context.accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${_priceRange.end.round()} ج.م',
                        style: TextStyle(
                          color: context.accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 25000,
                    divisions: 50,
                    activeColor: context.accentColor,
                    inactiveColor: context.borderColor,
                    onChanged: (vals) => setState(() => _priceRange = vals),
                  ),
                  const SizedBox(height: 18),

                  // 2. Rental Type Section
                  _buildSectionTitle('نوع الإيجار'),
                  Wrap(
                    spacing: 8,
                    children: _rentTypes.map((type) {
                      final isSelected = _rentType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _rentType = type);
                        },
                        selectedColor: context.accentColor.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? context.accentColor : context.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: isSelected ? context.accentColor : context.borderColor,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // 3. Minimum Bedrooms Section
                  _buildSectionTitle('الحد الأدنى لعدد الغرف'),
                  Wrap(
                    spacing: 8,
                    children: [
                      {'label': 'الكل', 'val': 0},
                      {'label': '1+ غرفة', 'val': 1},
                      {'label': '2+ غرف', 'val': 2},
                      {'label': '3+ غرف', 'val': 3},
                      {'label': '4+ فأكثر', 'val': 4},
                    ].map((item) {
                      final val = item['val'] as int;
                      final isSelected = _minBedrooms == val;
                      return ChoiceChip(
                        label: Text(item['label'] as String),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _minBedrooms = val);
                        },
                        selectedColor: context.accentColor.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? context.accentColor : context.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: isSelected ? context.accentColor : context.borderColor,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // 4. Amenities Section
                  _buildSectionTitle('الخدمات والمرافق المتوفرة'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allAmenities.map((amenity) {
                      final isSelected = _selectedAmenities.contains(amenity);
                      return FilterChip(
                        label: Text(amenity),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedAmenities.add(amenity);
                            } else {
                              _selectedAmenities.remove(amenity);
                            }
                          });
                        },
                        selectedColor: context.accentColor.withValues(alpha: 0.15),
                        checkmarkColor: context.accentColor,
                        labelStyle: TextStyle(
                          color: isSelected ? context.accentColor : context.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: isSelected ? context.accentColor : context.borderColor,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Bottom Sticky Action ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: context.cardColor,
              border: Border(top: BorderSide(color: context.borderColor)),
            ),
            child: GradientButton(
              text: 'تطبيق الفلترة (${widget.matchingCount} شقة مطابقة)',
              height: 48,
              onPressed: _apply,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: context.textPrimary,
        ),
      ),
    );
  }
}
