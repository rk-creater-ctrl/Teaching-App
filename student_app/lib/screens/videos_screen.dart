import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:video_player/video_player.dart';
import '../api/api_client.dart';
import '../models/app_settings.dart';
import '../models/student.dart';
import '../theme/student_ui.dart';

class VideoItem {
  final String id;
  final String title;
  final String? youtubeVideoId;
  final String? fileUrl;
  final String? courseTitle;
  final String type; // 'youtube' or 'file'

  VideoItem({
    required this.id,
    required this.title,
    required this.type,
    this.youtubeVideoId,
    this.fileUrl,
    this.courseTitle,
  });

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    return VideoItem(
      id: (json['id'] ?? json['_id']) as String,
      title: json['title'] as String,
      type: (json['type'] as String?) ?? 'youtube',
      youtubeVideoId: _extractYouTubeVideoId(json['youtubeVideoId'] as String?),
      fileUrl: json['fileUrl'] as String?,
      courseTitle: json['courseTitle'] as String?,
    );
  }

  bool get isYouTube => type == 'youtube' && youtubeVideoId != null;
  bool get isFile => type == 'file' && fileUrl != null && fileUrl!.isNotEmpty;
}

String? _extractYouTubeVideoId(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return null;
  if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(raw)) return raw;

  final uri = Uri.tryParse(raw);
  final queryId = uri?.queryParameters['v'];
  if (queryId != null && queryId.isNotEmpty) return queryId;

  final match = RegExp(
    r'(?:youtu\.be\/|embed\/|shorts\/|live\/)([a-zA-Z0-9_-]{11})',
  ).firstMatch(raw);
  return match?.group(1) ?? raw;
}

class VideosScreen extends StatefulWidget {
  final AppSettings settings;
  final Student? student;
  final String? courseId;
  final String? courseTitle;
  final Future<void> Function()? onCourseProgressChanged;

  const VideosScreen({
    super.key,
    this.settings = AppSettings.fallback,
    this.student,
    this.courseId,
    this.courseTitle,
    this.onCourseProgressChanged,
  });

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  bool _loading = true;
  String? _error;
  List<VideoItem> _videos = [];

  bool get _isCourseVideos =>
      widget.courseId != null && widget.courseId!.trim().isNotEmpty;

