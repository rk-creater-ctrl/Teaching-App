import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:video_player/video_player.dart';
import '../api/api_client.dart';
import '../models/app_settings.dart';
import '../theme/student_ui.dart';

class VideoItem {
  final String id;
  final String title;
  final String? youtubeVideoId;
  final String? fileUrl;
  final String type; // 'youtube' or 'file'

  VideoItem({
    required this.id,
    required this.title,
    required this.type,
    this.youtubeVideoId,
    this.fileUrl,
  });

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    return VideoItem(
      id: (json['id'] ?? json['_id']) as String,
      title: json['title'] as String,
      type: (json['type'] as String?) ?? 'youtube',
      youtubeVideoId: json['youtubeVideoId'] as String?,
      fileUrl: json['fileUrl'] as String?,
    );
  }

  bool get isYouTube => type == 'youtube' && youtubeVideoId != null;
  bool get isFile => type == 'file' && fileUrl != null && fileUrl!.isNotEmpty;
}

class VideosScreen extends StatefulWidget {
  final AppSettings settings;

  const VideosScreen({
    super.key,
    this.settings = AppSettings.fallback,
  });

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  bool _loading = true;
  String? _error;
  List<VideoItem> _videos = [];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ApiClient();
      final res = await api.getVideos();
      final list = res.data as List<dynamic>;
      final videos =
          list.map((e) => VideoItem.fromJson(e as Map<String, dynamic>)).toList();

      setState(() {
        _videos = videos;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load videos';
        _loading = false;
      });
    }
  }

  String _thumbUrlYoutube(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/0.jpg';
  }

  String _thumbFor(VideoItem v) {
    if (v.isYouTube) {
      return _thumbUrlYoutube(v.youtubeVideoId!);
    }
    // simple placeholder for uploaded file videos
    return 'https://dummyimage.com/640x360/111827/9ca3af&text=Video';
  }

  void _onVideoTap(VideoItem video) {
    if (video.isYouTube) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _YouTubePlayerPage(video: video),
        ),
      );
    } else if (video.isFile) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FileVideoPlayerPage(video: video),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video source not available')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudentColors.bg,
      appBar: AppBar(
        backgroundColor: StudentColors.bg,
        elevation: 0,
        title: Row(
          children: [
            StudentBrandMark(settings: widget.settings, size: 32, radius: 10),
            const SizedBox(width: 10),
            const Text(
              'Videos',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      body: _loading
          ? GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 16 / 11,
              children: const [
                StudentSkeletonCard(height: 160),
                StudentSkeletonCard(height: 160),
                StudentSkeletonCard(height: 160),
                StudentSkeletonCard(height: 160),
              ],
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: StudentEmptyState(
                      icon: Icons.video_library_outlined,
                      title: 'Videos unavailable',
                      message: _error!,
                      actionLabel: 'Retry',
                      onAction: _loadVideos,
                    ),
                  ),
                )
              : _buildGrid(),
    );
  }

  Widget _buildGrid() {
    if (_videos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: StudentEmptyState(
          icon: Icons.ondemand_video_outlined,
          title: 'No videos yet',
          message: 'Recorded classes will appear here after admin uploads them.',
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 16 / 11,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final v = _videos[index];
        return GestureDetector(
          onTap: () => _onVideoTap(v),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF1F2937),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 18,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        _thumbFor(v),
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.4),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    const Positioned.fill(
                      child: Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          size: 38,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: v.isYouTube
                              ? Colors.redAccent.withOpacity(0.9)
                              : Colors.greenAccent.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          v.isYouTube ? 'YouTube' : 'File',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Text(
                      v.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Full-screen page for YouTube playback with minimal controls
class _YouTubePlayerPage extends StatefulWidget {
  final VideoItem video;
  const _YouTubePlayerPage({required this.video});

  @override
  State<_YouTubePlayerPage> createState() => _YouTubePlayerPageState();
}

class _YouTubePlayerPageState extends State<_YouTubePlayerPage> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: false, // hide controls as much as allowed
        showFullscreenButton: false,
      ),
    );

    _controller.loadVideoById(videoId: widget.video.youtubeVideoId!);
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerControllerProvider(
      controller: _controller,
      child: Scaffold(
        backgroundColor: const Color(0xFF020617),
        appBar: AppBar(
          backgroundColor: const Color(0xFF020617),
          title: Text(
            widget.video.title,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubePlayer(
              controller: _controller,
              aspectRatio: 16 / 9,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen page for uploaded file videos
class FileVideoPlayerPage extends StatefulWidget {
  final VideoItem video;
  const FileVideoPlayerPage({required this.video});

  @override
  State<FileVideoPlayerPage> createState() => _FileVideoPlayerPageState();
}

class _FileVideoPlayerPageState extends State<FileVideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.fileUrl!),
    )
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
        });
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        title: Text(
          widget.video.title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: _initialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: _initialized
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF22C55E),
              onPressed: () {
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}
