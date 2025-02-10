import 'package:flutter/material.dart';
import 'package:ai_video/models/generated_video.dart';
import 'package:ai_video/service/database_service.dart';
import 'package:ai_video/constants/theme.dart';

class VideoHistoryPage extends StatelessWidget {
  const VideoHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackgroundColor : AppTheme.lightBackgroundColor,
      appBar: AppBar(
        title: Text('Video History', style: AppTheme.getTitleStyle(isDark)),
      ),
      body: FutureBuilder<List<GeneratedVideo>>(
        future: DatabaseService().getAllVideos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No videos generated yet',
                style: AppTheme.getTitleStyle(isDark),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final video = snapshot.data![index];
              return ListTile(
                title: Text(video.title),
                subtitle: Text(video.createdAt.toString()),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await DatabaseService().deleteVideo(video.id!);
                    // Refresh the page
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
