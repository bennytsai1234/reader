import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader_v2/viewport/reader_v2_gesture_layer.dart';

void main() {
  testWidgets('disabling gestures keeps content subtree mounted', (
    tester,
  ) async {
    var initCount = 0;
    var disposeCount = 0;

    Widget build({required bool gesturesEnabled}) {
      return MaterialApp(
        home: ReaderV2GestureLayer(
          gesturesEnabled: gesturesEnabled,
          onTapUp: (_) {},
          child: _Probe(
            onInit: () => initCount += 1,
            onDispose: () => disposeCount += 1,
          ),
        ),
      );
    }

    await tester.pumpWidget(build(gesturesEnabled: true));
    expect(initCount, 1);
    expect(disposeCount, 0);

    await tester.pumpWidget(build(gesturesEnabled: false));
    expect(initCount, 1);
    expect(disposeCount, 0);
  });
}

class _Probe extends StatefulWidget {
  const _Probe({required this.onInit, required this.onDispose});

  final VoidCallback onInit;
  final VoidCallback onDispose;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand();
  }
}
