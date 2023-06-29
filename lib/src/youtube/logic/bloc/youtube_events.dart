import 'package:flutter/foundation.dart' show immutable;
import 'package:videory/src/youtube/model/single_video.dart';

@immutable
abstract class YouTubeResult {
  const YouTubeResult();
}

@immutable
class LoadingYouTubeResult implements YouTubeResult {}

@immutable
class NoYouTubeResults implements YouTubeResult {}

@immutable
class YouTubeResultWithError implements YouTubeResult {
  final Object? error;
  const YouTubeResultWithError(this.error);
}

@immutable
class YouTubeVideoResult implements YouTubeResult {
  final YouTubeVideo youTubeVideo;
  const YouTubeVideoResult(this.youTubeVideo);
}
