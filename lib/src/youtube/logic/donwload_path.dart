import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, immutable;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

@immutable
class DownloadPath {
  Future<Directory?> _createCustomFolder() async {
    try {
      // Get the root directory
      Directory root = Directory('/');
      final String customFolder = '${root.path}/Videory/YouTube';
      // Create a subdirectory within the root directory
      // Directory customFolder = Directory('${root.path}/Videory/YouTube');
      Directory customPath = Directory(customFolder);
      debugPrint("Custom Folder Path${customPath.path}");
      if (!customPath.existsSync()) {
        // Create the directory if it doesn't exist
        await customPath.create(recursive: true);
      }
      debugPrint(customPath.path);
      // Return the path of the custom folder
      return customPath;
    } catch (e) {
      debugPrint('Error creating custom folder: $e');
      return null;
    }
  }

  Future<bool> _requestStoragePermission() async {
    try {
      // Request storage permission using platform-specific code
      if (Platform.isAndroid || Platform.isIOS) {
        var status = await Permission.storage.request();
        return status.isGranted;
      } else if (Platform.isIOS) {
        var status = await Permission.storage.request();
        return status.isGranted;
      } else {
        debugPrint('UnSupported Platform.');
        // Unsupported platform
        return false;
      }
    } catch (e) {
      debugPrint('Error requesting storage permission: $e');
      return false;
    }
  }

  Future<Directory> getDefaultDownloadDir() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // final paths =
      //     await getExternalStorageDirectories(type: StorageDirectory.music);
      // return paths!.first;
      bool permissionGranted = await _requestStoragePermission();
      if (!permissionGranted) {
        debugPrint('Storage permission denied.');
      }
      final Directory? customFolderPath = await _createCustomFolder();
      if (customFolderPath == null) {
        debugPrint("Failed to Create Folder...");
      } else {
        return customFolderPath;
      }
    }
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      final path = await getDownloadsDirectory();
      debugPrint(path?.path ?? "No Path");
      return path!;
    }
    throw UnsupportedError(
        'Platform: ${Platform.operatingSystem} is not supported!');
  }
}
