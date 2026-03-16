import 'base_source.dart';

/// RssSource - RSS 來源模型
/// (原 Android data/entities/RssSource.kt)
class RssSource implements BaseSource {
  String sourceUrl;
  String sourceName;
  String sourceIcon;
  String? sourceGroup;
  String? sourceComment;
  bool enabled;
  String? variableComment;
  @override
  String? jsLib;
  @override
  bool enabledCookieJar;
  @override
  String? concurrentRate;
  @override
  String? header;
  @override
  String? loginUrl;
  @override
  String? loginUi;
  String? loginCheckJs;
  String? coverDecodeJs;
  String? sortUrl;
  bool singleUrl;
  int articleStyle;

  String? ruleArticles;
  String? ruleNextPage;
  String? ruleTitle;
  String? rulePubDate;
  String? ruleDescription;
  String? ruleImage;
  String? ruleLink;
  String? ruleContent;
  String? contentWhitelist;
  String? contentBlacklist;

  String? shouldOverrideUrlLoading;
  String? style;
  bool enableJs;
  bool loadWithBaseUrl;
  String? injectJs;

  int lastUpdateTime;
  int customOrder;

  // --- 虛擬欄位 (原 Android 動態查詢) ---
  int unreadCount = 0;

  RssSource({
    required this.sourceUrl,
    this.sourceName = '',
    this.sourceIcon = '',
    this.sourceGroup,
    this.sourceComment,
    this.enabled = true,
    this.variableComment,
    this.jsLib,
    this.enabledCookieJar = true,
    this.concurrentRate,
    this.header,
    this.loginUrl,
    this.loginUi,
    this.loginCheckJs,
    this.coverDecodeJs,
    this.sortUrl,
    this.singleUrl = false,
    this.articleStyle = 0,
    this.ruleArticles,
    this.ruleNextPage,
    this.ruleTitle,
    this.rulePubDate,
    this.ruleDescription,
    this.ruleImage,
    this.ruleLink,
    this.ruleContent,
    this.contentWhitelist,
    this.contentBlacklist,
    this.shouldOverrideUrlLoading,
    this.style,
    this.enableJs = true,
    this.loadWithBaseUrl = true,
    this.injectJs,
    this.lastUpdateTime = 0,
    this.customOrder = 0,
  });

  @override
  String getTag() => sourceName;

  @override
  String getKey() => sourceUrl;

  Map<String, dynamic> toJson() {
    return {
      'sourceUrl': sourceUrl,
      'sourceName': sourceName,
      'sourceIcon': sourceIcon,
      'sourceGroup': sourceGroup,
      'sourceComment': sourceComment,
      'enabled': enabled ? 1 : 0,
      'variableComment': variableComment,
      'jsLib': jsLib,
      'enabledCookieJar': enabledCookieJar ? 1 : 0,
      'concurrentRate': concurrentRate,
      'header': header,
      'loginUrl': loginUrl,
      'loginUi': loginUi,
      'loginCheckJs': loginCheckJs,
      'coverDecodeJs': coverDecodeJs,
      'sortUrl': sortUrl,
      'singleUrl': singleUrl ? 1 : 0,
      'articleStyle': articleStyle,
      'ruleArticles': ruleArticles,
      'ruleNextPage': ruleNextPage,
      'ruleTitle': ruleTitle,
      'rulePubDate': rulePubDate,
      'ruleDescription': ruleDescription,
      'ruleImage': ruleImage,
      'ruleLink': ruleLink,
      'ruleContent': ruleContent,
      'contentWhitelist': contentWhitelist,
      'contentBlacklist': contentBlacklist,
      'shouldOverrideUrlLoading': shouldOverrideUrlLoading,
      'style': style,
      'enableJs': enableJs ? 1 : 0,
      'loadWithBaseUrl': loadWithBaseUrl ? 1 : 0,
      'injectJs': injectJs,
      'lastUpdateTime': lastUpdateTime,
      'customOrder': customOrder,
    };
  }

  factory RssSource.fromJson(Map<String, dynamic> json) {
    return RssSource(
      sourceUrl: json['sourceUrl'] ?? '',
      sourceName: json['sourceName'] ?? '',
      sourceIcon: json['sourceIcon'] ?? '',
      sourceGroup: json['sourceGroup'],
      sourceComment: json['sourceComment'],
      enabled: json['enabled'] == 1 || json['enabled'] == true,
      variableComment: json['variableComment'],
      jsLib: json['jsLib'],
      enabledCookieJar: json['enabledCookieJar'] == 1 || json['enabledCookieJar'] == true,
      concurrentRate: json['concurrentRate'],
      header: json['header'],
      loginUrl: json['loginUrl'],
      loginUi: json['loginUi'],
      loginCheckJs: json['loginCheckJs'],
      coverDecodeJs: json['coverDecodeJs'],
      sortUrl: json['sortUrl'],
      singleUrl: json['singleUrl'] == 1 || json['singleUrl'] == true,
      articleStyle: json['articleStyle'] ?? 0,
      ruleArticles: json['ruleArticles'],
      ruleNextPage: json['ruleNextPage'],
      ruleTitle: json['ruleTitle'],
      rulePubDate: json['rulePubDate'],
      ruleDescription: json['ruleDescription'],
      ruleImage: json['ruleImage'],
      ruleLink: json['ruleLink'],
      ruleContent: json['ruleContent'],
      contentWhitelist: json['contentWhitelist'],
      contentBlacklist: json['contentBlacklist'],
      shouldOverrideUrlLoading: json['shouldOverrideUrlLoading'],
      style: json['style'],
      enableJs: json['enableJs'] == 1 || json['enableJs'] == true,
      loadWithBaseUrl: json['loadWithBaseUrl'] == 1 || json['loadWithBaseUrl'] == true,
      injectJs: json['injectJs'],
      lastUpdateTime: json['lastUpdateTime'] ?? 0,
      customOrder: json['customOrder'] ?? 0,
    );
  }

  // --- 分組操作 (原 Android RssSource.kt) ---
  void addGroup(String groups) {
    final currentGroups = sourceGroup?.split(RegExp(r'[,，\s]+')).where((s) => s.isNotEmpty).toSet() ?? {};
    currentGroups.addAll(groups.split(RegExp(r'[,，\s]+')).where((s) => s.isNotEmpty));
    sourceGroup = currentGroups.join(',');
  }

  void removeGroup(String groups) {
    final currentGroups = sourceGroup?.split(RegExp(r'[,，\s]+')).where((s) => s.isNotEmpty).toSet() ?? {};
    currentGroups.removeAll(groups.split(RegExp(r'[,，\s]+')).where((s) => s.isNotEmpty));
    sourceGroup = currentGroups.isEmpty ? null : currentGroups.join(',');
  }
}

