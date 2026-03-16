/// RuleSub - 規則訂閱模型
/// (原 Android data/entities/RuleSub.kt)
class RuleSub {
  int id;
  String name;
  String url;
  int type;
  int customOrder;
  bool autoUpdate;
  int update;

  RuleSub({
    required this.id,
    this.name = '',
    this.url = '',
    this.type = 0,
    this.customOrder = 0,
    this.autoUpdate = false,
    this.update = 0,
  });

  factory RuleSub.fromJson(Map<String, dynamic> json) {
    return RuleSub(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch,
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      type: json['type'] ?? 0,
      customOrder: json['customOrder'] ?? 0,
      autoUpdate: json['autoUpdate'] == 1 || json['autoUpdate'] == true,
      update: json['update'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'customOrder': customOrder,
      'autoUpdate': autoUpdate ? 1 : 0,
      'update': update,
    };
  }
}

