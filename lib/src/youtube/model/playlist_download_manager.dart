import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:videory/src/youtube/model/query_playlist.dart';

abstract class PlayListDownloadManager with ChangeNotifier {
  Future<void> download(Playlist playlist);
  Future<void> removeDownload(String playlistId);
  List<Playlist> getDownloadedPlaylists();
}

class PlayListDownloadManagerImpl extends ChangeNotifier
    implements PlayListDownloadManager {
  SharedPreferences prefs;
  int nextId;
  List<String> playlistIds;
  List<Playlist> playlists;

  PlayListDownloadManagerImpl._(
      this.prefs, this.nextId, this.playlistIds, this.playlists);

  static Future<PlayListDownloadManagerImpl> getInstance() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int nextId = prefs.getInt('next_id') ?? 0;
    final List<String> playlistIds = prefs.getStringList('playlist_list') ?? [];
    final List<Playlist> playlists = playlistIds
        .map(
            (id) => Playlist.fromJson(json.decode(prefs.getString(id) ?? '{}')))
        .toList();

    return PlayListDownloadManagerImpl._(prefs, nextId, playlistIds, playlists);
  }

  @override
  Future<void> download(Playlist playlist) async {
    final playlistJson = json.encode(playlist.toJson());

    // Save the playlist with a unique id
    final String playlistId = 'playlist_${nextId.toString()}';
    playlistIds.add(playlistId);
    playlists.add(playlist);

    await prefs.setString(playlistId, playlistJson);
    await prefs.setStringList('playlist_list', playlistIds);
    await prefs.setInt('next_id', nextId + 1);

    notifyListeners();
  }

  @override
  List<Playlist> getDownloadedPlaylists() {
    throw playlists;
  }

  @override
  Future<void> removeDownload(String playlistId) async {
    playlistIds.remove(playlistId);
    playlists.removeWhere((playlist) => playlist.id == playlistId);

    await prefs.remove(playlistId);
    await prefs.setStringList('playlist_list', playlistIds);

    notifyListeners();
  }

  // Rest of the class implementation...
}
