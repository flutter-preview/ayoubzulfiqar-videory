import 'package:flutter/foundation.dart' show immutable;

@immutable
class QueryVideo {
  final String title;
  final String id;
  final String author;
  final Duration duration;
  final String thumbnail;

  const QueryVideo({
    required this.title,
    required this.id,
    required this.author,
    required this.duration,
    required this.thumbnail,
  });
}
