import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pbn/core/constants/api_config.dart';
import 'package:pbn/core/constants/app_colors.dart';

/// A reusable, cached network avatar widget.
///
/// Shows initials as the placeholder (instead of a spinner) so the user
/// never sees a blank loading circle when images are already cached.
/// Images are cached to disk via [CachedNetworkImage] and served
/// instantly on repeat views.
class CachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const CachedAvatar({
    super.key,
    required this.imageUrl,
    required this.initials,
    this.size = 70,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  });

  String get _fullUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return '';
    if (imageUrl!.startsWith('http')) return imageUrl!;
    return '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? const Color(0xFF1E3A8A).withOpacity(0.1);
    final fgColor = textColor ?? const Color(0xFF1E3A8A);
    final fSize = fontSize ?? (size * 0.32);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade100, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: _fullUrl.isEmpty
            ? _initialsWidget(bgColor, fgColor, fSize)
            : CachedNetworkImage(
                imageUrl: _fullUrl,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                // Use initials as placeholder so there's no spinner flash
                placeholder: (context, url) => _initialsWidget(bgColor, fgColor, fSize),
                errorWidget: (context, url, error) => _initialsWidget(bgColor, fgColor, fSize),
                memCacheWidth: (size * 2).toInt(), // limit memory cache size
              ),
      ),
    );
  }

  Widget _initialsWidget(Color bg, Color fg, double fs) {
    return Container(
      color: bg,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(fontWeight: FontWeight.w900, color: fg, fontSize: fs),
        ),
      ),
    );
  }
}
