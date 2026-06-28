import 'group_ride_summary.dart';

/// Keşfet araması (POST /search) sayfalı sonucu.
///
/// Backend `meta` zarfını ({page, pageSize, totalCount, hasMore, ...}) taşır.
/// `meta` yoksa (eski backend) data uzunluğundan türetilir → geriye dönük uyumlu.
class GroupRideSearchResult {
  final List<GroupRideSummary> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  const GroupRideSearchResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.hasMore,
  });

  static const empty = GroupRideSearchResult(
    items: [],
    page: 1,
    pageSize: 20,
    totalCount: 0,
    hasMore: false,
  );
}
