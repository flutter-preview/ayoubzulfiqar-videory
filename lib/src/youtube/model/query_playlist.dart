import 'package:flutter/foundation.dart' show immutable;

@immutable
class QueryPlayList {
  final String title;
  final String id;
  final String author;
  final Duration duration;
  final String thumbnail;

  const QueryPlayList({
    required this.title,
    required this.id,
    required this.author,
    required this.duration,
    required this.thumbnail,
  });
}

@immutable
class PlaylistQuery {
  final String playlistId;
  final int maxResults;
  final String? pageToken;

  const PlaylistQuery({
    required this.playlistId,
    this.maxResults = 10,
    this.pageToken,
  });
}

@immutable
class PlaylistResult {
  final List<QueryPlayList> playlists;
  final String? nextPageToken;

  const PlaylistResult({
    required this.playlists,
    this.nextPageToken,
  });
}


/*

DOCS:

In the above code, we have the following classes:

QueryPlayList: Represents a single playlist item with properties like title, id, author, duration, and thumbnail.
PlaylistQuery: Represents a query model for requesting YouTube playlists. It includes properties like playlistId (the unique identifier of the playlist), maxResults (the maximum number of videos to retrieve from the playlist), and pageToken (optional token for pagination if the playlist has more results).
PlaylistResult: Represents the result of a playlist query, containing a list of QueryPlayList items and an optional nextPageToken for pagination.
These classes can be used to model and handle YouTube playlist queries in your Flutter app.

*/