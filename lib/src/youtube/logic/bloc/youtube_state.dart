import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:videory/src/youtube/model/single_video.dart';
import 'package:videory/src/youtube/widgets/snack_bar.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeAPI extends ChangeNotifier {
  YouTubeVideo? _youTubeVideo;
  YouTubeVideo? get youTubeVideoInfo => _youTubeVideo;
  YouTubeAPI();

  TextEditingController urlController = TextEditingController();
  double progress = 0;
  int value = 0;
  bool start = false;

  //get info function
  Future<YouTubeVideo?> getVideoInfo(String url, BuildContext context) async {
    try {
      final youtubeInfo = YoutubeExplode();
      var video = await youtubeInfo.videos.get(url);
      _youTubeVideo = YouTubeVideo(
        videoId: video.id.value,
        title: video.title,
        thumbnailUrl: video.thumbnails.standardResUrl,
        channelTitle: video.author,
        viewCount: video.engagement.viewCount,
        likeCount: video.engagement.likeCount ?? 0,
        dislikeCount: video.engagement.dislikeCount ?? 0,
        duration: video.duration.toString(),
      );
      notifyListeners();
      return _youTubeVideo;
    } catch (e) {
      Exception("Got Error $e");
      showSnackBar(context, "Got Error $e");
      debugPrint("$e");
      notifyListeners();
    }
    return null;
  }

  // Download
  Future<void> downloadVideo(String url, BuildContext context) async {
    final permissionRequest = Permission.storage.request();
    final YoutubeExplode youtubeExplode = YoutubeExplode();

    try {
      final List<dynamic> results = await Future.wait(
          [permissionRequest, youtubeExplode.videos.get(url)]);
      final permission = results[0];
      final video = results[1];

      if (permission.isGranted) {
        final manifest =
            await youtubeExplode.videos.streamsClient.getManifest(url);
        final streams = value > 0
            ? manifest.audio.withHighestBitrate()
            : manifest.muxed.withHighestBitrate();
        final audio = streams;
        final audioStream = youtubeExplode.videos.streamsClient.get(audio);

        Directory? directory = await getExternalStorageDirectory();
        String appDocPath = '';
        final folders = directory!.path.split('/');
        for (int x = 1; x < folders.length; x++) {
          final folder = folders[x];
          if (folder != 'Android') {
            appDocPath += '/$folder';
          } else {
            break;
          }
        }

        final sourcePath = value > 0 ? 'Audio' : 'Video';
        final homePath = '$appDocPath/Videory/YouTube';
        appDocPath = path.join(homePath, sourcePath);

        directory = Directory(homePath);
        final directory1 = Directory(appDocPath);
        if (!await directory.exists()) {
          directory.create();
          directory1.create();
          if (context.mounted) {
            showSnackBar(context, 'Folder Created');
          }
        } else {
          if (!await directory1.exists()) {
            directory1.create();
          }
        }

        final extensions = value > 0 ? 'mp3' : 'mp4';
        final filePath = path.join(appDocPath, '${video.title}.$extensions');
        final file = File(filePath);

        if (file.existsSync()) {
          file.delete(recursive: true);
          if (context.mounted) {
            showSnackBar(context, 'File Already Exists');
          }
        }

        final output = file.openWrite(mode: FileMode.writeOnlyAppend);
        final size = audio.size.totalBytes;
        int count = 0;

        await for (final data in audioStream) {
          count += data.length;
          final double val = count / size;
          progress = val;

          output.add(data);
        }

        start = false;
        notifyListeners();
      } else {
        await Permission.storage.request();
        notifyListeners();
      }
    } catch (e) {
      Exception(e);
      debugPrint("$e");
      if (context.mounted) {
        showSnackBar(context, "Got Error $e");
      }
    } finally {
      youtubeExplode.close();
    }
  }
}
