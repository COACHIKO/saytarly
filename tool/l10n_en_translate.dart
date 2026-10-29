// Merges hand-written English (tool/l10n_en_dict/*.txt, tab-separated: Arabic<TAB>English)
// into lib/l10n/app_en.arb, preserving app_ar.arb key order exactly.
// - Keys with a dictionary hit -> English.
// - Keys with existing non-empty en value (legacy Hatif-era keys) -> kept.
// - Everything else -> Arabic identity (untranslated), logged to the report.
// Validates that every {placeholder} in the Arabic value appears in the English value.
import 'dart:convert';
import 'dart:io';

void main() {
  final arMap =
      jsonDecode(File('lib/l10n/app_ar.arb').readAsStringSync(encoding: utf8))
          as Map<String, dynamic>;
  final enOld = File('lib/l10n/app_en.arb').existsSync()
      ? jsonDecode(
              File('lib/l10n/app_en.arb').readAsStringSync(encoding: utf8))
          as Map<String, dynamic>
      : <String, dynamic>{};

  final dict = <String, String>{};
  final dictDir = Directory('tool/l10n_en_dict');
  final files = dictDir.existsSync()
      ? (dictDir.listSync()..sort((a, b) => a.path.compareTo(b.path)))
          .whereType<File>()
          .where((f) => f.path.endsWith('.txt'))
          .toList()
      : <File>[];
  var dictRows = 0;
  for (final f in files) {
    for (final raw in f.readAsLinesSync(encoding: utf8)) {
      if (raw.isEmpty) continue;
      final parts = raw.split('\t');
      if (parts.length < 2) continue;
      final key = parts[0].replaceAll(RegExp(r'\r$'), '');
      dict[key] = parts.sublist(1).join('\t');
      dictRows++;
    }
  }

  final out = <String, dynamic>{};
  final untranslated = <String>[];
  final dictMisses = <String>[];
  final placeholderViolations = <List<String>>[];
  var dictHits = 0, legacyKept = 0, identity = 0, schema = 0;

  arMap.forEach((key, arValue) {
    if (key == '@@locale') {
      out[key] = 'en';
      return;
    }
    if (key.startsWith('@')) {
      out[key] = arValue;
      schema++;
      return;
    }
    final ar = arValue.toString();
    String en;
    if (dict.containsKey(key)) {
      en = dict[key]!;
      dictHits++;
    } else {
      final existing = enOld[key]?.toString();
      if (existing != null && existing.trim().isNotEmpty) {
        en = existing;
        legacyKept++;
      } else {
        en = ar; // identity fallback (untranslated / SQL / HTML)
        identity++;
        untranslated.add(key);
      }
    }
    // placeholder validation: ar tokens must all appear in en
    final arTokens = RegExp(r'\{([^{}]+)\}').allMatches(ar).map((m) => m[1]).toSet();
    final missing =
        arTokens.where((t) => !en.contains('{$t}')).toList(growable: false);
    if (missing.isNotEmpty) {
      placeholderViolations.add([key, missing.join(', ')]);
    }
    out[key] = en;
  });

  for (final k in dict.keys) {
    if (!arMap.containsKey(k)) dictMisses.add(k);
  }

  const encoder = JsonEncoder.withIndent('  ');
  File('lib/l10n/app_en.arb')
      .writeAsStringSync(encoder.convert(out) + '\n', encoding: utf8);

  final report = {
    'dictFiles': files.map((f) => f.path).toList(),
    'dictRows': dictRows,
    'dictHits': dictHits,
    'legacyKept': legacyKept,
    'identityFallbacks': identity,
    'schemaRows': schema,
    'total': arMap.length,
    'untranslatedKeys': untranslated,
    'dictMisses': dictMisses,
    'placeholderViolations': placeholderViolations,
  };
  File('build/l10n_en_translate_report.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(report) + '\n',
      encoding: utf8);
  stdout.writeln(
      'dictRows=$dictRows dictHits=$dictHits legacyKept=$legacyKept identity=$identity schema=$schema total=${arMap.length} misses=${dictMisses.length} values=${placeholderViolations.length}');
}
