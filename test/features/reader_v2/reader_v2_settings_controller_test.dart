import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader_v2/features/settings/reader_v2_settings_controller.dart';
import 'package:inkpage_reader/features/reader_v2/layout/reader_v2_layout_constants.dart';

void main() {
  test('readStyleFor does not double-count externally reserved top inset', () {
    final controller = ReaderV2SettingsController();
    const padding = EdgeInsets.only(top: 24, bottom: 16);

    final internal = controller.readStyleFor(padding);
    final external = controller.readStyleFor(
      padding,
      topInfoReservedExternally: true,
    );

    expect(external.paddingTop, kReaderContentTopSpacing);
    expect(
      internal.paddingTop,
      kReaderContentTopSpacing + 24 * kReaderContentTopSafeAreaFactor,
    );
  });
}
