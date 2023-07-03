import 'package:flutter/material.dart';
import 'package:videory/src/youtube/models/single_video_model.dart';

class InfoView extends StatelessWidget {
  final SingleYouTubeVideo? videoInfo;
  const InfoView({super.key, required this.videoInfo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                videoInfo?.thumbnailUrl ?? "No Image Yet",
                height: 100.0,
                width: 100.0,
              ),
              const SizedBox(height: 20),
              Text(videoInfo?.videoId ?? ""),
              const SizedBox(height: 20),
              Text(videoInfo?.channelTitle ?? ""),
              const SizedBox(height: 20),
              Text(videoInfo?.viewCount.toString() ?? ""),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(videoInfo?.likeCount.toString() ?? ""),
                  const SizedBox(width: 20),
                  Text(videoInfo?.dislikeCount.toString() ?? ""),
                ],
              ),
              const SizedBox(height: 20),
              Text(videoInfo?.duration ?? "")
            ],
          ),
        ),
      ],
    );
  }
}
