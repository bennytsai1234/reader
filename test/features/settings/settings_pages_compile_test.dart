import 'package:flutter_test/flutter_test.dart';

import 'package:inkpage_reader/features/about/about_page.dart';
import 'package:inkpage_reader/features/settings/other_settings_page.dart';
import 'package:inkpage_reader/features/settings/settings_page.dart';
import 'package:inkpage_reader/features/settings/tts_settings_page.dart';

void main() {
  test('Settings pages can be constructed', () {
    expect(() => const AboutPage(), returnsNormally);
    expect(() => const OtherSettingsPage(), returnsNormally);
    expect(() => const SettingsPage(), returnsNormally);
    expect(() => const TtsSettingsPage(), returnsNormally);
  });
}
