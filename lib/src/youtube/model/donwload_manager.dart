import 'package:flutter/material.dart';

String bytesToString(int bytes) {
  final totalKiloBytes = bytes / 1024;
  final totalMegaBytes = totalKiloBytes / 1024;
  final totalGigaBytes = totalMegaBytes / 1024;

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

  debugPrint('${getLargestValue().toStringAsFixed(2)} ${getLargestSymbol()}');
  return '${getLargestValue().toStringAsFixed(2)} ${getLargestSymbol()}';
}

void getSnackBar(SnackBar snackBar, BuildContext context) {
  // final _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldMessengerState> scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  // ScaffoldMessenger.of(context).showSnackBar(snackBar);
  scaffoldKey.currentState!.showSnackBar(snackBar);

  // WidgetsBinding.instance
  //   .addPostFrameCallback((_) =>scaffoldKey.currentState?.showSnackBar(snackBar));
}

enum DownloadStatus { downloading, success, failed, muxing, canceled }

enum StreamType { audio, video }



/*


DOCS:

Multiplexing, or muxing, is a way of sending multiple signals or streams of information over a communications link at the same time in the form of a single, complex signal.
https://github.com/Hexer10/youtube_downloader_flutter/blob/master/lib/src/models/download_manager.dart

*/