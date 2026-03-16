import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';
import 'package:legado_reader/core/models/rule_data_interface.dart';

class MockRuleData extends RuleDataInterface {
  @override
  final Map<String, String> variableMap = {};

  @override
  String getVariable(String key) => variableMap[key] ?? '';

  @override
  void putVariable(String key, String? value) {
    if (value == null) {
      variableMap.remove(key);
    } else {
      variableMap[key] = value;
    }
  }
}

void main() {
  group('AnalyzeRule Tests', () {
    const htmlStr = '''
    <html>
      <body>
        <div class="title">Test Title</div>
        <div class="content">Test Content</div>
      </body>
    </html>
    ''';

    const jsonStr = '''
    {
      "title": "JSON Title",
      "content": "JSON Content"
    }
    ''';

    test('Routing to CSS parser', () {
      final analyzer = AnalyzeRule().setContent(htmlStr);
      expect(analyzer.getString('.title@text'), 'Test Title');
    });

    test('Routing to JsonPath parser', () {
      final analyzer = AnalyzeRule().setContent(jsonStr);
      expect(analyzer.getString(r'$.title'), 'JSON Title');
    });

    test('Routing to XPath parser', () {
      final analyzer = AnalyzeRule().setContent(htmlStr);
      expect(analyzer.getString('//div[@class="title"]/text()'), 'Test Title');
    });

    test('Prefix override @Json:', () {
      // Force JSON mode even if content looks like HTML (though this content IS JSON)
      final analyzer = AnalyzeRule().setContent(jsonStr);
      expect(analyzer.getString(r'@Json:$.title'), 'JSON Title');
    });

    test('Regex replacement ##', () {
      final analyzer = AnalyzeRule().setContent(htmlStr);
      // Replace Title with Header
      expect(analyzer.getString('.title@text##Title##Header'), 'Test Header');
    });

    test('Variables @get and put', () {
      final mockData = MockRuleData();
      final analyzer = AnalyzeRule(ruleData: mockData).setContent(htmlStr);
      
      analyzer.put('myVar', 'Hello');
      expect(analyzer.getString('@get:{myVar}'), 'Hello');
      
      // Test embedded in rule
      expect(analyzer.getString('Prefix: @get:{myVar}'), 'Prefix: Hello');
    });
  });
}
