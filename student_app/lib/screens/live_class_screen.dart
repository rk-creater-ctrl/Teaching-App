import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as windows_webview;
import '../api/api_client.dart';
import '../models/app_settings.dart';
import '../models/student.dart';
import '../theme/student_ui.dart';

class LiveClassScreen extends StatefulWidget {
  final Student student;
  final AppSettings settings;
  final String? courseId;

  const LiveClassScreen({
    super.key,
    required this.student,
    this.settings = AppSettings.fallback,
    this.courseId,
  });

  @override
  State<LiveClassScreen> createState() => _LiveClassScreenState();
}

class _LiveClassScreenState extends State<LiveClassScreen> {
  bool _loading = true;
  bool _fullscreen = false;
  String? _error;
  WebViewController? _controller;
  windows_webview.WebviewController? _windowsController;
  String? _viewerOrigin;
  String _title = 'Live class';
  String _viewerStatus = 'Connecting';
  bool _controlsVisible = true;
  bool _audioMuted = false;
  bool _handRaised = false;
  bool _chatOpen = false;
  final ValueNotifier<Duration> _elapsed = ValueNotifier(Duration.zero);
  Timer? _elapsedTimer;
  Timer? _controlsTimer;
  Timer? _handTimer;
  Timer? _statusTimer;
  StreamSubscription<windows_webview.LoadingState>? _windowsLoadingSubscription;

  @override
  void initState() {
    super.initState();
    _loadLive();
    _showControls();
  }

