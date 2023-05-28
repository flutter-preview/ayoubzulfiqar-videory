import 'package:flutter/foundation.dart' show immutable;
import 'package:videory/src/youtube/model/download_manager.dart';

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

class Playlist {
  final String id;
  final String title;
  final List<SingleTrack> tracks;

  Playlist({required this.id, required this.title, required this.tracks});

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final List<dynamic> trackList = json['tracks'] as List<dynamic>;
    final List<SingleTrack> tracks =
        trackList.map((track) => SingleTrack.fromJson(track)).toList();

    return Playlist(
      id: json['id'] as String,
      title: json['title'] as String,
      tracks: tracks,
    );
  }

  Map<String, dynamic> toJson() {
    final List<dynamic> trackList =
        tracks.map((track) => track.toJson()).toList();

    return {
      'id': id,
      'title': title,
      'tracks': trackList,
    };
  }

  SingleTrack? get video {
    // Return the first track as the video
    return tracks.isNotEmpty ? tracks.first : null;
  }
}
