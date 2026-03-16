/// ExploreKind - 探索分類模型
/// (原 Android data/entities/rule/ExploreKind.kt)
class ExploreKind {
  final String title;
  final String? url;

  ExploreKind(this.title, this.url);

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
  };

  factory ExploreKind.fromJson(Map<String, dynamic> json) {
    return ExploreKind(
      json['title'] ?? '',
      json['url'],
    );
  }
}

