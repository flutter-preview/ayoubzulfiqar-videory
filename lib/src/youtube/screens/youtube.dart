import 'package:flutter/material.dart';
import 'package:videory/src/youtube/models/single_video_model.dart';
import 'package:videory/src/youtube/screens/widgets/info_view.dart';
import 'package:videory/src/youtube/services/single_youtube_video_downloader.dart';

class YouTube extends StatefulWidget {
  const YouTube({super.key});

  @override
  State<YouTube> createState() => _YouTubeState();
}

class _YouTubeState extends State<YouTube> {
  final TextEditingController youtubeURLController = TextEditingController();
  // late Future<SingleYouTubeVideo>? fetchFuture;
  final SingleYouTubeVideoDownloadManager manager =
      SingleYouTubeVideoDownloadManager();

  Future<SingleYouTubeVideo?> _fetchData() async {
    if (youtubeURLController.text.trim() == "" &&
        youtubeURLController.text.isEmpty) {
      return null;
    } else {
      final fetchFuture =
          manager.fetchYouTubeVideoInfo(youtubeURLController.text, context);
      setState(() {});
      return fetchFuture;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    youtubeURLController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Info"),
      ),
      body: Column(
        children: [
          TextField(
            controller: youtubeURLController,
            decoration: const InputDecoration(
              labelText: 'URL',
            ),
          ),
          TextButton(
            onPressed: _fetchData,
            child: const Text('Fetch'),
          ),
          FutureBuilder<SingleYouTubeVideo?>(
            future: _fetchData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                debugPrint(snapshot.hasError.toString());
                return Text('Error: ${snapshot.error}');
              } else {
                final data = snapshot.data;
                if (data == null) {
                  return const Center(
                    child: Text("Waiting For URL"),
                  );
                }
                return Expanded(
                  child:
                      SingleChildScrollView(child: InfoView(videoInfo: data)),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
