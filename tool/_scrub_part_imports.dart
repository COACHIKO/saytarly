// One-off: removes tool-added illegal `import .../messages.dart` lines from
// `part of` files (imports live in the parent library instead).
// Preserves the file's existing line endings.
import 'dart:convert';
import 'dart:io';

void main() {
  final needle = "import 'package:saytarly/core/localization/messages.dart';";
  final root = Directory('lib');
  var files = 0, removedLines = 0;
  for (final f in root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))) {
    final src = f.readAsStringSync(encoding: utf8);
    if (!RegExp(r'^\s*part\s+of\s', multiLine: true).hasMatch(src)) continue;
    // Remove the needle only when it occupies a full line.
    final rx = RegExp('${RegExp.escape(needle)}\r?\n');
    final out = src.replaceFirst(rx, '');
    if (out.length != src.length) {
      removedLines++;
      files++;
      f.writeAsStringSync(out, encoding: utf8);
    }
  }
  stdout.writeln('partFilesCleaned=$files importsRemoved=$removedLines');
}
