import 'pagination_metadata.dart';

class PagedResult<T> {
  final List<T> items;
  final PaginationMetadata metadata;

  PagedResult({required this.items, required this.metadata});
}
