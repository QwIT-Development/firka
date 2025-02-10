import 'dart:io';

import 'package:firka/main.dart';
import 'package:image/image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> pickProfilePicture(
    AppInitialization data, ImagePicker picker) async {
  var imageFile = await picker.pickImage(source: ImageSource.gallery);
  if (imageFile == null) return;

  var image = await decodeImageFile(imageFile.path);
  var resized = copyResize(image!, width: 128, maintainAspect: true);

  var dataDir = await getApplicationDocumentsDirectory();
  var bytes = encodePng(resized);
  await File(p.join(dataDir.path, "profile.png")).writeAsBytes(bytes);

  data.profilePicture = bytes;
}
