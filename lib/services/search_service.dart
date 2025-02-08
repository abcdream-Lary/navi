import '../models/website.dart';

/// 搜索服务类，用于处理网站搜索功能
class SearchService {
  /// 根据搜索关键词筛选网站列表
  ///
  /// [websites] 原始网站列表
  /// [query] 搜索关键词
  /// 返回筛选后的网站列表
  static List<Website> filterWebsites(List<Website> websites, String query) {
    if (query.isEmpty) {
      return websites;
    }

    final lowercaseQuery = query.toLowerCase();
    return websites.where((website) {
      return website.title.toLowerCase().contains(lowercaseQuery) ||
          website.url.toLowerCase().contains(lowercaseQuery) ||
          (website.description?.toLowerCase().contains(lowercaseQuery) ??
              false);
    }).toList();
  }
}
