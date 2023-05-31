// YOUTUBE: Directory

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:videory/src/theme.dart';

@immutable
class Settings {
  const Settings();

  SettingsImpl copyWith({
    String? downloadPath,
    ThemeSetting? theme,
    String? ffmpegContainer,
    Locale? locale,
  }) =>
      throw UnimplementedError();

  String get ffmpegContainer => throw UnimplementedError();

  String get downloadPath => throw UnimplementedError();

  ThemeSetting get theme => throw UnimplementedError();

  Locale get locale => throw UnimplementedError();
}

@immutable
class SettingsImpl implements Settings {
  final SharedPreferences _prefs;

  @override
  final String downloadPath;

  @override
  final ThemeSetting theme;

  @override
  final String ffmpegContainer;

  @override
  final Locale locale;

  const SettingsImpl._(
    this._prefs,
    this.downloadPath,
    this.theme,
    this.ffmpegContainer,
    this.locale,
  );

  @override
  SettingsImpl copyWith({
    String? downloadPath,
    ThemeSetting? theme,
    String? ffmpegContainer,
    Locale? locale,
  }) {
    if (downloadPath != null) {
      _prefs.setString('download_path', downloadPath);
    }
    if (theme != null) {
      _prefs.setInt('theme_id', theme.id);
    }
    if (ffmpegContainer != null) {
      _prefs.setString('ffmpeg_container', ffmpegContainer);
    }
    if (locale != null) {
      _prefs.setString('locale', locale.languageCode);
    }

    return SettingsImpl._(
      _prefs,
      downloadPath ?? this.downloadPath,
      theme ?? this.theme,
      ffmpegContainer ?? this.ffmpegContainer,
      locale ?? this.locale,
    );
  }

  static Future<SettingsImpl> init({
    required SharedPreferences prefs,
    required BuildContext context,
  }) async {
    String? path = prefs.getString('download_path');
    if (path == null) {
      path = (await getDefaultDownloadDir()).path;
      prefs.setString('download_path', path);
    }
    int? themeId = prefs.getInt('theme_id');
    if (themeId == null) {
      themeId = 0;
      prefs.setInt('theme_id', 0);
    }
    String? ffmpegContainer = prefs.getString('ffmpeg_container');
    if (ffmpegContainer == null) {
      ffmpegContainer = '.mp4';
      prefs.setString('ffmpeg_container', '.mp4');
    }

    String? langCode = prefs.getString('locale');
    if (langCode == null && context.mounted) {
      // This Property is deprecated - Using View.Of()
      // final Locale defaultLang = WidgetsBinding.instance.window.locales.first;
      final defaultLang = View.of(context).platformDispatcher.locale;
      langCode = defaultLang.languageCode;
      prefs.setString('locale', defaultLang.languageCode);
    }
    return SettingsImpl._(
      prefs,
      path,
      ThemeSetting.fromId(themeId),
      ffmpegContainer,
      Locale(langCode ?? "No Locale"),
    );
  }
}

Future<Directory?> createCustomFolder() async {
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

Future<bool> requestStoragePermission() async {
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
    bool permissionGranted = await requestStoragePermission();
    if (!permissionGranted) {
      debugPrint('Storage permission denied.');
    }
    final Directory? customFolderPath = await createCustomFolder();
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



/*

DOCs:-

This Property is deprecated - Using View.Of()
final Locale defaultLang = WidgetsBinding.instance.window.locales.first; - deprecated

final defaultLang = View.of(context).platformDispatcher.locale;

[Reference]
https://docs.flutter.dev/release/breaking-changes/window-singleton

*/