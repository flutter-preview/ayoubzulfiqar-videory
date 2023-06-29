class YouTubeVideo {
  String videoId;
  String title;
  String thumbnailUrl;
  String channelTitle;
  int viewCount;
  int likeCount;
  int dislikeCount;
  String duration;

  YouTubeVideo({
    required this.videoId,
    required this.title,
    required this.channelTitle,
    required this.thumbnailUrl,
    required this.viewCount,
    required this.likeCount,
    required this.dislikeCount,
    required this.duration,
  });

  @override
  String toString() {
    return {
      "VideID": videoId,
      "Title": title,
      "ThumbnailURL": thumbnailUrl,
      "ChannelAuthor": channelTitle,
      "ViewCount": viewCount,
      "LikeCount": likeCount,
      "DislikeCount": dislikeCount,
      "Duration": duration
    }.toString();
  }
}
