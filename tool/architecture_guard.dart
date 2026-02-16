import 'dart:io';

void main() {
  final root = Directory('lib/features');
  if (!root.existsSync()) {
    stderr.writeln('architecture_guard: lib/features not found');
    exitCode = 2;
    return;
  }

  final forbidden = <RegExp>[
    RegExp("import\\s+['\"].*signalr_flutter.*['\"]"),
    RegExp("import\\s+['\"].*/data/repositories/.*['\"]"),
    RegExp("import\\s+['\"].*/data/datasources/.*['\"]"),
  ];

  final violations = <String>[];

  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final normalizedPath = entity.path.replaceAll('\\', '/');
    if (!normalizedPath.contains('/presentation/')) continue;

    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (forbidden.any((pattern) => pattern.hasMatch(line))) {
        violations.add('$normalizedPath:${i + 1}: $line');
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln('Architecture guard failed. Forbidden imports in presentation layer:');
    for (final violation in violations) {
      stderr.writeln(' - $violation');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('Architecture guard passed.');
}
