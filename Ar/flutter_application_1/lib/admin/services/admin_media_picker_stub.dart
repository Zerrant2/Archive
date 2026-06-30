import 'dart:typed_data';

class AdminPickedFile {
  final String name;
  final Uint8List bytes;
  final String? mimeType;

  const AdminPickedFile({
    required this.name,
    required this.bytes,
    this.mimeType,
  });
}

class AdminMediaPicker {
  static Future<AdminPickedFile?> pickFile({String? accept}) async {
    return null;
  }

  static Future<AdminPickedFile?> pickImage() async {
    return pickFile(accept: 'image/jpeg,image/png,image/webp');
  }
}
