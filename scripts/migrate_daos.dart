import 'dart:io';

void main() async {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (var file in files) {
    var content = await file.readAsString();
    var changed = false;

    // 1. Replace DAOs: \b\w+Dao\(\) -> getIt<OriginalDaoName>()
    final daoRegex = RegExp(r'\b(\w+Dao)\(\)');
    if (daoRegex.hasMatch(content)) {
      content = content.replaceAllMapped(daoRegex, (match) => 'getIt<${match.group(1)}>()');
      changed = true;
    }

    // 2. Replace AppDatabase.database -> getIt<IsarService>().isar
    if (content.contains('AppDatabase.database')) {
      content = content.replaceAll('AppDatabase.database', 'getIt<IsarService>().isar');
      changed = true;
    }

    if (changed) {
      // 3. Ensure injection import
      if (!content.contains('package:inkpage_reader/core/di/injection.dart')) {
        content = "import 'package:inkpage_reader/core/di/injection.dart';\n$content";
      }

      // 4. Ensure IsarService import if used
      if (content.contains('IsarService') && !content.contains('package:inkpage_reader/core/database/isar_service.dart')) {
        content = "import 'package:inkpage_reader/core/database/isar_service.dart';\n$content";
      }

      await file.writeAsString(content);
      stdout.writeln('Updated ${file.path}');
    }
  }
}
