class AppSettings {
  final String appName;
  final String logoUrl;

  const AppSettings({
    required this.appName,
    required this.logoUrl,
  });

  static const fallback = AppSettings(
    appName: 'TechJaguar',
    logoUrl: '',
  );

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final appName = '${json['appName'] ?? ''}'.trim();
    final logoUrl = '${json['logoUrl'] ?? ''}'.trim();

    return AppSettings(
      appName: appName.isEmpty ? fallback.appName : appName,
      logoUrl: logoUrl,
    );
  }

  String? resolvedLogoUrl(String baseUrl) {
    if (logoUrl.isEmpty) return null;
    if (logoUrl.startsWith('http')) return logoUrl;
    return '$baseUrl/${logoUrl.replaceFirst(RegExp(r'^/+'), '')}';
  }
}
