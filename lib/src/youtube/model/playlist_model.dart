class YouTubePlaylist {
  final String playlistId;
  final String title;
  final String thumbnailUrl;
  final String channelTitle;
  final int videoCount;

  YouTubePlaylist({
    required this.playlistId,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.videoCount,
  });

  @override
  String toString() {
    return {
      "PlaylistID": playlistId,
      "Title": title,
      "ThumbnailURL": thumbnailUrl,
      "ChannelTitle": channelTitle,
      "VideoCount": videoCount,
    }.toString();
  }
}
