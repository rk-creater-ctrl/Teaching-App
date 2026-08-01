import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../api/api_client.dart';
import '../models/app_settings.dart';
import '../models/student.dart';
import '../theme/student_ui.dart';

class LiveClassScreen extends StatefulWidget {
  final Student student;
  final AppSettings settings;

  const LiveClassScreen({
    super.key,
    required this.student,
    this.settings = AppSettings.fallback,
  });

  @override
  State<LiveClassScreen> createState() => _LiveClassScreenState();
}

class _LiveClassScreenState extends State<LiveClassScreen> {
  bool _loading = true;
  bool _fullscreen = false;
  String? _error;
  WebViewController? _controller;
  String _title = 'Live class';

  @override
  void initState() {
    super.initState();
    _loadLive();
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
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _loadLive() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ApiClient();
      final tokenRes = await api.getInternalLiveViewerToken(widget.student.id);
      final data = tokenRes.data as Map<String, dynamic>;
      final viewerPath = data['viewerUrl'] as String?;
      final title = data['title'] as String?;

      if (viewerPath == null || viewerPath.isEmpty) {
        throw Exception('Missing live class viewer URL');
      }

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse('${api.baseUrl}$viewerPath'));

      setState(() {
        _title = title ?? 'Live class';
        _controller = controller;
        _loading = false;
      });
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final message = e.response?.data is Map
          ? e.response?.data['error'] ?? e.response?.data['message']
          : e.response?.data;

      var errorText = 'No internal live class is available right now.';
      if (status == 401) {
        errorText = 'Please login again, then join the live class.';
      } else if (status == 403) {
        errorText =
            message?.toString() ?? 'Your enrollment is not approved for live class access yet.';
      } else if (status == 404) {
        errorText =
            message?.toString() ?? 'Teacher has not started the live class yet.';
      } else if (message != null && message.toString().trim().isNotEmpty) {
        errorText = message.toString();
      }

      setState(() {
        _error = errorText;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to open live class. Please check your internet and try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudentColors.bg,
      appBar: _fullscreen
          ? null
          : AppBar(
              backgroundColor: StudentColors.bg,
              elevation: 0,
              title: Row(
                children: [
                  StudentBrandMark(settings: widget.settings, size: 32, radius: 10),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                if (!_loading && _error == null)
                  IconButton(
                    tooltip: 'Fullscreen',
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: _toggleFullscreen,
                  ),
              ],
            ),
      body: Stack(
        children: [
          _loading
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: const [
                    StudentSkeletonCard(height: 180),
                    StudentSkeletonCard(height: 120),
                  ],
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: StudentEmptyState(
                          icon: Icons.live_tv_outlined,
                          title: 'No live class',
                          message: _error!,
                          actionLabel: 'Check again',
                          onAction: _loadLive,
                        ),
                      ),
                    )
                  : WebViewWidget(controller: _controller!),
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
                    icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                    onPressed: _toggleFullscreen,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