  String get _screenTitle => _isCourseVideos
      ? '${widget.courseTitle?.trim().isNotEmpty == true ? widget.courseTitle : 'Course'} Videos'
      : 'Global Videos';

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
      final res = _isCourseVideos
          ? await api.getCourseVideos(widget.courseId!)
          : await api.getGlobalVideos();
      final list = res.data as List<dynamic>;
      final videos = list
          .map((e) => VideoItem.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _videos = videos;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load videos: $e');
      setState(() {
        _error = 'Failed to load videos';
        _loading = false;
      });
    }
  }

  Future<VideoItem?> _refreshVideo(String videoId) async {
    final api = ApiClient();
    final res = _isCourseVideos
        ? await api.getCourseVideos(widget.courseId!)
        : await api.getGlobalVideos();
    final list = res.data as List<dynamic>;
    final videos = list
        .map((e) => VideoItem.fromJson(e as Map<String, dynamic>))
        .toList();

    if (mounted) {
      setState(() => _videos = videos);
    }

    for (final video in videos) {
      if (video.id == videoId) return video;
    }
    return null;
  }

  Future<void> _markCourseVideoComplete(String videoId) async {
    if (!_isCourseVideos) return;
    try {
      await ApiClient().updateCourseProgress(
        studentId: widget.student?.id ?? '',
        courseId: widget.courseId!,
        videoId: videoId,
        completed: true,
      );
      await widget.onCourseProgressChanged?.call();
    } catch (e) {
      debugPrint('Could not mark course video complete: $e');
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
        MaterialPageRoute(builder: (_) => _YouTubePlayerPage(video: video)),
      );
    } else if (video.isFile) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FileVideoPlayerPage(
            video: video,
            refreshVideo: _refreshVideo,
            onVideoCompleted: _isCourseVideos ? _markCourseVideoComplete : null,
          ),
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
            Text(_screenTitle, style: const TextStyle(color: Colors.white)),
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
      return Padding(
        padding: const EdgeInsets.all(20),
        child: StudentEmptyState(
          icon: Icons.ondemand_video_outlined,
          title: 'No videos yet',
          message: _isCourseVideos
              ? 'No videos available for this course.'
              : 'Global videos will appear here after admin uploads them.',
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
              border: Border.all(color: const Color(0xFF1F2937), width: 1),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: v.isYouTube
                              ? Colors.redAccent.withOpacity(0.9)
                              : Colors.greenAccent.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          v.courseTitle?.isNotEmpty == true
                              ? v.courseTitle!
                              : (v.isYouTube ? 'YouTube' : 'File'),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
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
  bool _fullscreen = false;

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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _controller.close();
    super.dispose();
  }

  Future<void> _toggleFullscreen() async {
    final next = !_fullscreen;
    setState(() => _fullscreen = next);

    if (next) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerControllerProvider(
      controller: _controller,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _fullscreen
            ? null
            : AppBar(
                backgroundColor: Colors.black,
                title: Text(
                  widget.video.title,
                  style: const TextStyle(color: Colors.white),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Fullscreen',
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: _toggleFullscreen,
                  ),
                ],
              ),
        body: Stack(
          children: [
            Center(
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 1600,
                    height: 900,
                    child: YoutubePlayer(
                      controller: _controller,
                      aspectRatio: 16 / 9,
                    ),
                  ),
                ),
              ),
            ),
            if (_fullscreen)
              Positioned(
                top: 12,
                right: 12,
                child: SafeArea(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: IconButton(
                      tooltip: 'Exit fullscreen',
                      icon: const Icon(
                        Icons.fullscreen_exit,
                        color: Colors.white,
                      ),
                      onPressed: _toggleFullscreen,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen page for uploaded file videos
class FileVideoPlayerPage extends StatefulWidget {
  final VideoItem video;
  final Future<VideoItem?> Function(String videoId) refreshVideo;
  final Future<void> Function(String videoId)? onVideoCompleted;

  const FileVideoPlayerPage({
    required this.video,
    required this.refreshVideo,
    this.onVideoCompleted,
  });

  @override
  State<FileVideoPlayerPage> createState() => _FileVideoPlayerPageState();
}

class _FileVideoPlayerPageState extends State<FileVideoPlayerPage> {
  VideoPlayerController? _controller;
  late VideoItem _video;
  bool _initialized = false;
  bool _fullscreen = false;
  bool _completionReported = false;
  bool _controlsVisible = true;
  Duration _furthestWatchedPosition = Duration.zero;
  Duration? _seekPreview;
  Timer? _controlsHideTimer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _video = widget.video;
    _initializeVideo();
  }

  String _resolvedVideoUrl() {
    final raw = _video.fileUrl!.trim();
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return '${ApiClient().baseUrl}/${raw.replaceFirst(RegExp(r'^/+'), '')}';
  }

  Future<void> _initializeVideo() async {
    try {
      final url = _resolvedVideoUrl();
      final uri = Uri.parse(url);
      debugPrint(
        'Initializing video player for ${uri.host}${uri.path} '
        '(signed query: ${uri.hasQuery})',
      );
      final controller = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: const {'Accept': 'video/mp4,video/*;q=0.9,*/*;q=0.8'},
      );

      _controller = controller;
      await controller.initialize().timeout(const Duration(seconds: 25));
      controller.addListener(_handlePlaybackUpdate);
      if (!mounted) return;
      setState(() {
        _initialized = true;
        _error = null;
      });
      await controller.play();
      _showControls();
    } catch (e) {
      debugPrint('Video initialization failed: $e');
      debugPrint('Video player error: ${_controller?.value.errorDescription}');
      if (!mounted) return;
      setState(() {
        _error =
            'Video could not load. Re-upload this video from admin if it was uploaded before the latest backend deploy.';
        _initialized = false;
      });
    }
  }

  void _handlePlaybackUpdate() {
    final value = _controller?.value;
    final duration = value?.duration ?? Duration.zero;
    final position = value?.position ?? Duration.zero;
    if (value?.isPlaying == true && position > _furthestWatchedPosition) {
      _furthestWatchedPosition = position;
    }
    if (_completionReported ||
        widget.onVideoCompleted == null ||
        value?.isPlaying != true ||
        duration.inMilliseconds <= 0 ||
        position.inMilliseconds * 10 < duration.inMilliseconds * 9) {
      return;
    }

    _completionReported = true;
    unawaited(widget.onVideoCompleted!(_video.id));
  }

  void _showControls() {
    _controlsHideTimer?.cancel();
    if (!_controlsVisible && mounted) setState(() => _controlsVisible = true);
    final playing = _controller?.value.isPlaying == true;
    if (playing) {
      _controlsHideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _controller?.value.isPlaying == true) {
          setState(() => _controlsVisible = false);
        }
      });
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    _showControls();
  }

  Widget _buildLearningControls(VideoPlayerController controller) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final duration = value.duration;
        final position = _seekPreview ?? value.position;
        final durationMs = duration.inMilliseconds;
        final currentFraction = durationMs == 0
            ? 0.0
            : (position.inMilliseconds / durationMs).clamp(0.0, 1.0).toDouble();
        final watchedFraction = durationMs == 0
            ? 0.0
            : (_furthestWatchedPosition.inMilliseconds / durationMs)
                  .clamp(0.0, 1.0)
                  .toDouble();

        return AnimatedOpacity(
          opacity: _controlsVisible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: IgnorePointer(
            ignoring: !_controlsVisible,
            child: SafeArea(
              minimum: const EdgeInsets.all(14),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.78),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: watchedFraction,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: StudentColors.blue,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: currentFraction,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: durationMs == 0
                            ? 0
                            : position.inMilliseconds
                                  .clamp(0, durationMs)
                                  .toDouble(),
                        min: 0,
                        max: durationMs == 0 ? 1 : durationMs.toDouble(),
                        activeColor: Colors.transparent,
                        inactiveColor: Colors.transparent,
                        onChangeStart: (_) => _controlsHideTimer?.cancel(),
                        onChanged: durationMs == 0
                            ? null
                            : (milliseconds) {
                                final requested = Duration(
                                  milliseconds: milliseconds.round(),
                                );
                                final target =
                                    requested > _furthestWatchedPosition
                                    ? _furthestWatchedPosition
                                    : requested;
                                setState(() => _seekPreview = target);
                              },
                        onChangeEnd: durationMs == 0
                            ? null
                            : (milliseconds) => _seekWithinWatched(
                                Duration(milliseconds: milliseconds.round()),
                              ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Rewind 10 seconds',
                            onPressed: _rewindTenSeconds,
                            icon: const Icon(Icons.replay_10_rounded),
                          ),
                          IconButton(
                            tooltip: value.isPlaying ? 'Pause' : 'Play',
                            iconSize: 32,
                            onPressed: _togglePlayback,
                            icon: Icon(
                              value.isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_formatDuration(position)} / ${_formatDuration(duration)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            tooltip: _fullscreen
                                ? 'Exit fullscreen'
                                : 'Fullscreen',
                            onPressed: _toggleFullscreen,
                            icon: Icon(
                              _fullscreen
                                  ? Icons.fullscreen_exit_rounded
                                  : Icons.fullscreen_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _seekWithinWatched(Duration requestedPosition) async {
    final controller = _controller;
    if (controller == null) return;
    final duration = controller.value.duration;
    final allowedMaximum = _furthestWatchedPosition > duration
        ? duration
        : _furthestWatchedPosition;
    final target = requestedPosition > allowedMaximum
        ? allowedMaximum
        : requestedPosition < Duration.zero
        ? Duration.zero
        : requestedPosition;
    await controller.seekTo(target);
    if (mounted) setState(() => _seekPreview = null);
    _showControls();
  }

  Future<void> _rewindTenSeconds() async {
    final position = _controller?.value.position ?? Duration.zero;
    await _seekWithinWatched(position - const Duration(seconds: 10));
  }

  String _formatDuration(Duration value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    final seconds = value.inSeconds.remainder(60);
    return hours > 0
        ? '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}'
        : '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  Future<void> _retryWithFreshVideoUrl() async {
    setState(() {
      _error = null;
      _initialized = false;
    });

    _controller?.removeListener(_handlePlaybackUpdate);
    await _controller?.dispose();
    _controller = null;

    try {
      final refreshedVideo = await widget.refreshVideo(_video.id);
      if (refreshedVideo == null || !refreshedVideo.isFile) {
        throw StateError('Video is no longer available');
      }
      _video = refreshedVideo;
      await _initializeVideo();
    } catch (e) {
      debugPrint('Video URL refresh failed: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Video could not be refreshed. Please try again later.';
      });
    }
  }

  Future<void> _toggleFullscreen() async {
    final next = !_fullscreen;
    setState(() => _fullscreen = next);

    if (next) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    _showControls();
  }

  @override
  void dispose() {
    _controlsHideTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _controller?.removeListener(_handlePlaybackUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    Widget videoSurface(VideoPlayerController controller) {
      final size = controller.value.size;
      final width = size.width == 0 ? 1600.0 : size.width;
      final height = size.height == 0 ? 900.0 : size.height;

      if (_fullscreen) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: width,
              height: height,
              child: VideoPlayer(controller),
            ),
          ),
        );
      }

      return AspectRatio(
        aspectRatio: controller.value.aspectRatio == 0
            ? 16 / 9
            : controller.value.aspectRatio,
        child: VideoPlayer(controller),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _fullscreen
          ? null
          : AppBar(
              backgroundColor: Colors.black,
              title: Text(
                _video.title,
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                if (_initialized)
                  IconButton(
                    tooltip: 'Fullscreen',
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: _toggleFullscreen,
                  ),
              ],
            ),
      body: Stack(
        children: [
          Center(
            child: _error != null
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: StudentEmptyState(
                      icon: Icons.video_file_outlined,
                      title: 'Video unavailable',
                      message: _error!,
                      actionLabel: 'Try again',
                      onAction: _retryWithFreshVideoUrl,
                    ),
                  )
                : _initialized && controller != null
                ? videoSurface(controller)
                : const CircularProgressIndicator(),
          ),
          if (_initialized && controller != null)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _showControls,
                onPanDown: (_) => _showControls(),
              ),
            ),
          if (_initialized && controller != null)
            _buildLearningControls(controller),
        ],
      ),
    );
  }
}
