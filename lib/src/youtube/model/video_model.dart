import 'package:flutter/foundation.dart' show immutable;

@immutable
class QueryVideo {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String channelTitle;
  final Duration duration;

  const QueryVideo({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.duration,
  });
}
