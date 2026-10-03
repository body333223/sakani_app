import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/features/apartments/domain/entities/apartment_entity.dart';

class OwnerApartmentItem extends StatelessWidget {
  final ApartmentEntity apartment;
  final ValueChanged<bool> onToggleAvailability;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<double>? onUpdatePrice;

  const OwnerApartmentItem({
    super.key,
    required this.apartment,
    required this.onToggleAvailability,
    required this.onTap,
    required this.onDelete,
    this.onUpdatePrice,
  });

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  void _showPriceEditDialog(BuildContext context) {
    final controller = TextEditingController(text: apartment.monthlyPrice.round().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.edit_note_rounded, color: context.accentColor),
            const SizedBox(width: 8),
            const Text(
              'تعديل سعر الإيجار',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أدخل السعر الشهري الجديد لعقار: "${apartment.title}"',
              style: TextStyle(fontSize: 13, color: context.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'السعر الشهري (ج.م)',
                prefixIcon: const Icon(Icons.attach_money_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.accentColor,
              foregroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null && newPrice > 0) {
                Navigator.pop(ctx);
                onUpdatePrice?.call(newPrice);
              }
            },
            child: const Text('حفظ السعر', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isOccupied = apartment.isCurrentlyOccupied;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOccupied
              ? Colors.amber.withValues(alpha: 0.4)
              : (isDark ? Colors.white.withValues(alpha: 0.08) : context.borderColor),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Occupancy Period Banner ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isOccupied
                  ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                  : AppColors.success.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: isOccupied
                      ? const Color(0xFFEF4444).withValues(alpha: 0.25)
                      : AppColors.success.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isOccupied ? Icons.lock_clock_rounded : Icons.check_circle_rounded,
                      size: 16,
                      color: isOccupied ? const Color(0xFFEF4444) : AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOccupied
                          ? 'مشغول من ${_formatDate(apartment.occupiedFrom!)} حتى ${_formatDate(apartment.occupiedUntil!)}'
                          : 'متاح للحجز الفوري والتأجير',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isOccupied ? const Color(0xFFEF4444) : AppColors.success,
                      ),
                    ),
                  ],
                ),
                if (isOccupied && apartment.occupiedUntil != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'متبقي ${apartment.occupiedUntil!.difference(DateTime.now()).inDays.clamp(0, 999)} يوم',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 86,
                          height: 86,
                          color: context.surfaceColor,
                          child: apartment.images.isNotEmpty
                              ? Image.network(
                                  apartment.images.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Icon(
                                    Icons.home_work_rounded,
                                    color: context.textSecondary,
                                    size: 32,
                                  ),
                                )
                              : Icon(
                                  Icons.home_work_rounded,
                                  color: context.textSecondary,
                                  size: 32,
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              apartment.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: context.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, size: 14, color: context.accentColor),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${apartment.city} - ${apartment.address}',
                                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${apartment.monthlyPrice.round()}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: context.accentColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'ج.م / شهري',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Availability Toggle
                      Row(
                        children: [
                          Switch.adaptive(
                            value: apartment.isAvailable,
                            activeTrackColor: AppColors.success.withValues(alpha: 0.5),
                            activeThumbColor: AppColors.success,
                            onChanged: onToggleAvailability,
                          ),
                          Text(
                            apartment.isAvailable ? 'متاح' : 'غير متاح',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: apartment.isAvailable ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),

                      // Quick Price Edit & Delete
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _showPriceEditDialog(context),
                            icon: Icon(Icons.edit_note_rounded, size: 18, color: context.accentColor),
                            label: Text(
                              'تعديل السعر',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: context.accentColor,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              backgroundColor: context.accentColor.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                            tooltip: 'حذف العقار',
                            onPressed: onDelete,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
