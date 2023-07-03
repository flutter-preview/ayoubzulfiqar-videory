import 'package:flutter/material.dart';
import 'package:videory/src/youtube/models/single_video_model.dart';
import 'package:videory/src/youtube/screens/widgets/snack_bar.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class SingleYouTubeVideoDownloadManager {
  SingleYouTubeVideo? singleYouTubeVideo;
  double progress = 0.0;
  int value = 0;
  bool start = false;

  // Info Fetcher
  Future<SingleYouTubeVideo?> fetchYouTubeVideoInfo(
    String youtubeVideoURL,
    BuildContext context,
  ) async {
    final YoutubeExplode youTubeVideoClient = YoutubeExplode();
    try {
      final parsedUrl = VideoId.parseVideoId(youtubeVideoURL);
      if (parsedUrl == "" && parsedUrl == null) {
        return null;
      }

      final Video videoQuery =
          await youTubeVideoClient.videos.get(youtubeVideoURL);

      final result = singleYouTubeVideo = SingleYouTubeVideo(
        videoId: videoQuery.id.toString(),
        title: videoQuery.title,
        channelTitle: videoQuery.author,
        thumbnailUrl: videoQuery.thumbnails.standardResUrl,
        viewCount: videoQuery.engagement.viewCount,
        likeCount: videoQuery.engagement.likeCount ?? 0,
        dislikeCount: videoQuery.engagement.dislikeCount ?? 0,
        duration: videoQuery.duration.toString(),
      );
      debugPrint(result.toString());
      return result;
    } catch (e) {
      showSnackBar(context, "Error fetching YouTube Video Information");
      throw Exception(e.toString());
    } finally {
      youTubeVideoClient.close();
    }
  }

  // Download Manager
}
