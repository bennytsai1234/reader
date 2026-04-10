/// ExploreKind - 探索分類模型
/// (對標 Android data/entities/rule/ExploreKind.kt)
class ExploreKind {
  final String title;
  final String? url;

  ExploreKind({required this.title, this.url});

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
  };

  factory ExploreKind.fromJson(Map<String, dynamic> json) {
    return ExploreKind(
      title: json['title'] ?? '',
      url: json['url'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExploreKind &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          url == other.url;

  @override
  int get hashCode => title.hashCode ^ url.hashCode;
}
