// One-off audit: lists pubspec dependencies never imported under lib/ or test/.
import 'dart:io';

const packageNames = <String, String>{};

void main() {
  final pubspec =
      File('pubspec.yaml').readAsStringSync().replaceAll('\r\n', '\n');
  final deps = RegExp(r'dependencies:\n([\s\S]*?)\ndev_dependencies')
      .firstMatch(pubspec)
      ?.group(1);
  final devDeps = RegExp(r'dev_dependencies:\n([\s\S]*?)\n')
      .firstMatch(pubspec)
      ?.group(1);
  final names = <String>[];
  for (final b in [deps, devDeps]) {
    if (b == null) continue;
    for (final line in b.split('\n')) {
      final m =
          RegExp(r'^\s+([a-z_][a-z0-9_]*):').firstMatch('$line\n');
      if (m == null) continue;
      final name = m.group(1)!;
      if (name == 'flutter' ||
          name == 'flutter_localizations' ||
          name == 'flutter_test') continue;
      names.add(name);
    }
  }
  final usage = <String, int>{};
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .toList();
  dartFiles.addAll(Directory('test')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart')));
  dartFiles.addAll(Directory('tool')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart')));
  dartFiles.addAll(Directory('windows/runner')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart')));
  final contents = dartFiles.map((f) {
    try {
      return f.readAsStringSync();
    } catch (_) {
      return '';
    }
  }).join('\n');
  var unused = <String>[];
  for (final n in names.toSet()) {
    final count =
        RegExp('package:$n/').allMatches(contents).length;
    usage[n] = count;
    if (count == 0) unused.add(n);
  }
  stdout.writeln('deps=${names.toSet().length}');
  stdout.writeln('UNUSED: ${unused.join(', ')}');
  for (final e in usage.entries.where((e) => e.value > 0).toList()
    ..sort((a, b) => b.value.compareTo(a.value))) {
    stdout.writeln('${usage[e.key] == null ? "" : e.key}=${e.value > 99 ? 99 : e.value}');
  }
}
