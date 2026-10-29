// Dumps raw untranslated keys (en empty, no newline/tab chars) for hand translation.
// Reads build/l10n_en_compact.json, writes build/l10n_pending.txt (one raw key per line).
import 'dart:convert';
import 'dart:io';

void main() {
  final rows =
      jsonDecode(File('build/l10n_en_compact.json').readAsStringSync()) as List;
  final out = StringBuffer();
  var total = 0, translated = 0, skipped = 0, pending = 0;
  for (final r in rows) {
    total++;
    final key = r[0] as String;
    final en = r[1] as String;
    if (en.isNotEmpty) {
      translated++;
      continue;
    }
    if (key.contains('\n') || key.contains('\r') || key.contains('\t')) {
      skipped++; // multi-line (HTML/SQL docs) -> stays identity in en arb
      continue;
    }
    out.writeln(key);
    pending++;
  }
  File('build/l10n_pending.txt').writeAsStringSync(out.toString());
  stdout.writeln('total=$total translated=$translated skipped=$skipped pending=$pending');
}
