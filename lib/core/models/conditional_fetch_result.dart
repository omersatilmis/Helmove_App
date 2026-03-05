class ConditionalFetchResult<T> {
  final T? data;
  final String? etag;
  final bool notModified;

  const ConditionalFetchResult({
    required this.data,
    required this.etag,
    required this.notModified,
  });
}
