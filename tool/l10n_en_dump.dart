// Compact dump: one JSON array object per row: ["<arabic key>", "<current en>"]
// Meta rows (@@locale etc.) filtered out.
import 'dart:convert';
import 'dart:io';

void main() {
  final ar = jsonDecode(File('lib/l10n/app_ar.arb').readAsStringSync())
      as Map<String, dynamic>;
  final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;
  final rows = <List<String>>[];
  final out = <Map<String, dynamic>>[];
  ar.forEach((key, value) {
    final isMeta = key.startsWith('@@') || key.startsWith('@');
    final curEn = en[key];
    final valueStr = value is String ? value : value.toString();
    if (isMeta) return;
    final curEnStr = curEn is String ? curEn : (curEn?.toString() ?? '');
    rows.add([key, curEnStr]);
    if (key == _htmlKey) return;
    out.add({'ar': valueStr, 'en': curEnStr == valueStr ? '' : curEnStr});
  });
  const encoder = JsonEncoder.withIndent('');
  // compact array entries without indentation inside:
  final buf = StringBuffer('[');
  for (int i = 0; i < out.length; i++) {
    final r = out[i];
    if (i > 0) buf.write(',');
    buf.write('\n["');
    buf.write(_jsonStr(r['ar'] as String));
    buf.write('","');
    buf.write(_jsonStr(r['en'] as String));
    buf.write('"]');
  }
  buf.write('\n]');
  Directory('build').createSync(recursive: true);
  File('build/l10n_en_compact.json').writeAsStringSync(buf.toString());
  stdout.writeln('rows: ${out.length} (compact)');
}

/// Escapes a string for JSON printing (quotes and control chars), keeping
/// Arabic as-is.
String _jsonStr(String s) {
  final b = StringBuffer();
  for (final c in s.codeUnits) {
    switch (c) {
      case 34:
        b.write(r'\"');
        break;
      case 92:
        b.write(r'\\');
        break;
      case 10:
        b.write(r'\n');
        break;
      case 13:
        b.write(r'\r');
        break;
      case 9:
        b.write(r'\t');
        break;
      default:
        if (c < 0x20) {
          b.write('\\u${c.toRadixString(16).padLeft(4, '0')}');
        } else {
          b.write(String.fromCharCode(c));
        }
    }
  }
  return b.toString();
}

final _htmlKey = '\r\n<!DOCTYPE html>';
