import 'package:legado_reader/core/services/chinese_utils.dart';

class ChineseTextConverter {
  const ChineseTextConverter();

  Future<String> convert(
    String text, {
    required int convertType,
  }) async {
    if (text.isEmpty || convertType == 0) return text;
    if (convertType == 1) {
      return ChineseUtils.s2t(text);
    }
    if (convertType == 2) {
      return ChineseUtils.t2s(text);
    }
    return text;
  }
}
