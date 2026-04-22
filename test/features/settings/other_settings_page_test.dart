import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inkpage_reader/core/constant/prefer_key.dart';
import 'package:inkpage_reader/features/settings/other_settings_page.dart';
import 'package:inkpage_reader/features/settings/settings_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('OtherSettingsPage uses reader prefs for showAddToShelfAlert', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      PreferKey.showAddToShelfAlert: false,
    });

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsProvider(),
        child: const MaterialApp(home: OtherSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).last).value,
      isFalse,
    );

    await tester.tap(find.text('顯示加入書架提示'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PreferKey.showAddToShelfAlert), isTrue);
  });
}
