import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:videory/src/youtube/logic/settings.dart';
import 'package:videory/src/youtube/model/video_model.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path/path.dart' as path;

class DataProvider extends ChangeNotifier {
  TextEditingController urlController = TextEditingController();
  String videoID = '';
  String videoTitle = '';
  double progress = 0;
  int value = 0;
  bool start = false;

  //get info function
  Future<void> getVideoInfo(String url) async {
    try {
      YoutubeExplode youtubeInfo = YoutubeExplode();
      Video video = await youtubeInfo.videos.get(url);

      QueryVideo queryVideo = QueryVideo(
        id: video.id.toString(),
        title: video.title,
        thumbnailUrl: video.thumbnails.highResUrl,
        channelTitle: video.author,
        duration: video.duration ?? const Duration(),
      );
      debugPrint(queryVideo.toString());
      // videoID = video.id.toString();
      // videoTitle = video.title;
      notifyListeners();
    } catch (error) {
      debugPrint("Error Found: $error");
      // videoID = '';
      // videoTitle = '';
      notifyListeners();
    }
  }

  //download function
  // Future<void> downloadVideo(String url) async {
  //   var permission = await Permission.storage.request();
  //   if (permission.isGranted) {
  //     progress = 0;
  //     start = true;
  //     notifyListeners();
  //     YoutubeExplode youtubeExplode = YoutubeExplode();
  //     //get meta data video
  //     Video video = await youtubeExplode.videos.get(url);
  //     StreamManifest manifest =
  //         await youtubeExplode.videos.streamsClient.getManifest(url);
  //     AudioStreamInfo streams = value > 0
  //         ? manifest.audio.withHighestBitrate()
  //         : manifest.muxed.withHighestBitrate();
  //     AudioStreamInfo audio = streams;
  //     Stream<List<int>> audioStream =
  //         youtubeExplode.videos.streamsClient.get(audio);
  //     //create a directory
  //     Directory? directory = await getExternalStorageDirectory();
  //     // String appDocPath = "";
  //     List<String> folders = directory!.path.split('/');
  //     String appDocPath = folders.sublist(1, folders.indexOf('Android')).join('/');
  //     // for (int x = 1; x < folders.length; x++) {
  //     //   String folder = folders[x];
  //     //   if (folder != "Android") {
  //     //     appDocPath += "/$folder";
  //     //   } else {
  //     //     break;
  //     //   }
  //     // }
  //     String scPath = value > 0 ? 'Audio' : 'Video';
  //     String homePath = '$appDocPath/Videory/YouTube';
  //     appDocPath = homePath + scPath;

  //     directory = Directory(homePath);
  //     Directory directory1 = Directory(appDocPath);
  //     if (!await directory.exists()) {
  //       directory.create();
  //       directory1.create();
  //     } else {
  //       if (!await directory1.exists()) {
  //         directory1.create();
  //       }
  //     }

  //     // String appDocPath = appDocDir.path;
  //     String extensions = value > 0 ? 'mp3' : 'mp4';
  //     final File file = File('$appDocPath/${video.title}.$extensions');
  //     //delete file if exists
  //     if (file.existsSync()) {
  //       file.deleteSync();
  //     }
  //     IOSink output = file.openWrite(mode: FileMode.writeOnlyAppend);
  //     int size = audio.size.totalBytes;
  //     int count = 0;

  //     await for (final data in audioStream) {
  //       // Keep track of the current downloaded data.
  //       count += data.length;
  //       // Calculate the current progress.
  //       double val = ((count / size));
  //       // var msg = '${video.title} Downloaded to $appDocPath/${video.id}';
  //       // for (val; val == 1.0; val++) {
  //       //   // ScaffoldMessenger.of(context)
  //       //   //     .showSnackBar(SnackBar(content: Text(msg)));
  //       // }
  //       progress = val;
  //       notifyListeners();

  //       // Write to file.
  //       output.add(data);
  //     }

  //     start = false;
  //     notifyListeners();
  //   } else {
  //     await Permission.storage.request();
  //   }
  // }

  // download Function

  Future<void> downloadVideo(String url) async {
    final permission = await Permission.storage.request();
    if (permission.isGranted) {
      final youtubeExplode = YoutubeExplode();
      final video = await youtubeExplode.videos.get(url);
      final manifest =
          await youtubeExplode.videos.streamsClient.getManifest(url);
      final streams = value > 0
          ? manifest.audio.withHighestBitrate()
          : manifest.muxed.withHighestBitrate();
      final audio = streams;
      final audioStream = youtubeExplode.videos.streamsClient.get(audio);

      // creating directory
      Directory? directory = await getExternalStorageDirectory();
      final List<String> folders = directory!.path.split('/');
      String appDocPath =
          path.joinAll(folders.sublist(1, folders.indexOf('Android')));
      final String scPath = value > 0 ? 'Audio' : 'Video';
      final String homePath = path.join(appDocPath, 'Videory/YouTube');
      appDocPath = path.join(homePath, scPath);

      directory = Directory(homePath);
      final Directory directory1 = Directory(appDocPath);
      if (!await directory.exists()) {
        await directory.create();
      }
      if (!await directory1.exists()) {
        await directory1.create();
      }

      final extensions = value > 0 ? 'mp3' : 'mp4';
      final file = File(path.join(appDocPath, '${video.title}.$extensions'));
      if (file.existsSync()) {
        file.deleteSync();
      }
      final output = file.openWrite(mode: FileMode.writeOnlyAppend);

      final size = audio.size.totalBytes;
      // const chunkSize = 1024 * 1024; // 1 MB
      int count = 0;
      double progress = 0;

      await for (final data in audioStream) {
        count += data.length;
        final newProgress = count / size;
        if (newProgress - progress >= 0.01) {
          progress = newProgress;
          notifyListeners();
        }
        output.add(data);
      }

      output.close();
      youtubeExplode.close();
      start = false;
      notifyListeners();
    } else {
      await Permission.storage.request();
    }
  }
}
