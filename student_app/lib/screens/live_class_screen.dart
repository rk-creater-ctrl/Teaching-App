import 'package:flutter/material.dart';
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
  String? _error;
  WebViewController? _controller;
  String _title = 'Live class';

  @override
  void initState() {
    super.initState();
    _loadLive();
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
    } catch (e) {
      setState(() {
        _error = 'No internal live class is available right now.';
        _loading = false;
      });
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
      ),
      body: _loading
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
    );
  }
}
