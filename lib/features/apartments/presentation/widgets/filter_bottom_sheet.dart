import 'package:flutter/material.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/staggered_entrance.dart';
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
      barrierColor: Colors.black.withValues(alpha: 0.65),
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

  static const List<Map<String, dynamic>> _amenitiesData = [
    {'name': 'واي فاي', 'icon': Icons.wifi_rounded},
    {'name': 'تكييف', 'icon': Icons.ac_unit_rounded},
    {'name': 'موقف سيارات', 'icon': Icons.directions_car_filled_rounded},
    {'name': 'مطبخ', 'icon': Icons.kitchen_rounded},
    {'name': 'غسالة', 'icon': Icons.local_laundry_service_rounded},
    {'name': 'تلفزيون', 'icon': Icons.tv_rounded},
    {'name': 'مسبح', 'icon': Icons.pool_rounded},
    {'name': 'صالة رياضية', 'icon': Icons.fitness_center_rounded},
    {'name': 'مصعد', 'icon': Icons.elevator_rounded},
    {'name': 'أمن', 'icon': Icons.security_rounded},
  ];

  static const List<Map<String, dynamic>> _rentTypesData = [
    {'type': 'الكل', 'label': 'الكل', 'desc': 'جميع الخيارات', 'icon': Icons.all_inclusive_rounded},
    {'type': 'يومي', 'label': 'يومي', 'desc': 'إيجار سياحي', 'icon': Icons.wb_sunny_rounded},
    {'type': 'شهري', 'label': 'شهري', 'desc': 'الأكثر طلباً', 'icon': Icons.calendar_month_rounded},
    {'type': 'سنوي', 'label': 'سنوي', 'desc': 'عقود مستقرة', 'icon': Icons.event_available_rounded},
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

  int get _activeCount {
    int c = 0;
    if (_priceRange.start > 0 || _priceRange.end < 25000) c++;
    if (_rentType != 'الكل') c++;
    if (_minBedrooms > 0) c++;
    c += _selectedAmenities.length;
    return c;
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
    final isDark = context.isDark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? context.accentColor.withValues(alpha: 0.3)
                : context.borderColor,
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Drag Handle & Modern Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Icon Badge
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.accentColor.withValues(alpha: 0.25),
                            context.accentColor.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: context.accentColor.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: context.accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'تصفية وبحث متقدم',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimary,
                                ),
                              ),
                              if (_activeCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: context.accentColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$_activeCount مفعل',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'خصص خيارات البحث للوصول للشقة المثالية',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Reset Button
                    BouncingTap(
                      onTap: _reset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.borderColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: 14,
                              color: context.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'إعادة ضبط',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: context.borderColor.withValues(alpha: 0.6)),

          // ── Scrollable Body ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Price Range ──
                  _buildSectionHeader(
                    icon: Icons.monetization_on_rounded,
                    title: 'نطاق السعر الشهري',
                    hint: 'بالجنيه المصري',
                  ),
                  const SizedBox(height: 12),

                  // Quick Price Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPricePresetChip('الكل', 0, 25000),
                      _buildPricePresetChip('أقل من 5,000', 0, 5000),
                      _buildPricePresetChip('5,000 - 12,000', 5000, 12000),
                      _buildPricePresetChip('فاخر 12,000+', 12000, 25000),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Dual Price Visual Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildPriceBox(
                          label: 'الحد الأدنى',
                          amount: '${_priceRange.start.round()}',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: context.accentColor,
                          size: 18,
                        ),
                      ),
                      Expanded(
                        child: _buildPriceBox(
                          label: 'الحد الأقصى',
                          amount: '${_priceRange.end.round()}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: context.accentColor,
                      inactiveTrackColor: context.borderColor,
                      thumbColor: context.accentColor,
                      overlayColor: context.accentColor.withValues(alpha: 0.2),
                      trackHeight: 4,
                      rangeThumbShape: const RoundRangeSliderThumbShape(
                        enabledThumbRadius: 10,
                        elevation: 4,
                      ),
                    ),
                    child: RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 25000,
                      divisions: 50,
                      onChanged: (vals) => setState(() => _priceRange = vals),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── 2. Rental Type ──
                  _buildSectionHeader(
                    icon: Icons.calendar_month_rounded,
                    title: 'نوع الإيجار المطلوب',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: _rentTypesData.map((data) {
                      final type = data['type'] as String;
                      final label = data['label'] as String;
                      final desc = data['desc'] as String;
                      final icon = data['icon'] as IconData;
                      final isSelected = _rentType == type;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: BouncingTap(
                            scaleFactor: 0.95,
                            onTap: () => setState(() => _rentType = type),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          context.accentColor.withValues(alpha: 0.25),
                                          context.accentColor.withValues(alpha: 0.08),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      )
                                    : null,
                                color: isSelected ? null : context.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? context.accentColor
                                      : context.borderColor,
                                  width: isSelected ? 1.6 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: context.accentColor.withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    icon,
                                    size: 22,
                                    color: isSelected
                                        ? context.accentColor
                                        : context.textSecondary,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? context.accentColor
                                          : context.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    desc,
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 9,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // ── 3. Minimum Bedrooms ──
                  _buildSectionHeader(
                    icon: Icons.king_bed_rounded,
                    title: 'الحد الأدنى لعدد الغرف',
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        {'label': 'الكل', 'val': 0},
                        {'label': '1 غرفة', 'val': 1},
                        {'label': '2 غرف', 'val': 2},
                        {'label': '3 غرف', 'val': 3},
                        {'label': '4+ غرف', 'val': 4},
                      ].map((item) {
                        final val = item['val'] as int;
                        final label = item['label'] as String;
                        final isSelected = _minBedrooms == val;

                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: BouncingTap(
                            scaleFactor: 0.94,
                            onTap: () => setState(() => _minBedrooms = val),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? context.accentColor
                                    : context.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? context.accentColor
                                      : context.borderColor,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: context.accentColor.withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (val > 0) ...[
                                    Icon(
                                      Icons.bed_rounded,
                                      size: 16,
                                      color: isSelected ? Colors.black : context.accentColor,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : context.textPrimary,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── 4. Amenities Grid ──
                  _buildSectionHeader(
                    icon: Icons.auto_awesome_rounded,
                    title: 'الخدمات والمرافق المتوفرة',
                    hint: '${_selectedAmenities.length} محددة',
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _amenitiesData.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.8,
                    ),
                    itemBuilder: (context, index) {
                      final item = _amenitiesData[index];
                      final name = item['name'] as String;
                      final icon = item['icon'] as IconData;
                      final isSelected = _selectedAmenities.contains(name);

                      return BouncingTap(
                        scaleFactor: 0.95,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedAmenities.remove(name);
                            } else {
                              _selectedAmenities.add(name);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      context.accentColor.withValues(alpha: 0.22),
                                      context.accentColor.withValues(alpha: 0.08),
                                    ],
                                  )
                                : null,
                            color: isSelected ? null : context.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? context.accentColor
                                  : context.borderColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: context.accentColor.withValues(alpha: 0.18),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? context.accentColor
                                      : context.accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  icon,
                                  size: 16,
                                  color: isSelected ? Colors.black : context.accentColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? context.accentColor
                                        : context.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: context.accentColor,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── Bottom Sticky Action ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: Border(top: BorderSide(color: context.borderColor)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: BouncingTap(
                    scaleFactor: 0.97,
                    onTap: _apply,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.accentColor,
                            AppColors.goldDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: context.accentColor.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            color: Colors.black,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.matchingCount > 0
                                ? 'عرض النتائج (${widget.matchingCount} شقة)'
                                : 'تطبيق الفلترة',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? hint,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        if (hint != null) ...[
          const Spacer(),
          Text(
            hint,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPricePresetChip(String label, double min, double max) {
    final isSelected = (_priceRange.start - min).abs() < 100 &&
        (_priceRange.end - max).abs() < 100;

    return BouncingTap(
      scaleFactor: 0.95,
      onTap: () {
        setState(() {
          _priceRange = RangeValues(min, max);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? context.accentColor.withValues(alpha: 0.18)
              : context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? context.accentColor : context.borderColor,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? context.accentColor : context.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceBox({required String label, required String amount}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: context.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: context.accentColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'ج.م',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
