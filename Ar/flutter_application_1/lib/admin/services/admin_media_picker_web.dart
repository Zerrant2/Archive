import 'dart:async';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
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
  static Future<AdminPickedFile?> pickFile({String? accept}) {
    final completer = Completer<AdminPickedFile?>();
    final input = html.FileUploadInputElement()
      ..accept = accept ?? ''
      ..multiple = false;

    input.onChange.first.then((_) {
      final files = input.files;
      final file = files == null || files.isEmpty ? null : files.first;
      if (file == null) {
        completer.complete(null);
        return;
      }

      final reader = html.FileReader();
      reader.onError.first.then((_) {
        if (!completer.isCompleted) {
          completer.completeError('Не удалось прочитать файл.');
        }
      });
      reader.onLoad.first.then((_) {
        final result = reader.result;
        if (result is ByteBuffer) {
          completer.complete(
            AdminPickedFile(
              name: file.name,
              bytes: Uint8List.view(result),
              mimeType: file.type,
            ),
          );
          return;
        }

        if (result is Uint8List) {
          completer.complete(
            AdminPickedFile(
              name: file.name,
              bytes: result,
              mimeType: file.type,
            ),
          );
          return;
        }

        completer.completeError('Формат файла не удалось распознать.');
      });
      reader.readAsArrayBuffer(file);
    });

    input.click();
    return completer.future;
  }

  static Future<AdminPickedFile?> pickImage() {
    return pickFile(accept: 'image/jpeg,image/png,image/webp');
  }
}
