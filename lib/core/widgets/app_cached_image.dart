import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sakani/core/config/theme.dart';

/// A robust image loader with offline caching and bundled asset fallback.
/// If internet is unavailable or image fails to load, it falls back to
/// internal bundled high-resolution apartment assets.
class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? fallbackAsset;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackAsset,
  });

  static const List<String> defaultFallbackAssets = [
    'assets/images/apt_1.jpg',
    'assets/images/apt_2.jpg',
  ];

  String _getFallbackAsset() {
    if (fallbackAsset != null && fallbackAsset!.isNotEmpty) {
      return fallbackAsset!;
    }
    final hash = imageUrl.hashCode.abs();
    return defaultFallbackAssets[hash % defaultFallbackAssets.length];
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (imageUrl.isEmpty) {
      imageWidget = _buildAssetFallback();
    } else if (imageUrl.startsWith('assets/')) {
      imageWidget = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: 600,
        errorBuilder: (_, _, _) => _buildAssetFallback(),
      );
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: 600,
        memCacheHeight: 450,
        maxWidthDiskCache: 1000,
        maxHeightDiskCache: 750,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => _buildShimmer(context),
        errorWidget: (context, url, error) => _buildAssetFallback(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildAssetFallback() {
    return Image.asset(
      _getFallbackAsset(),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: const Color(0xFF1E293B),
        child: Center(
          child: Icon(
            Icons.apartment_rounded,
            color: Colors.white.withValues(alpha: 0.3),
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final isDark = context.isDark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
      child: Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        color: Colors.white,
      ),
    );
  }
}
