import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:videory/src/youtube/model/query_video.dart';
import 'package:videory/src/youtube/model/settings.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
// import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

enum DownloadStatus {
  downloading,
  success,
  failed,
  muxing,
  canceled,
  completed,
}

enum StreamType { audio, video }

void showSnackbar(SnackBar snackBar) {
  // final _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldMessengerState> scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  // ScaffoldMessenger.of(context).showSnackBar(snackBar);
  scaffoldKey.currentState!.showSnackBar(snackBar);

  // WidgetsBinding.instance
  //   .addPostFrameCallback((_) =>scaffoldKey.currentState?.showSnackBar(snackBar));
}

extension StreamTypeExtension on StreamType {
  static StreamType fromString(String value) {
    if (value == 'video') {
      return StreamType.video;
    } else if (value == 'audio') {
      return StreamType.audio;
    }
    throw ArgumentError('Invalid stream type: $value');
  }
}

String bytesToString(int bytes) {
  final double totalKiloBytes = bytes / 1024;
  final double totalMegaBytes = totalKiloBytes / 1024;
  final double totalGigaBytes = totalMegaBytes / 1024;

  String getLargestSymbol() {
    if (totalGigaBytes.abs() >= 1) {
      return 'GB';
    }
    if (totalMegaBytes.abs() >= 1) {
      return 'MB';
    }
    if (totalKiloBytes.abs() >= 1) {
      return 'KB';
    }
    return 'B';
  }

  num getLargestValue() {
    if (totalGigaBytes.abs() >= 1) {
      return totalGigaBytes;
    }
    if (totalMegaBytes.abs() >= 1) {
      return totalMegaBytes;
    }
    if (totalKiloBytes.abs() >= 1) {
      return totalKiloBytes;
    }
    return bytes;
  }

  return '${getLargestValue().toStringAsFixed(2)} ${getLargestSymbol()}';
}

class StreamMerge extends ChangeNotifier {
  AudioOnlyStreamInfo? _audio;

  AudioOnlyStreamInfo? get audio => _audio;

  set audio(AudioOnlyStreamInfo? audio) {
    _audio = audio;
    notifyListeners();
  }

  VideoOnlyStreamInfo? _video;

  VideoOnlyStreamInfo? get video => _video;

  set video(VideoOnlyStreamInfo? video) {
    _video = video;
    notifyListeners();
  }

  StreamMerge();
}

class SingleTrack extends ChangeNotifier {
  final int id;
  final String title;
  final String size;
  final int totalSize;
  final StreamType streamType;

  String _path;

  int _downloadPerc = 0;
  DownloadStatus _downloadStatus = DownloadStatus.downloading;
  int _downloadedBytes = 0;
  String _error = '';

  String get path => _path;

  int get downloadPerc => _downloadPerc;

  DownloadStatus get downloadStatus => _downloadStatus;

  int get downloadedBytes => _downloadedBytes;

  String get error => _error;

  set path(String path) {
    _path = path;

    _prefs?.setString('video_$id', json.encode(this));
    notifyListeners();
  }

  set downloadPerc(int value) {
    _downloadPerc = value;

    _prefs?.setString('video_$id', json.encode(this));
    notifyListeners();
  }

  set downloadStatus(DownloadStatus value) {
    _downloadStatus = value;

    _prefs?.setString('video_$id', json.encode(this));
    notifyListeners();
  }

  set downloadedBytes(int value) {
    _downloadedBytes = value;

    _prefs?.setString('video_$id', json.encode(this));
    notifyListeners();
  }

  set error(String value) {
    _error = value;
    _prefs?.setString('video_$id', json.encode(this));

    notifyListeners();
  }

  VoidCallback? _cancelCallback;

  final SharedPreferences? _prefs;

  SingleTrack(this.id, String path, this.title, this.size, this.totalSize,
      this.streamType,
      {SharedPreferences? prefs})
      : _path = path,
        _prefs = prefs;

