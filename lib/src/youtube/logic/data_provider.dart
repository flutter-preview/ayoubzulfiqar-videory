import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:videory/src/youtube/model/single_video.dart';
import 'package:videory/src/youtube/widgets/snack_bar.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// @immutable
class VideoDownloader extends ChangeNotifier {
  YouTubeVideo? youTube;
  Future<YouTubeVideo?> getYouTubeVideoInfo(
    String url,
    BuildContext context,
  ) async {
    final YoutubeExplode yt = YoutubeExplode();

    try {
      final video = await yt.videos.get(url);

      youTube = YouTubeVideo(
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
      debugPrint(video.toString());
      return youTube;
    } catch (e) {
      notifyListeners();
      debugPrint('Error fetching YouTube video information: $e');
      showSnackBar(context, "Error fetching YouTube Video Information");
      rethrow;
    } finally {
      notifyListeners();
      yt.close();
    }
  }

  Future<void> requestAndDownload(String videoUrl, BuildContext context) async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      final directory = await getExternalStorageDirectory();
      final folderPath = '${directory!.path}/Videory/YouTube';

      final folder = Directory(folderPath);
      if (!(await folder.exists())) {
        await folder.create(recursive: true);
      }

      if (context.mounted) {
        await downloadYouTubeVideo(folderPath, videoUrl, context);
      }
      notifyListeners();
    } else {
      if (status.isDenied) {
        await openAppSettings();
      }
      notifyListeners();
      if (context.mounted) {
        showSnackBar(context, "Storage Permission Error");
      }
      throw Exception('Storage permission denied');
    }
  }

  Future<void> downloadYouTubeVideo(
      String savePath, String videoUrl, BuildContext context) async {
    final yt = YoutubeExplode();

    // Validate the video URL
    if (!isYouTubeUrl(videoUrl)) {
      throw Exception('Invalid YouTube video URL: $videoUrl');
    }

    final videoId = VideoId.parseVideoId(videoUrl);

    // Validate the videoId
    if (!VideoId.validateVideoId(videoId!)) {
      throw Exception('Invalid YouTube video ID: $videoId');
    }

    try {
      final manifest = await yt.videos.streamsClient.getManifest(videoId);

      final videoStreamInfo = manifest.muxed
          .where((e) => e.container.name == 'mp4')
          .getAllVideoQualities()
          .first as VideoStreamInfo;

      final saveFilePath = '$savePath/$videoId.mp4';

      final file = File(saveFilePath);

      if (await file.exists()) {
        if (context.mounted) {
          showSnackBar(context, "File Already Exists");
        }
        notifyListeners();
        throw Exception('File already exists: $saveFilePath');
      }

      final response = yt.videos.streamsClient.get(videoStreamInfo);

      final totalBytes = videoStreamInfo.size.totalBytes;
      var bytesDownloaded = 0;

      final progressStream = response.listen((chunk) {
        bytesDownloaded += chunk.length;
        final progress = bytesDownloaded / totalBytes;
        debugPrint('Progress: ${(progress * 100).toStringAsFixed(2)}%');
        // Update the progress value or perform any desired actions here
      });
      notifyListeners();
      await response.pipe(file.openWrite());

      debugPrint('Video downloaded successfully at $saveFilePath');
      if (context.mounted) {
        showSnackBar(context, "Video Downloaded Successfully");
      }
      progressStream
          .cancel(); // Cancel the progress stream when download completes
      notifyListeners();
    } catch (e) {
      showSnackBar(context, "Error downloading video");
      throw Exception('Error downloading video: $e');
    } finally {
      yt.close();
    }
  }

  // Validate URL
  bool isYouTubeUrl(String url) {
    final regex = RegExp(
      r"^(https?\:\/\/)?(www\.)?(youtube\.com|youtu\.?be)\/.+$",
      caseSensitive: false,
      multiLine: false,
    );
    return regex.hasMatch(url);
  }
}
