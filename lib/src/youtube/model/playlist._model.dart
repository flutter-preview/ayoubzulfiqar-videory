import 'package:flutter/foundation.dart' show immutable;
import 'package:videory/src/youtube/model/video_model.dart';

@immutable
class QueryPlaylist {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String channelTitle;
  final int videoCount;
  final Future<List<QueryVideo>> videos;

  const QueryPlaylist({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.videoCount,
    required this.videos,
  });
}
