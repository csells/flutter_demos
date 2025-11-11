// Copyright 2025 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../platform/platform.dart';
import '../services/image_picker_service.dart';
import '../state/app_step_state.dart';
import '../state/puzzle_data_state.dart';
import '../styles.dart';
import 'selected_images_view.dart';
import 'step_activation_mixin.dart';

class StepOneSelectImage extends StatefulWidget {
  const StepOneSelectImage({required this.isActive, super.key});

  final bool isActive;

  @override
  State<StepOneSelectImage> createState() => _StepOneSelectImageState();
}

class _StepOneSelectImageState extends State<StepOneSelectImage>
    with StepActivationMixin<StepOneSelectImage> {
  final _imagePickerService = ImagePickerService();

  @override
  bool get isActive => widget.isActive;

  @override
  void onActivated() {
    final puzzleDataState = Provider.of<PuzzleDataState>(
      context,
      listen: false,
    );
    assert(puzzleDataState.isGridClear);
  }

  @override
  Widget build(BuildContext context) {
    final puzzleDataState = Provider.of<PuzzleDataState>(context);
    final appStepState = Provider.of<AppStepState>(context);
    final areImagesSelected =
        puzzleDataState.selectedCrosswordImages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (areImagesSelected)
          SelectedImagesView(
            imagesData: puzzleDataState.selectedCrosswordImagesData,
            onRemoveImage: puzzleDataState.removeSelectedCrosswordImage,
          ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.start,
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
              onPressed: () async {
                final images = await _imagePickerService
                    .pickMultipleImagesFromGallery();
                await puzzleDataState.addSelectedCrosswordImages(images);
              },
              style: secondaryActionButtonStyle,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Photo'),
              onPressed: isMobile()
                  ? () async {
                      final image = await _imagePickerService
                          .pickImageFromCamera();
                      if (image != null) {
                        await puzzleDataState.addSelectedCrosswordImages([
                          image,
                        ]);
                      }
                    }
                  : null,
              style: secondaryActionButtonStyle,
            ),
            ElevatedButton(
              onPressed: areImagesSelected ? appStepState.nextStep : null,
              style: primaryActionButtonStyle,
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }
}