  factory SingleTrack.fromJson(Map<String, dynamic> json) {
    return SingleTrack(
      json['id'] as int,
      '',
      json['title'] as String,
      json['size'] as String,
      json['totalSize'] as int,
      StreamTypeExtension.fromString(json['streamType'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'size': size,
      'totalSize': totalSize,
      'streamType': streamType.toString().split('.').last,
    };
  }

  void cancelDownload() {
    if (_cancelCallback == null) {
      debugPrint('Tried to cancel an UnCancellable video');
      return;
    }
    _cancelCallback!();
  }
}

class MuxedTrack extends SingleTrack {
  final SingleTrack audio;
  final SingleTrack video;

  MuxedTrack(
    int id,
    String path,
    String title,
    String size,
    int totalSize,
    this.audio,
    this.video, {
    SharedPreferences? prefs,
    StreamType streamType = StreamType.video,
  }) : super(id, path, title, size, totalSize, streamType, prefs: prefs);

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'size': size,
      'totalSize': totalSize,
      'streamType': streamType.toString().split('.').last,
      'audio': audio.toJson(),
      'video': video.toJson(),
    };
  }

  factory MuxedTrack.fromJson(Map<String, dynamic> json) {
    return MuxedTrack(
      json['id'] as int,
      '',
      json['title'] as String,
      json['size'] as String,
      json['totalSize'] as int,
      SingleTrack.fromJson(json['audio'] as Map<String, dynamic>),
      SingleTrack.fromJson(json['video'] as Map<String, dynamic>),
      streamType: StreamTypeExtension.fromString(json['streamType'] as String),
    );
  }
}

class DownloadManager extends ChangeNotifier {
  DownloadManager();

  Future<void> downloadStream(
    YoutubeExplode yt,
    QueryVideo video,
    Settings settings,
    StreamType type, {
    StreamInfo? singleStream,
    StreamMerge? merger,
    String? ffmpegContainer,
  }) =>
      throw UnimplementedError();

  Future<void> removeVideo(SingleTrack video) => throw UnimplementedError();

  List<SingleTrack> get videos => throw UnimplementedError();
}

//------

class DownloadManagerImpl extends ChangeNotifier implements DownloadManager {
  static final invalidChars = RegExp(r'[\\\/:*?"<>|]');

  final SharedPreferences _prefs;

  @override
  final List<SingleTrack> videos;
  final List<String> videoIds;

  final Map<int, bool> cancelTokens = {};

  int _nextId;

  int get nextId {
    _prefs.setInt('next_id', ++_nextId);
    return _nextId;
  }

  DownloadManagerImpl._(this._prefs, this._nextId, this.videoIds, this.videos);

  void addVideo(SingleTrack video) {
    final String id = 'video_${video.id}';
    videoIds.add(id);

    _prefs.setStringList('video_list', videoIds);
    _prefs.setString(id, json.encode(video));

    notifyListeners();
  }

  @override
  Future<void> removeVideo(SingleTrack video) async {
    final String id = 'video_${video.id}';

    videoIds.remove(id);
    videos.removeWhere((e) => e.id == video.id);

    _prefs.setStringList('video_list', videoIds);
    _prefs.remove(id);

    final File file = File(video.path);
    if (await file.exists()) {
      await file.delete();
    }

    notifyListeners();
  }

  Future<String> getValidPath(String strPath) async {
    final File file = File(strPath);
    if (!(await file.exists())) {
      return strPath;
    }
    final String basename = path
        .withoutExtension(strPath)
        .replaceFirst(RegExp(r' \([0-9]+\)$'), '');
    final String ext = path.extension(strPath);

    int count = 0;

    while (true) {
      final String newPath = '$basename (${++count})$ext';
      final File file = File(newPath);
      if (await file.exists()) {
        continue;
      }
      return newPath;
    }
  }

