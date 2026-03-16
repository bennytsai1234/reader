/// BookSource 的子規則類別定義
class SearchRule {
  String? init, bookList, name, author, kind, wordCount, lastChapter, coverUrl, intro, bookUrl, checkKeyWord;
  SearchRule({this.init, this.bookList, this.name, this.author, this.kind, this.wordCount, this.lastChapter, this.coverUrl, this.intro, this.bookUrl, this.checkKeyWord});
  factory SearchRule.fromJson(Map<String, dynamic> json) => SearchRule(init: json['init'], bookList: json['bookList'], name: json['name'], author: json['author'], kind: json['kind'], wordCount: json['wordCount'], lastChapter: json['lastChapter'], coverUrl: json['coverUrl'], intro: json['intro'], bookUrl: json['bookUrl'], checkKeyWord: json['checkKeyWord']);
  Map<String, dynamic> toJson() => {'init': init, 'bookList': bookList, 'name': name, 'author': author, 'kind': kind, 'wordCount': wordCount, 'lastChapter': lastChapter, 'coverUrl': coverUrl, 'intro': intro, 'bookUrl': bookUrl, 'checkKeyWord': checkKeyWord};
}

class ExploreRule {
  String? init, bookList, name, author, kind, wordCount, lastChapter, coverUrl, intro, bookUrl;
  ExploreRule({this.init, this.bookList, this.name, this.author, this.kind, this.wordCount, this.lastChapter, this.coverUrl, this.intro, this.bookUrl});
  factory ExploreRule.fromJson(Map<String, dynamic> json) => ExploreRule(init: json['init'], bookList: json['bookList'], name: json['name'], author: json['author'], kind: json['kind'], wordCount: json['wordCount'], lastChapter: json['lastChapter'], coverUrl: json['coverUrl'], intro: json['intro'], bookUrl: json['bookUrl']);
  Map<String, dynamic> toJson() => {'init': init, 'bookList': bookList, 'name': name, 'author': author, 'kind': kind, 'wordCount': wordCount, 'lastChapter': lastChapter, 'coverUrl': coverUrl, 'intro': intro, 'bookUrl': bookUrl};
}

class BookInfoRule {
  String? init, name, author, kind, wordCount, lastChapter, coverUrl, intro, tocUrl;
  bool? canReName;
  BookInfoRule({this.init, this.name, this.author, this.kind, this.wordCount, this.lastChapter, this.coverUrl, this.intro, this.tocUrl, this.canReName});
  factory BookInfoRule.fromJson(Map<String, dynamic> json) => BookInfoRule(init: json['init'], name: json['name'], author: json['author'], kind: json['kind'], wordCount: json['wordCount'], lastChapter: json['lastChapter'], coverUrl: json['coverUrl'], intro: json['intro'], tocUrl: json['tocUrl'], canReName: json['canReName'] == 1 || json['canReName'] == true);
  Map<String, dynamic> toJson() => {'init': init, 'name': name, 'author': author, 'kind': kind, 'wordCount': wordCount, 'lastChapter': lastChapter, 'coverUrl': coverUrl, 'intro': intro, 'tocUrl': tocUrl, 'canReName': canReName};
}

class TocRule {
  String? init, chapterList, chapterName, chapterUrl, isVolume, isVip, isPay, updateTime, nextTocUrl, preUpdateJs;
  String? get nextPage => nextTocUrl;
  set nextPage(String? v) => nextTocUrl = v;

  TocRule({this.init, this.chapterList, this.chapterName, this.chapterUrl, this.isVolume, this.isVip, this.isPay, this.updateTime, this.nextTocUrl, this.preUpdateJs});
  factory TocRule.fromJson(Map<String, dynamic> json) => TocRule(init: json['init'], chapterList: json['chapterList'], chapterName: json['chapterName'], chapterUrl: json['chapterUrl'], isVolume: json['isVolume'], isVip: json['isVip'], isPay: json['isPay'], updateTime: json['updateTime'], nextTocUrl: json['nextTocUrl'] ?? json['nextPage'], preUpdateJs: json['preUpdateJs']);
  Map<String, dynamic> toJson() => {'init': init, 'chapterList': chapterList, 'chapterName': chapterName, 'chapterUrl': chapterUrl, 'isVolume': isVolume, 'isVip': isVip, 'isPay': isPay, 'updateTime': updateTime, 'nextTocUrl': nextTocUrl, 'preUpdateJs': preUpdateJs};
}

class ContentRule {
  String? init, content, nextContentUrl, webJs, sourceRegex, replaceRegex, imageStyle, imageDecode, payAction;
  String? get nextPage => nextContentUrl;
  set nextPage(String? v) => nextContentUrl = v;
  String? get replace => replaceRegex;
  set replace(String? v) => replaceRegex = v;

  ContentRule({this.init, this.content, this.nextContentUrl, this.webJs, this.sourceRegex, this.replaceRegex, this.imageStyle, this.imageDecode, this.payAction});
  factory ContentRule.fromJson(Map<String, dynamic> json) => ContentRule(init: json['init'], content: json['content'], nextContentUrl: json['nextContentUrl'] ?? json['nextPage'], webJs: json['webJs'], sourceRegex: json['sourceRegex'], replaceRegex: json['replaceRegex'] ?? json['replace'], imageStyle: json['imageStyle'], imageDecode: json['imageDecode'], payAction: json['payAction']);
  Map<String, dynamic> toJson() => {'init': init, 'content': content, 'nextContentUrl': nextContentUrl, 'webJs': webJs, 'sourceRegex': sourceRegex, 'replaceRegex': replaceRegex, 'imageStyle': imageStyle, 'imageDecode': imageDecode, 'payAction': payAction};
}

class ReviewRule {
  String? reviewUrl, avatarRule, contentRule, postTimeRule, reviewQuoteUrl, voteUpUrl, voteDownUrl, postReviewUrl, postQuoteUrl, deleteUrl;
  ReviewRule({this.reviewUrl, this.avatarRule, this.contentRule, this.postTimeRule, this.reviewQuoteUrl, this.voteUpUrl, this.voteDownUrl, this.postReviewUrl, this.postQuoteUrl, this.deleteUrl});
  factory ReviewRule.fromJson(Map<String, dynamic> json) => ReviewRule(reviewUrl: json['reviewUrl'], avatarRule: json['avatarRule'], contentRule: json['contentRule'], postTimeRule: json['postTimeRule'], reviewQuoteUrl: json['reviewQuoteUrl'], voteUpUrl: json['voteUpUrl'], voteDownUrl: json['voteDownUrl'], postReviewUrl: json['postReviewUrl'], postQuoteUrl: json['postQuoteUrl'], deleteUrl: json['deleteUrl']);
  Map<String, dynamic> toJson() => {'reviewUrl': reviewUrl, 'avatarRule': avatarRule, 'contentRule': contentRule, 'postTimeRule': postTimeRule, 'reviewQuoteUrl': reviewQuoteUrl, 'voteUpUrl': voteUpUrl, 'voteDownUrl': voteDownUrl, 'postReviewUrl': postReviewUrl, 'postQuoteUrl': postQuoteUrl, 'deleteUrl': deleteUrl};
}

