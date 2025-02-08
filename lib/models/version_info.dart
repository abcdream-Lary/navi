class VersionInfo {
  final String version;
  final String releaseNotes;
  final Map<String, String> downloadUrls;
  final DateTime publishedAt;
  final bool forceUpdate;

  VersionInfo({
    required this.version,
    required this.releaseNotes,
    required this.downloadUrls,
    required this.publishedAt,
    this.forceUpdate = false,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    // 从 release 信息中提取下载链接
    Map<String, String> urls = {};

    // 添加 Release 页面 URL
    urls['releaseUrl'] = json['html_url'] ?? '';

    if (json['assets'] != null) {
      for (var asset in json['assets']) {
        String name = asset['name'] as String;
        if (name.endsWith('.exe') || name.endsWith('.zip')) {
          urls['windows'] = asset['browser_download_url'];
        } else if (name.endsWith('.apk')) {
          urls['android'] = asset['browser_download_url'];
        }
      }
    }

    return VersionInfo(
      version: json['tag_name'].toString().replaceAll('v', ''),
      releaseNotes: json['body'] ?? '',
      downloadUrls: urls,
      publishedAt: DateTime.parse(json['published_at']),
      forceUpdate:
          json['body']?.toString().toLowerCase().contains('[force]') ?? false,
    );
  }
}
