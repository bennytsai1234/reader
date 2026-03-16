import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/engine/js/query_ttf.dart';


void main() {
  group('QueryTTF Tests', () {
    test('Empty font parsing', () {
      expect(() => QueryTTF(Uint8List(0)), throwsRangeError);
    });

    test('Basic TTF Structure', () {
      // Mock basic TTF header
      final bytes = Uint8List.fromList([
        0, 1, 0, 0, // sfntVersion
        0, 0, // numTables
        0, 0, 0, 0, 0, 0 // binary search header
      ]);
      final q = QueryTTF(bytes);
      expect(q.directorys.isEmpty, true);
    });
  });
}
