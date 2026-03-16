import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MangaImageView extends StatelessWidget {
  final String imageUrl;
  final int readingMode;

  const MangaImageView({super.key, required this.imageUrl, required this.readingMode});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      placeholder: (context, url) => Container(height: 400, color: Colors.black, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
      errorWidget: (context, url, error) => Container(height: 200, color: Colors.grey[900], child: const Center(child: Icon(Icons.broken_image, color: Colors.white))),
      fit: readingMode == 2 ? BoxFit.fitWidth : BoxFit.contain,
    );
  }
}

