import 'package:inkpage_reader/core/di/injection.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:inkpage_reader/core/models/dict_rule.dart';
import 'package:inkpage_reader/core/database/dao/dict_rule_dao.dart';

class DictionaryService {
  static final DictionaryService _instance = DictionaryService._internal();
  factory DictionaryService() => _instance;
  DictionaryService._internal();

  final DictRuleDao _dao = getIt<DictRuleDao>();

  /// 執行查詞
  Future<void> lookup(String text) async {
    if (text.isEmpty) return;

    // 優先嘗試自訂啟用的字典規則
    final rules = await _dao.getAll();
    final enabledRule = rules.cast<DictRule?>().firstWhere((r) => r?.enabled == true, orElse: () => null);

    if (enabledRule != null) {
      final url = enabledRule.urlRule.replaceAll('{{key}}', Uri.encodeComponent(text));
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // 後備：使用系統搜尋或線上引擎
    final googleUri = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(googleUri)) {
      await launchUrl(googleUri, mode: LaunchMode.externalApplication);
    }
  }
}

