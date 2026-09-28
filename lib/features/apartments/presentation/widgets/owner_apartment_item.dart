import 'package:flutter/material.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/features/apartments/domain/entities/apartment_entity.dart';

class OwnerApartmentItem extends StatelessWidget {
  final ApartmentEntity apartment;
  final ValueChanged<bool> onToggleAvailability;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const OwnerApartmentItem({
    super.key,
    required this.apartment,
    required this.onToggleAvailability,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: AppRadius.mdBr,
        border: Border.all(color: context.borderColor),
        boxShadow: AppShadows.card(context),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdBr,
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
                    borderRadius: AppRadius.smBr,
                    child: Container(
                      width: 80,
                      height: 80,
                      color: context.surfaceColor,
                      child: apartment.images.isNotEmpty
                          ? Image.network(
                              apartment.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.home_work_rounded,
                                color: context.textSecondary,
                              ),
                            )
                          : Icon(
                              Icons.home_work_rounded,
                              color: context.textSecondary,
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
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: context.accentColor),
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
                        Text(
                          '${apartment.monthlyPrice.round()} ج.م / شهري',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: context.accentColor,
                          ),
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
                  Row(
                    children: [
                      Switch.adaptive(
                        value: apartment.isAvailable,
                        activeThumbColor: AppColors.success,
                        onChanged: onToggleAvailability,
                      ),
                      Text(
                        apartment.isAvailable ? 'متاح للحجز' : 'غير متاح',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: apartment.isAvailable ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        tooltip: 'حذف',
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
    );
  }
}
