import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/gradient_button.dart';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_cubit.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_state.dart';
import 'package:sakani/features/apartments/presentation/cubit/wishlist_cubit.dart';
import 'package:sakani/features/apartments/presentation/widgets/apartment_card.dart';

class WishlistScreen extends StatelessWidget {
  final VoidCallback onExplore;

  const WishlistScreen({super.key, required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WishlistCubit, Set<String>>(
      builder: (context, favoriteIds) {
        return BlocBuilder<ApartmentCubit, ApartmentState>(
          builder: (context, aptState) {
            final favoriteApartments = aptState.apartments
                .where((a) => favoriteIds.contains(a.id))
                .map((e) => e is ApartmentModel ? e : ApartmentModel.fromEntity(e))
                .toList();

            if (favoriteApartments.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          size: 46,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'قائمة المفضلة فارغة',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'لم تقم بحفظ أي شقة حتى الآن. تصفح آلاف الشقق واحفظ ما يعجبك بضغطة زر!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 200,
                        child: GradientButton(
                          text: 'استكشف الشقق',
                          height: 46,
                          onPressed: onExplore,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الشقق المحفوظة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                            borderRadius: AppRadius.pillBr,
                          ),
                          child: Text(
                            '${favoriteApartments.length} شقة',
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final apt = favoriteApartments[index];
                        return ApartmentCard(
                          apartment: apt,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/apartment-detail',
                            arguments: apt,
                          ),
                        );
                      },
                      childCount: favoriteApartments.length,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
