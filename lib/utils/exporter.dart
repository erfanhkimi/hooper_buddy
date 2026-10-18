import 'dart:typed_data';
import 'export_stub.dart' if (dart.library.html) 'export_web.dart';

void saveWebImage(Uint8List bytes, String filename) {
  downloadWebImage(bytes, filename);
}