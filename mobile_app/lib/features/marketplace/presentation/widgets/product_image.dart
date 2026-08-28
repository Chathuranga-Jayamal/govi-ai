import 'package:flutter/material.dart';

/// Renders a product's photo when [imageUrl] is set, with a loading
/// spinner while it fetches and a placeholder icon (over [backgroundColor])
/// when there's no URL at all or the image fails to load. Fills whatever
/// box the caller sizes it into.
class ProductImage extends StatelessWidget {
  const ProductImage({
    required this.imageUrl,
    required this.backgroundColor,
    required this.iconColor,
    this.borderRadius = 12,
    this.iconSize = 32,
    super.key,
  });

  final String? imageUrl;
  final Color backgroundColor;
  final Color iconColor;
  final double borderRadius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final String? url = imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        color: backgroundColor,
        alignment: Alignment.center,
        child: url == null
            ? Icon(Icons.image_outlined, color: iconColor, size: iconSize)
            : Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: iconSize * 0.6,
                      height: iconSize * 0.6,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.broken_image_outlined,
                  color: iconColor,
                  size: iconSize,
                ),
              ),
      ),
    );
  }
}
