import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api_client.dart';
import '../models/app_settings.dart';
import '../models/student.dart';
import '../theme/student_ui.dart';

class MaterialItem {
  final String id;
  final String title;
  final String fileUrl;
  final String fileName;
  final String courseTitle;

  MaterialItem({
    required this.id,
    required this.title,
    required this.fileUrl,
    required this.fileName,
    required this.courseTitle,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: '${json['id']}',
      title: '${json['title'] ?? 'Material'}',
      fileUrl: '${json['fileUrl'] ?? ''}',
      fileName: '${json['fileName'] ?? ''}',
      courseTitle: '${json['courseTitle'] ?? ''}',
    );
  }
}

class MaterialsScreen extends StatefulWidget {
  final Student student;
  final AppSettings settings;

  const MaterialsScreen({
    super.key,
    required this.student,
    this.settings = AppSettings.fallback,
  });

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  bool _loading = true;
  String? _error;
  List<MaterialItem> _materials = [];

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiClient().getMaterials(widget.student.id);
      final list = res.data as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _materials = list
            .map((item) => MaterialItem.fromJson(item as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load notes';
        _loading = false;
      });
    }
  }

  Future<void> _openMaterial(MaterialItem material) async {
    final uri = Uri.tryParse(material.fileUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
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
            const Text('Notes', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: _loading
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                StudentSkeletonCard(height: 90),
                StudentSkeletonCard(height: 90),
                StudentSkeletonCard(height: 90),
              ],
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: StudentEmptyState(
                      icon: Icons.picture_as_pdf_outlined,
                      title: 'Notes unavailable',
                      message: _error!,
                      actionLabel: 'Retry',
                      onAction: _loadMaterials,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMaterials,
                  child: _materials.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(20),
                          children: const [
                            StudentEmptyState(
                              icon: Icons.description_outlined,
                              title: 'No notes yet',
                              message: 'Notes and PDFs will appear here after admin uploads them.',
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _materials.length,
                          itemBuilder: (context, index) {
                            final material = _materials[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: studentCardDecoration(),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFF1E293B),
                                  child: Icon(Icons.description_outlined, color: StudentColors.blue),
                                ),
                                title: Text(
                                  material.title,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                                subtitle: Text(
                                  material.courseTitle.isNotEmpty
                                      ? material.courseTitle
                                      : 'General material',
                                  style: const TextStyle(color: StudentColors.muted, fontSize: 12),
                                ),
                                trailing: const Icon(Icons.open_in_new_rounded, color: Colors.white70),
                                onTap: () => _openMaterial(material),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
