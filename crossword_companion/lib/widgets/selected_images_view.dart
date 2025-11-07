import 'dart:typed_data';

import 'package:flutter/material.dart';

class SelectedImagesView extends StatelessWidget {
  const SelectedImagesView({
    required this.imagesData,
    super.key,
    this.onRemoveImage,
  });
  final List<Uint8List> imagesData;
  final Function(int)? onRemoveImage;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 500,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: imagesData.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Stack(
          children: [
            Image.memory(imagesData[index], fit: BoxFit.contain),
            if (onRemoveImage != null)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  onPressed: () => onRemoveImage!(index),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