  @override
  Future<void> downloadStream(
    YoutubeExplode yt,
    QueryVideo video,
    Settings settings,
    StreamType type, {
    StreamInfo? singleStream,
    StreamMerge? merger,
    String? ffmpegContainer,
  }) async {
    assert(singleStream != null || merger != null);
    assert(merger == null ||
        merger.video != null &&
            merger.audio != null &&
            ffmpegContainer != null);

    if (Platform.isAndroid || Platform.isIOS) {
      final PermissionStatus req = await Permission.storage.request();
      if (!req.isGranted) {
        showSnackbar(
          const SnackBar(
            content: Text(
              "Permission Error",
            ),
          ),
        );
        return;
      }
    }

    final bool isMerging = singleStream == null;
    final StreamInfo stream = singleStream ?? merger!.video!;
    final int id = nextId;
    final String saveDir = settings.downloadPath;

    if (isMerging) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final process = await Process.run('ffmpeg', [], runInShell: true);
        if (!(process.stderr as String).startsWith("ffmpeg version")) {
          showSnackbar(const SnackBar(content: Text("FFMPEGNotFound")));
          return;
        }
      }
      processMuxedTrack(
        yt,
        video,
        merger!,
        stream,
        saveDir,
        id,
        ffmpegContainer!,
        settings,
      );
    } else {
      processSingleTrack(
        yt,
        video,
        stream,
        saveDir,
        id,
        type,
      );
    }
  }

  Future<void> processSingleTrack(
    YoutubeExplode yt,
    QueryVideo video,
    StreamInfo stream,
    String saveDir,
    int id,
    StreamType type,
  ) async {
    final String downloadPath = await getValidPath(
        '${path.join(saveDir, video.title.replaceAll(invalidChars, '_'))}${'.${stream.container.name}'}');

    final String tempPath = path.join(saveDir, 'Unconfirmed $id.ytdownload');

    final File file = File(tempPath);
    final IOSink sink = file.openWrite();
    final Stream<List<int>> dataStream = yt.videos.streamsClient.get(stream);

    final SingleTrack downloadVideo = SingleTrack(
      id,
      downloadPath,
      video.title,
      bytesToString(stream.size.totalBytes),
      stream.size.totalBytes,
      type,
      prefs: _prefs,
    );

    addVideo(downloadVideo);
    videos.add(downloadVideo);

    final StreamSubscription<List<int>> sub = dataStream.listen(
      (data) => handleData(data, sink, downloadVideo),
      onError: (error, __) async {
        showSnackbar(SnackBar(content: Text("Failed Download ${video.title}")));
        await cleanUp(sink, file);
        downloadVideo.downloadStatus = DownloadStatus.failed;
        downloadVideo.error = error.toString();
      },
      onDone: () async {
        final String? newPath = await cleanUp(sink, file, downloadPath);
        downloadVideo.downloadStatus = DownloadStatus.success;
        downloadVideo.path = newPath!;
        showSnackbar(
          SnackBar(
            content: Text("Finished Download ${video.title}"),
          ),
        );
      },
      cancelOnError: true,
    );

    downloadVideo._cancelCallback = () async {
      sub.cancel();
      await cleanUp(sink, file);
      downloadVideo.downloadStatus = DownloadStatus.canceled;

      showSnackbar(SnackBar(content: Text("Cancel Download ${video.title}")));
    };

    showSnackbar(SnackBar(content: Text("Start Download ${video.title}")));
  }

  Future<void> processMuxedTrack(
    YoutubeExplode yt,
    QueryVideo video,
    StreamMerge merger,
    StreamInfo stream,
    String saveDir,
    int id,
    String ffmpegContainer,
    Settings settings,
  ) async {
    final String downloadPath = await getValidPath(
        '${path.join(settings.downloadPath, video.title.replaceAll(invalidChars, '_'))}$ffmpegContainer');

    final SingleTrack audioTrack = processTrack(yt, merger.audio!, saveDir,
        stream.container.name, video, StreamType.audio);

    final videoTrack = processTrack(yt, merger.video!, saveDir,
        stream.container.name, video, StreamType.video);

    final MuxedTrack muxedTrack = MuxedTrack(
      id,
      downloadPath,
      video.title,
      bytesToString(videoTrack.totalSize + audioTrack.totalSize),
      videoTrack.totalSize + audioTrack.totalSize,
      audioTrack,
      videoTrack,
      prefs: _prefs,
    );
    muxedTrack._cancelCallback = () {
      audioTrack._cancelCallback!();
      videoTrack._cancelCallback!();

      muxedTrack.downloadStatus = DownloadStatus.canceled;

      // localizations.cancelDownload(video.title);
    };

    Future<void> downloadListener() async {
      muxedTrack.downloadedBytes =
          audioTrack.downloadedBytes + videoTrack.downloadedBytes;
      muxedTrack.downloadPerc =
          (muxedTrack.downloadedBytes / muxedTrack.totalSize * 100).floor();
      if (audioTrack.downloadStatus == DownloadStatus.success &&
          videoTrack.downloadStatus == DownloadStatus.success) {
        muxedTrack.downloadStatus = DownloadStatus.muxing;
        final path = await getValidPath(muxedTrack.path);
        muxedTrack.path = path;

        final args = [
          '-i',
          audioTrack.path,
          '-i',
          videoTrack.path,
          '-progress',
          '-',
          '-y',
          '-shortest',
          path,
        ];
        if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
          desktopFFMPEG(
            muxedTrack,
            audioTrack,
            videoTrack,
            path,
            args,
            downloadListener,
            video,
          );
        } else {
          mobileFFMPEG(
            muxedTrack,
            audioTrack,
            videoTrack,
            path,
            args,
            downloadListener,
            video,
          );
        }
      }
    }

    audioTrack.addListener(downloadListener);
    videoTrack.addListener(downloadListener);

    addVideo(muxedTrack);
    videos.add(muxedTrack);

    showSnackbar(SnackBar(content: Text("Start Download ${video.title}")));
  }

  Future<void> desktopFFMPEG(
    MuxedTrack muxedTrack,
    SingleTrack audioTrack,
    SingleTrack videoTrack,
    String outPath,
    List<String> args,
    VoidCallback downloadListener,
    QueryVideo video,
  ) async {
    final Process process =
        await Process.start('ffmpeg', args, runInShell: true);
    process.exitCode.then((exitCode) async {
      //sigterm
      if (exitCode == -1) {
        return;
      }
      muxedTrack.downloadStatus = DownloadStatus.success;

      audioTrack.removeListener(downloadListener);
      videoTrack.removeListener(downloadListener);

      await File(audioTrack.path).delete();
      await File(videoTrack.path).delete();

      // localizations.finishMerge();

      debugPrint("Finish Merge ${video.title}");
    });

    process.stdout.listen((event) {
      final String data = utf8.decode(event);
      debugPrint('OUT: $data');

      final String? timeStr =
          RegExp(r'out_time_ms=(\d+)').firstMatch(data)?.group(1);
      if (timeStr == null) {
        return;
      }

      final int ms = int.parse(timeStr);

      muxedTrack.downloadPerc =
          (ms / video.duration.inMicroseconds * 100).round();
    });

    muxedTrack._cancelCallback = () async {
      audioTrack._cancelCallback!();
      videoTrack._cancelCallback!();

      process.kill();
      muxedTrack.downloadStatus = DownloadStatus.canceled;

      debugPrint("Cancel Merge ${video.title}");
    };
  }

  Future<void> mobileFFMPEG(
    MuxedTrack muxedTrack,
    SingleTrack audioTrack,
    SingleTrack videoTrack,
    String outPath,
    List<String> args,
    VoidCallback downloadListener,
    QueryVideo video,
  ) async {
    // final ffmpeg = FFmpegKit();
    final FFmpegSession session =
        await FFmpegKit.executeWithArgumentsAsync(args, (execution) async {
      final bool ok = ReturnCode.isSuccess(await execution.getReturnCode());
      //killed
      // final ReturnCode? code = await execution.getReturnCode();
      // code == 255
      if (!ok) {
        return;
      }
      muxedTrack.downloadStatus = DownloadStatus.success;

      audioTrack.removeListener(downloadListener);
      videoTrack.removeListener(downloadListener);

      await File(audioTrack.path).delete();
      await File(videoTrack.path).delete();

      debugPrint("Finish Merge ${video.title}");
    });

    final File file = File(outPath);
    var oldSize = -1;

    // Currently the ffmpeg's executionCallback is never called so we have to
    // pool and check if the file is created and written to.
    Future.doWhile(() async {
      if (muxedTrack.downloadStatus == DownloadStatus.canceled) {
        return false;
      }

      if (!(await file.exists())) {
        await Future.delayed(const Duration(seconds: 2));
        return true;
      }
      final FileStat stat = await file.stat();
      final int size = stat.size;
      if (oldSize != size) {
        oldSize = size;
        await Future.delayed(const Duration(seconds: 2));
        return true;
      }
      return false;
    }).then((_) async {
      if (muxedTrack.downloadStatus == DownloadStatus.canceled) {
        return;
      }

      muxedTrack.downloadStatus = DownloadStatus.success;

      audioTrack.removeListener(downloadListener);
      videoTrack.removeListener(downloadListener);

      await File(audioTrack.path).delete();
      await File(videoTrack.path).delete();

      debugPrint("Finish Merge ${video.title}");
      showSnackbar(SnackBar(content: Text("Finish Merge ${video.title}")));
    });

    muxedTrack._cancelCallback = () async {
      audioTrack._cancelCallback!();
      videoTrack._cancelCallback!();

      // ffmpeg.cancelExecution(id);
      final int? id = session.getSessionId();
      FFmpegKit.cancel(id);
      muxedTrack.downloadStatus = DownloadStatus.canceled;
      debugPrint("Cancel Merge ${video.title}");
      showSnackbar(SnackBar(content: Text("Cancel Merge ${video.title}")));
    };
  }

  SingleTrack processTrack(
    YoutubeExplode yt,
    StreamInfo stream,
    String saveDir,
    String container,
    QueryVideo video,
    StreamType type,
  ) {
    final int id = nextId;
    final String tempPath =
        path.join(saveDir, 'Unconfirmed $id.ytdownload.$container');

    final File file = File(tempPath);
    final IOSink sink = file.openWrite();

    final SingleTrack downloadVideo = SingleTrack(
      id,
      tempPath,
      'Temp$id',
      bytesToString(stream.size.totalBytes),
      stream.size.totalBytes,
      type,
      prefs: _prefs,
    );

    final Stream<List<int>> dataStream = yt.videos.streamsClient.get(stream);
    final StreamSubscription<List<int>> sub = dataStream
        .listen((data) => handleData(data, sink, downloadVideo),
            onError: (error, __) async {
      await cleanUp(sink, file);
      downloadVideo.downloadStatus = DownloadStatus.failed;
      downloadVideo.error = error.toString();

      showSnackbar(SnackBar(content: Text("Failed Download ${video.title}")));
    }, onDone: () async {
      await sink.flush();
      await sink.close();
      downloadVideo.downloadStatus = DownloadStatus.success;
    }, cancelOnError: true);

    downloadVideo._cancelCallback = () async {
      sub.cancel();
      await cleanUp(sink, file);
      downloadVideo.downloadStatus = DownloadStatus.canceled;
    };
    return downloadVideo;
  }

  void handleData(List<int> bytes, IOSink sink, SingleTrack video) {
    sink.add(bytes);
    video.downloadedBytes += bytes.length;
    final newProgress = (video.downloadedBytes / video.totalSize * 100).floor();
    video.downloadPerc = newProgress;
  }

  /// Flushes and closes the sink.
  /// If path is specified the file is moved to that path, otherwise is it deleted.
  /// Returns the new file path if [path] is specified.
  Future<String?> cleanUp(IOSink sink, File file, [String? path]) async {
    await sink.flush();
    await sink.close();
    if (path != null) {
      // ignore: parameter_assignments
      path = await getValidPath(path);
      await file.rename(path);
      return path;
    }
    await file.delete();
    return null;
  }

  factory DownloadManagerImpl.init(SharedPreferences prefs) {
    List<String>? videoIds = prefs.getStringList('video_list');
    int? nextId = prefs.getInt('next_id');
    if (videoIds == null) {
      prefs.setStringList('video_list', const <String>[]);
      videoIds = <String>[];
    }
    if (nextId == null) {
      prefs.setInt('next_id', 0);
      nextId = 1;
    }
    final List<SingleTrack> videos = <SingleTrack>[];
    for (final String id in videoIds) {
      final jsonVideo = prefs.getString(id)!;
      final SingleTrack track =
          SingleTrack.fromJson(json.decode(jsonVideo) as Map<String, dynamic>);
      if (track.downloadStatus == DownloadStatus.downloading ||
          track.downloadStatus == DownloadStatus.muxing) {
        track.downloadStatus = DownloadStatus.failed;
        track.error = 'Error occurred while downloading';
        prefs.setString(id, json.encode(track));
      }
      videos.add(track);
    }
    return DownloadManagerImpl._(prefs, nextId, videoIds, videos);
  }
}