  Future<void> _toggleFullscreen() async {
    _showControls();
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
    _stopElapsedTimer();
    _controlsTimer?.cancel();
    _handTimer?.cancel();
    _statusTimer?.cancel();
    _windowsLoadingSubscription?.cancel();
    _elapsed.dispose();
    final windowsController = _windowsController;
    if (windowsController != null) unawaited(windowsController.dispose());
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _loadLive() async {
    _stopElapsedTimer();
    setState(() {
      _loading = true;
      _error = null;
      _viewerStatus = 'Connecting';
    });

    try {
      final api = ApiClient();
      final tokenRes = await api.getInternalLiveViewerToken(
        courseId: widget.courseId,
      );
      final data = tokenRes.data as Map<String, dynamic>;
      final viewerPath = data['viewerUrl'] as String?;
      final title = data['title'] as String?;

      if (viewerPath == null || viewerPath.isEmpty) {
        throw const _LiveViewerException(
          'Session token response was incomplete.',
        );
      }

      final viewerUri = Uri.parse(api.baseUrl).resolve(viewerPath);
      if (_isWindows) {
        final runtimeVersion =
            await windows_webview.WebviewController.getWebViewVersion();
        if (runtimeVersion == null) {
          throw const _LiveViewerException(
            'Windows live viewer requires Microsoft Edge WebView2 Runtime.',
          );
        }

        final previousController = _windowsController;
        if (previousController != null) await previousController.dispose();
        final controller = windows_webview.WebviewController();
        await controller.initialize();
        await _windowsLoadingSubscription?.cancel();
        _windowsController = controller;
        _controller = null;
        _viewerOrigin = viewerUri.origin;
        _windowsLoadingSubscription = controller.loadingState.listen((state) {
          if (state == windows_webview.LoadingState.navigationCompleted) {
            _configureViewerPage();
          }
        });
        await controller.loadUrl(viewerUri.toString());

        if (!mounted) {
          await controller.dispose();
          return;
        }
        setState(() {
          _title = title ?? 'Live class';
          _loading = false;
        });
        await _configureViewerPage();
      } else {
        final controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(onPageFinished: (_) => _configureViewerPage()),
          )
          ..loadRequest(viewerUri);

        if (!mounted) return;
        setState(() {
          _title = title ?? 'Live class';
          _controller = controller;
          _windowsController = null;
          _loading = false;
        });
      }
      _startElapsedTimer();
      _startStatusPolling();
      _showControls();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final message = e.response?.data is Map
          ? e.response?.data['error'] ?? e.response?.data['message']
          : e.response?.data;

      var errorText = 'No internal live class is available right now.';
      if (status == 401) {
        errorText = 'Session token request failed. Please login again.';
      } else if (status == 403) {
        errorText =
            message?.toString() ??
            'Your enrollment is not approved for live class access yet.';
      } else if (status == 404) {
        errorText = 'Live class ended or broadcaster is unavailable.';
      } else {
        errorText = 'Session token request failed. Please try again.';
      }

      if (kDebugMode) {
        debugPrint(
          'Live viewer token request failed (HTTP ${status ?? 'network'}).',
        );
      }
      if (!mounted) return;
      setState(() {
        _error = errorText;
        _loading = false;
      });
    } on _LiveViewerException catch (e) {
      if (kDebugMode) debugPrint('Live viewer setup failed: ${e.message}');
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Live viewer initialization failed (${e.runtimeType}).');
      }
      if (!mounted) return;
      setState(() {
        _error = 'Broadcaster unavailable or the live viewer could not start.';
        _loading = false;
      });
    }
  }

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  windows_webview.WebviewPermissionDecision _windowsPermissionRequested(
    String url,
    windows_webview.WebviewPermissionKind kind,
    bool isUserInitiated,
  ) {
    final requestUri = Uri.tryParse(url);
    if (requestUri != null &&
        (requestUri.scheme == 'http' || requestUri.scheme == 'https') &&
        requestUri.origin == _viewerOrigin) {
      return windows_webview.WebviewPermissionDecision.allow;
    }
    return windows_webview.WebviewPermissionDecision.deny;
  }

  Widget _buildViewer() {
    if (_isWindows) {
      return windows_webview.Webview(
        _windowsController!,
        permissionRequested: _windowsPermissionRequested,
      );
    }
    return WebViewWidget(controller: _controller!);
  }

  static const String _viewerShellScript = r'''
    (() => {
      if (document.getElementById('flutter-live-shell-style')) return true;
      document.body.classList.add('flutter-live-shell');
      const style = document.createElement('style');
      style.id = 'flutter-live-shell-style';
      style.textContent = `
        html, body, .wrap { width: 100%; height: 100%; min-height: 100%; overflow: hidden; background: #020617; }
        .flutter-live-shell header { display: none !important; }
        .flutter-live-shell .stage { display: block; height: 100vh; padding: 0; }
        .flutter-live-shell .classroom { height: 100%; padding: 0; border: 0; border-radius: 0; background: #020617; box-shadow: none; }
        .flutter-live-shell .video-shell { width: 100%; height: 100%; border: 0; border-radius: 0; background: #020617; }
        .flutter-live-shell video { width: 100%; height: 100%; min-height: 0; max-height: none; object-fit: contain; background: #020617; }
        .flutter-live-shell .video-label, .flutter-live-shell .controls { display: none !important; }
        .flutter-live-shell .student-access.visible { position: fixed; z-index: 20; left: 16px; bottom: 94px; width: min(360px, calc(100vw - 32px)); margin: 0; backdrop-filter: blur(16px); }
        .flutter-live-shell .chat { position: fixed; z-index: 30; top: 16px; right: 16px; bottom: 94px; width: min(370px, calc(100vw - 32px)); min-height: 0; border-radius: 18px; transform: translateX(calc(100% + 28px)); opacity: 0; pointer-events: none; transition: transform .22s ease, opacity .22s ease; box-shadow: 0 24px 70px rgba(0,0,0,.48); }
        .flutter-live-shell.flutter-chat-open .chat { transform: translateX(0); opacity: 1; pointer-events: auto; }
        @media (max-width: 700px) {
          .flutter-live-shell .chat { left: 10px; right: 10px; top: 42%; bottom: 88px; width: auto; }
          .flutter-live-shell .student-access.visible { left: 10px; bottom: 88px; width: calc(100vw - 20px); }
        }
      `;
      document.head.appendChild(style);
      return true;
    })();
  ''';

  Future<void> _runViewerScript(String script) async {
    if (_isWindows) {
      await _windowsController?.executeScript(script);
    } else {
      await _controller?.runJavaScript(script);
    }
  }

  Future<Object?> _runViewerScriptForResult(String script) async {
    if (_isWindows) return _windowsController?.executeScript(script);
    return _controller?.runJavaScriptReturningResult(script);
  }

  Future<void> _configureViewerPage() async {
    try {
      await _runViewerScript(_viewerShellScript);
      await _runViewerScript(
        "document.body.classList.toggle('flutter-chat-open', ${_chatOpen ? 'true' : 'false'});",
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Live viewer styling unavailable (${error.runtimeType}).');
      }
    }
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final result = await _runViewerScriptForResult(
          "document.getElementById('status')?.textContent || 'Connecting';",
        );
        if (!mounted || result == null) return;
        final raw = result.toString().replaceAll(RegExp(r'^"|"$'), '');
        final lower = raw.toLowerCase();
        final next = lower.contains('ended') || lower.contains('not active')
            ? 'Class ended'
            : lower.contains('failed') || lower.contains('unable')
            ? 'Connection issue'
            : lower.contains('playing')
            ? 'Live'
            : 'Connecting';
        if (next == _viewerStatus) return;
        setState(() => _viewerStatus = next);
        if (next == 'Class ended') _stopElapsedTimer();
      } catch (_) {
        // Keep the last real status reported by the existing viewer page.
      }
    });
  }

  void _showControls() {
    _controlsTimer?.cancel();
    if (mounted && !_controlsVisible) {
      setState(() => _controlsVisible = true);
    }
    if (_chatOpen) return;
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_chatOpen) setState(() => _controlsVisible = false);
    });
  }

  Future<void> _toggleAudio() async {
    _showControls();
    final next = !_audioMuted;
    setState(() => _audioMuted = next);
    await _runViewerScript(
      "document.getElementById('remoteVideo').muted = ${next ? 'true' : 'false'};",
    );
  }

  Future<void> _raiseHand() async {
    _showControls();
    await _runViewerScript(
      "document.getElementById('raiseHandButton')?.click();",
    );
    _handTimer?.cancel();
    setState(() => _handRaised = true);
    _handTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _handRaised = false);
    });
  }

  Future<void> _toggleChat() async {
    _showControls();
    final next = !_chatOpen;
    setState(() {
      _chatOpen = next;
      _controlsVisible = true;
    });
    await _runViewerScript(
      "document.body.classList.toggle('flutter-chat-open', ${next ? 'true' : 'false'});",
    );
    if (!next) _showControls();
  }

  void _leaveClass() {
    Navigator.of(context).maybePop();
  }

  void _startElapsedTimer() {
    _elapsed.value = Duration.zero;
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsed.value += const Duration(seconds: 1);
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _elapsed.value = Duration.zero;
  }

  String _formatElapsed(Duration value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(value.inHours)}:'
        '${twoDigits(value.inMinutes.remainder(60))}:'
        '${twoDigits(value.inSeconds.remainder(60))}';
  }

  Widget _animatedOverlay({required Widget child}) {
    return AnimatedOpacity(
      opacity: _controlsVisible ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      child: IgnorePointer(ignoring: !_controlsVisible, child: child),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: _animatedOverlay(
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xE60B1120),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 24),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: _leaveClass,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _viewerStatus,
                          style: TextStyle(
                            color: _viewerStatus == 'Connection issue'
                                ? StudentColors.orange
                                : StudentColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: StudentColors.red,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  ValueListenableBuilder<Duration>(
                    valueListenable: _elapsed,
                    builder: (context, elapsed, _) => Text(
                      _formatElapsed(elapsed),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: _animatedOverlay(
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 590),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xEB0B1120),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white12),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 28),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _LiveControlButton(
                    icon: _audioMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    label: _audioMuted ? 'Unmute' : 'Mute',
                    active: _audioMuted,
                    onPressed: _toggleAudio,
                  ),
                  _LiveControlButton(
                    icon: _handRaised
                        ? Icons.pan_tool_rounded
                        : Icons.pan_tool_outlined,
                    label: _handRaised ? 'Raised' : 'Raise hand',
                    active: _handRaised,
                    activeColor: StudentColors.orange,
                    onPressed: _raiseHand,
                  ),
                  _LiveControlButton(
                    icon: _chatOpen
                        ? Icons.chat_rounded
                        : Icons.chat_bubble_outline_rounded,
                    label: 'Chat',
                    active: _chatOpen,
                    activeColor: StudentColors.blue,
                    onPressed: _toggleChat,
                  ),
                  _LiveControlButton(
                    icon: _fullscreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    label: _fullscreen ? 'Exit full' : 'Fullscreen',
                    onPressed: _toggleFullscreen,
                  ),
                  _LiveControlButton(
                    icon: Icons.call_end_rounded,
                    label: 'Leave',
                    active: true,
                    activeColor: StudentColors.red,
                    onPressed: _leaveClass,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoStage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 760;
        return Padding(
          padding: EdgeInsets.all(desktop ? 18 : 7),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1500),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(desktop ? 22 : 14),
                border: Border.all(color: Colors.white10),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 34),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildViewer(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: StudentColors.green),
              SizedBox(height: 18),
              Text(
                'Connecting to live classroom…',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewerReady = !_loading && _error == null;
    return Scaffold(
      backgroundColor: StudentColors.bg,
      body: MouseRegion(
        onHover: (_) => _showControls(),
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _showControls(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_loading)
                _buildLoadingState()
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: StudentEmptyState(
                      icon: Icons.live_tv_outlined,
                      title: 'Live class unavailable',
                      message: _error!,
                      actionLabel: 'Check again',
                      onAction: _loadLive,
                    ),
                  ),
                )
              else
                _buildVideoStage(),
              if (viewerReady) _buildTopBar(),
              if (viewerReady) _buildBottomControls(),
              if (!viewerReady)
                Positioned(
                  top: 0,
                  left: 0,
                  child: SafeArea(
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed: _leaveClass,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveViewerException implements Exception {
  final String message;

  const _LiveViewerException(this.message);
}

class _LiveControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onPressed;

  const _LiveControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
    this.activeColor = StudentColors.green,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : Colors.white;
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: active
                        ? activeColor.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active
                          ? activeColor.withValues(alpha: 0.55)
                          : Colors.white12,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
