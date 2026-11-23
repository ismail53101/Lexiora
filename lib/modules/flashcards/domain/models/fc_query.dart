/// How the card browser orders results.
enum FcSort {
  recent('Recently added'),
  alphabetical('A to Z'),
  due('Due date');

  const FcSort(this.label);
  final String label;
}

/// Which cards the browser lists.
enum FcStatusFilter {
  all('All'),
  newCards('New'),
  learning('Learning'),
  review('Review'),
  suspended('Suspended'),
  starred('Starred'),
  leeches('Leeches');

  const FcStatusFilter(this.label);
  final String label;
}

/// A composable browse/search filter (all fields combine with AND).
class FcCardQuery {
  const FcCardQuery({
    this.deckId,
    this.text = '',
    this.tag,
    this.status = FcStatusFilter.all,
    this.sort = FcSort.recent,
    this.limit = 50,
    this.offset = 0,
  });

  final String? deckId;
  final String text;
  final String? tag;
  final FcStatusFilter status;
  final FcSort sort;
  final int limit;
  final int offset;

  FcCardQuery copyWith({
    String? Function()? deckId,
    String? text,
    String? Function()? tag,
    FcStatusFilter? status,
    FcSort? sort,
    int? limit,
    int? offset,
  }) =>
      FcCardQuery(
        deckId: deckId != null ? deckId() : this.deckId,
        text: text ?? this.text,
        tag: tag != null ? tag() : this.tag,
        status: status ?? this.status,
        sort: sort ?? this.sort,
        limit: limit ?? this.limit,
        offset: offset ?? this.offset,
      );
}
