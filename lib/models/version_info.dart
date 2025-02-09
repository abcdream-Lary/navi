class VersionInfo {
  final String version;
  final String releaseNotes;
  final Map<String, String> downloadUrls;

  VersionInfo({
    required this.version,
    required this.releaseNotes,
    required this.downloadUrls,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      version: json['version'] as String,
      releaseNotes: json['releaseNotes'] as String,
      downloadUrls: Map<String, String>.from(json['downloadUrls'] as Map),
    );
  }
}
