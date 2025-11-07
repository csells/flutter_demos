import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  ImagePickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  Future<XFile?> pickImageFromGallery() async =>
      _picker.pickImage(source: ImageSource.gallery);

  Future<XFile?> pickImageFromCamera() async =>
      _picker.pickImage(source: ImageSource.camera);

  Future<List<XFile>> pickMultipleImagesFromGallery() async =>
      _picker.pickMultiImage();
}
