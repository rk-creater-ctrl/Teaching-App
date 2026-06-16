class AppSettings {
  static const fixedBrandName = 'SR EduNova';
  static const defaultInstituteName = 'Your Institute Name';

  final String brandName;
  final String instituteName;
  final String logoUrl;

  const AppSettings({
    this.brandName = fixedBrandName,
    required this.instituteName,
    required this.logoUrl,
  });

  static const fallback = AppSettings(
    brandName: fixedBrandName,
    instituteName: defaultInstituteName,
    logoUrl: '',
  );

  static String _legacyInstituteName(String value) {
    final name = value.trim();
    final normalized = name.toLowerCase();
    final previousBrandName = ['tech', 'jaguar'].join();

    if (name.isEmpty ||
        normalized == fixedBrandName.toLowerCase() ||
        normalized == previousBrandName) {
      return '';
    }

    return name;
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final rawInstituteName = '${json['instituteName'] ?? ''}'.trim();
    final legacyAppName = '${json['appName'] ?? ''}'.trim();
    final instituteName = rawInstituteName.isEmpty
        ? _legacyInstituteName(legacyAppName)
        : rawInstituteName;
    final logoUrl = '${json['logoUrl'] ?? ''}'.trim();

    return AppSettings(
      brandName: fixedBrandName,
      instituteName:
          instituteName.isEmpty ? fallback.instituteName : instituteName,
      logoUrl: logoUrl,
    );
  }

  String? resolvedLogoUrl(String baseUrl) {
    if (logoUrl.isEmpty) return null;
    if (logoUrl.startsWith('http')) return logoUrl;
    return '$baseUrl/${logoUrl.replaceFirst(RegExp(r'^/+'), '')}';
  }
}
