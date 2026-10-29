// Tool: l10n_fix_const.dart
//
// Post-extraction repair passes:
//  1. Remove the accidentally-inserted messages.dart import from `part of`
//     files (part files cannot carry imports; they inherit the parent's),
//     then ensure the import exists in each part's parent library.
//  2. Structurally strip `const` keywords whose initializer/call contains
//     `.tr(` (a method call is not a constant expression).
//  3. Analyzer-driven loop: run `dart analyze lib --format=machine`, and for
//     constant-ness errors strip the nearest preceding `const`.
//  4. Report residual errors to build/l10n_residual_errors.json.
//
// Usage:  dart run tool/l10n_fix_const.dart

import 'dart:convert';
import 'dart:io';

const kLibDir = 'lib';
const kImportNeedle = 'core/localization/messages.dart';

const kConstantHints = [
  "can't be invoked in constant expressions",
  'constant expression',
  'Invalid constant',
  'must be constant',
  'constant value',
  'non-constant',
];

void main() {
  _fixGetterTerminators();
  _stripAllNeedleImports();
  _fixPartOfFiles();
  _ensureTrImports();
  int stripped = _structuralConstStrip();
  _analyzerLoop();
  stdout.writeln('done. structurally stripped $stripped const modifiers.');
}

// ═══════════════════════════════════════════════════════════════════════════
// 1a. strip previously-inserted import lines (may sit inside block comments)
// ═══════════════════════════════════════════════════════════════════════════

/// Removes needle import lines that are OUT OF PLACE:
///  * inside `part of` files (part files must not declare imports; they
///    inherit the import from their parent library).
/// ACTIVE import lines in regular libraries are KEPT — hand-added imports
/// (e.g. `saytarly.dart` referencing `Str`) must survive every run.
/// Residual copies inside `/* ... */` block comments are understood to be
/// duplicate-file remnants; they are inert comments and left as-is.
void _stripAllNeedleImports() {
  int stripped = 0;
  final files = Directory(kLibDir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) =>
          f.path.endsWith('.dart') &&
          !f.path.contains('generated') &&
          !f.path.endsWith('messages.dart'))
      .toList();

  for (final f in files) {
    final src = f.readAsStringSync();
    if (!src.contains(kImportNeedle)) continue;
    final isPartOf = RegExp(r'^\s*part\s+of\s+', multiLine: true).hasMatch(src);
    if (!isPartOf) continue; // Normal libraries keep their active imports.

    final lines = src.split('\n');
    final kept = <String>[];
    for (final l in lines) {
      final t = l.trimLeft();
      if (t.startsWith('import ') && t.contains(kImportNeedle)) continue;
      kept.add(l);
    }
    if (kept.length != lines.length) {
      f.writeAsStringSync(kept.join('\n'));
      stripped++;
    }
  }
  stdout.writeln('needle import lines stripped (part-of files): $stripped');
}

// ═══════════════════════════════════════════════════════════════════════════
// 1b. missing imports for `.tr(` call sites
// ═══════════════════════════════════════════════════════════════════════════

/// Every file using `.tr(` must see the extension:
///  * plain libraries get the import inserted directly;
///  * `part of` files inherit it from their parent library, so the parent
///    gets the import when any of its parts needs one.
/// Handles both `part of 'x.dart';` and `part of libraryName;` forms.
void _ensureTrImports() {
  final files = Directory(kLibDir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.path)
      .toList()
    ..sort();

  final allContent = <String, String>{
    for (final p in files) _normPath(p): File(p).readAsStringSync(),
  };

  // Resolution helper for `part of libraryName;` — the library file declares
  // `library name;` or is unique in holding `part '<this basename>';`.
  String? resolveNameParent(String partPath, String name) {
    final selfBase = File(partPath).uri.pathSegments.last;
    for (final e in allContent.entries) {
      if (e.value.contains('part of $name;')) continue;
      if (RegExp('\\blibrary\\s+$name\\s*;').hasMatch(e.value) ||
          RegExp("part\\s+'$selfBase';").hasMatch(e.value)) {
        return e.key;
      }
    }
    return null;
  }

  final applied = <String, String>{}; // path -> patched source (lazy)
  final notes = <String>[];

  String src(String path) => applied[path] ?? allContent[path] ?? '';

  void patch(String path) {
    var s = src(path);
    if (s.isEmpty) {
      notes.add('parent content not found: $path');
      return;
    }
    final alreadyImportsMessages =
        RegExp(r'''import\s+['"][^'"]*messages\.dart['"]''').hasMatch(s);
    if (!alreadyImportsMessages) {
      s = _insertImport(
          s, "import 'package:saytarly/core/localization/messages.dart';");
      applied[path] = s;
    }
  }

  allContent.forEach((path, content) {
    // Files needing the import: `.tr(` extension users AND direct `Str.`
    // references (e.g. saytarly.dart uses `Str.supportedLocales` without any
    // `.tr(` call).
    final needsImport =
        content.contains('.tr(') || RegExp(r'\bStr\.').hasMatch(content);
    if (!needsImport) return;
    // The runtime defining `Str`/`.tr` must never import itself; same for the
    // generated map module.
    final baseName = path.split(RegExp(r'[\\/]')).last;
    if (baseName == 'messages.dart' || baseName == 'app_messages.dart') {
      return;
    }
    if (path.contains('generated')) return;

    if (RegExp(r'^\s*part\s+of\s', multiLine: true).hasMatch(content)) {
      String? parentPath;
      final q = RegExp(r"^part\s+of\s+'([^']+)';", multiLine: true)
          .firstMatch(content);
      if (q != null) {
        final rel = q.group(1)!;
        final dir = File(path).parent.path;
        parentPath = _normPath('$dir${Platform.pathSeparator}$rel');
        if (!File(parentPath).existsSync()) parentPath = null;
      } else {
        final name = RegExp(r'^part\s+of\s+(\w+)\s*;', multiLine: true)
            .firstMatch(content)
            ?.group(1);
        if (name != null) parentPath = resolveNameParent(path, name);
      }
      if (parentPath == null) {
        notes.add('unresolved part parent: $path');
        return;
      }
      patch(parentPath);
      return;
    }

    // Plain library — insert directly.
    patch(path);
  });

  applied.forEach((path, s) => File(path).writeAsStringSync(s));

  stdout.writeln(
      'import pass: patched ${applied.length} libraries; '
      '${allContent.length} files scanned');
  for (final n in notes) {
    stdout.writeln('  note: $n');
  }
}

/// Canonicalises a path's separators and collapses `.`/`..` segments so that
/// computed paths match Directory listing keys exactly.
String _normPath(String path) {
  final parts = path.split(RegExp(r'[\\/]'));
  final out = <String>[];
  final hasRoot = path.startsWith(RegExp(r'\\\\')) ||
      path.startsWith('//') ||
      path.startsWith(RegExp(r'[A-Za-z]:[\\/]'));
  String root = '';
  for (final p in parts) {
    if (p.isEmpty) continue;
    if (RegExp(r'^[A-Za-z]:$').hasMatch(p)) {
      root = '$p\\';
      continue;
    }
    if (p == '.') continue;
    if (p == '..') {
      if (out.isNotEmpty) out.removeLast();
      continue;
    }
    out.add(p);
  }
  return (hasRoot ? root : '') + out.join('\\');
}

// ═══════════════════════════════════════════════════════════════════════════
// 1. part-of files
// ═══════════════════════════════════════════════════════════════════════════

void _fixPartOfFiles() {
  int fixed = 0;
  final files = Directory(kLibDir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  for (final f in files) {
    final src = f.readAsStringSync();
    if (!_isPartOf(src) || !src.contains(kImportNeedle)) continue;
    // Remove every inserted import line.
    final lines = src.split('\n');
    final kept = lines.where((l) {
      final t = l.trim();
      return !(t.startsWith('import ') && t.contains(kImportNeedle));
    }).toList();
    f.writeAsStringSync(kept.join('\n'));
    fixed++;

    // Ensure the parent library has the import.
    final parent = _resolveParent(f.path, src);
    if (parent != null) {
      final ps = parent.readAsStringSync();
      final pBase = parent.uri.pathSegments.last;
      final alreadyImports =
          RegExp(r'''import\s+['"][^'"]*messages\.dart['"]''').hasMatch(ps);
      if (!alreadyImports &&
          pBase != 'messages.dart' &&
          pBase != 'app_messages.dart') {
        parent.writeAsStringSync(_insertImport(ps,
            "import 'package:saytarly/core/localization/messages.dart';"));
      }
    }
  }
  stdout.writeln('part-of files cleaned: $fixed');
}

bool _isPartOf(String src) => RegExp(r'^part\s+of\s', multiLine: true).hasMatch(src);

/// Parses `part of 'x.dart';` (relative path form). Returns the parent file,
/// or null when the `part of libraryName;` form is used.
File? _resolveParent(String partPath, String src) {
  final m = RegExp(r"^part\s+of\s+'([^']+)';", multiLine: true).firstMatch(src);
  if (m == null) return null;
  final rel = m.group(1)!;
  final dir = File(partPath).parent.path;
  final parentPath = '$dir${Platform.pathSeparator}$rel';
  final f = File(parentPath);
  return f.existsSync() ? f : null;
}

// ═══════════════════════════════════════════════════════════════════════════
// 1c. missing `;` after `get x => [...]` arrow-bodies
// ═══════════════════════════════════════════════════════════════════════════

/// The extractor's old static-const→getter conversion could eat the trailing
/// `;` of `static List<String> get x => [ ... ];`. A getter whose body is a
/// bracket group MUST be terminated by `;` right after the closing bracket.
/// This pass finds every `get x =>` arrow whose body opens a bracket group
/// and appends the missing `;` after the balanced close (comments skipped).
void _fixGetterTerminators() {
  int fixed = 0;
  final files = Directory(kLibDir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  for (final f in files) {
    final src = f.readAsStringSync();
    var out = src;
    final getRe = RegExp(r'get\s+\w+\s*=>');
    final positions = <int>[];
    for (final m in getRe.allMatches(src)) {
      positions.add(m.start);
    }
    // Fix from the END so earlier offsets stay valid.
    for (int k = positions.length - 1; k >= 0; k--) {
      final srcNow = out;
      int i = positions[k];
      // Advance past `get name =>` + whitespace to the body.
      final arrowMatch = getRe.matchAsPrefix(srcNow, i)!;
      int j = arrowMatch.end;
      while (j < srcNow.length && (_isWs(srcNow[j]) || srcNow[j] == '\n' || srcNow[j] == '\r')) {
        j++;
      }
      if (j >= srcNow.length) continue;
      final opener = srcNow[j];
      if (opener != '(' && opener != '[' && opener != '{') continue;
      final close = _balancedEnd(srcNow, j);
      if (close >= srcNow.length) continue;
      // Skip whitespace (and sibling comment text) after the close bracket.
      int after = close;
      while (after < srcNow.length &&
          (_isWs(srcNow[after]) ||
              (srcNow[after] == '/' && after + 1 < srcNow.length &&
                  (srcNow[after + 1] == '/' || srcNow[after + 1] == '*')))) {
        if (srcNow[after] == '/' && srcNow[after + 1] == '/') {
          while (after < srcNow.length && srcNow[after] != '\n') {
            after++;
          }
        } else if (srcNow[after] == '/' && srcNow[after + 1] == '*') {
          int b = after + 2;
          while (b + 1 < srcNow.length &&
              !(srcNow[b] == '*' && srcNow[b + 1] == '/')) {
            b++;
          }
          after = b + 2;
        } else {
          after++;
        }
      }
      if (after < srcNow.length && srcNow[after] == ';') continue;
      out = '${srcNow.substring(0, close)};${srcNow.substring(close)}';
      fixed++;
    }
    if (out != src) {
      f.writeAsStringSync(out);
    }
  }
  stdout.writeln('getter terminators fixed: $fixed');
}

bool _isWs(String ch) =>
    ch == ' ' || ch == '\t';

String _insertImport(String src, String importLine) {
  final lines = src.split('\n');
  final hasCr = src.contains('\r\n');
  final insert = hasCr ? '$importLine\r' : importLine;

  // Comment-aware scan: a block-commented copy of the file (cafe source has
  // whole-file `/* ... */` copies above the real code) must not absorb the
  // import statement.
  bool inBlock = false;
  int coreAppLast = -1;
  int importsEnd = -1;
  for (int i = 0; i < lines.length; i++) {
    var l = lines[i].trimLeft();
    if (inBlock) {
      final end = l.indexOf('*/');
      if (end >= 0) {
        l = l.substring(end + 2).trimLeft();
        inBlock = false;
      } else {
        continue;
      }
    }
    if (l.startsWith('/*')) {
      final end = l.indexOf('*/', 2);
      if (end == -1) {
        inBlock = true;
        continue;
      }
      l = l.substring(end + 2).trimLeft();
    }
    if (l.startsWith('//') || l.startsWith('*')) continue;
    if (l.isEmpty) continue;
    if (l.startsWith('import ') && l.contains(';')) {
      if (l.contains('package:saytarly/')) coreAppLast = i;
      importsEnd = i;
      continue;
    }
    break;
  }
  final at = coreAppLast >= 0 ? coreAppLast : importsEnd;
  if (at >= 0) {
    lines.insert(at + 1, insert);
  } else {
    lines.insert(0, insert);
  }
  return lines.join('\n');
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. structural const strip
// ═══════════════════════════════════════════════════════════════════════════

/// Strips `const` when the balanced initializer/object it precedes contains
/// `.tr(`. Handles `const Foo(...)`, `const [...]`, `const {...}` and
/// `const name = ...;` declaration forms. Strings and comments are skipped
/// while scanning.
int _structuralConstStrip() {
  int total = 0;
  for (int pass = 0; pass < 20; pass++) {
    int strippedThisPass = 0;
    for (final e in Directory(kLibDir).listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final src = e.readAsStringSync();
      if (!src.contains('const')) continue;
      final out = _stripConstsIn(src);
      if (out != src) {
        e.writeAsStringSync(out);
        strippedThisPass++;
      }
    }
    total += strippedThisPass;
    if (strippedThisPass == 0) break;
  }
  return total;
}

String _stripConstsIn(String src) {
  final positions = <int>[];
  int i = 0;
  final n = src.length;
  while (i < n) {
    final ch = src[i];
    if (ch == '/' && i + 1 < n && src[i + 1] == '/') {
      while (i < n && src[i] != '\n') {
        i++;
      }
      continue;
    }
    if (ch == '/' && i + 1 < n && src[i + 1] == '*') {
      int j = i + 2;
      while (j + 1 < n && !(src[j] == '*' && src[j + 1] == '/')) {
        j++;
      }
      i = j + 2;
      continue;
    }
    if (ch == "'") {
      final e = _skipString(src, i);
      if (e == null) return src; // malformed — leave untouched
      i = e;
      continue;
    }
    if (ch == 'c' && _wordAtIs(src, i, 'const')) {
      positions.add(i);
      i += 5;
      continue;
    }
    i++;
  }

  // Evaluate each const from the END so edits don't shift earlier offsets.
  for (int k = positions.length - 1; k >= 0; k--) {
    final start = positions[k];
    if (_shouldStrip(src, start)) {
      if (_isDeclForm(src, start)) {
        // `const T x = '...'.tr();` -> `final T x = ...;`
        src = src.substring(0, start) +
            'final ' +
            src.substring(_constEndStart(src, start));
      } else {
        // `const Foo('...'.tr())` -> `Foo(...)` (drop keyword + blanks)
        int e = start + 5;
        while (e < src.length && (src[e] == ' ' || src[e] == '\t')) {
          e++;
        }
        src = src.substring(0, start) + src.substring(e);
      }
    }
  }
  return src;
}

bool _wordAtIs(String src, int at, String word) {
  if (at > 0) {
    final before = src[at - 1];
    if (before == '_' ||
        (before.codeUnitAt(0) >= 0x61 && before.codeUnitAt(0) <= 0x7A) ||
        (before.codeUnitAt(0) >= 0x41 && before.codeUnitAt(0) <= 0x5A) ||
        (before.codeUnitAt(0) >= 0x30 && before.codeUnitAt(0) <= 0x39)) {
      return false;
    }
  }
  if (!src.startsWith(word, at)) return false;
  final after = at + word.length < src.length ? src[at + word.length] : ' ';
  return after == ' ' || after == '\t' || after == '\n' || after == '\r' || after == '(' || after == '[' || after == '{';
}

/// Reads the UTF-16 identifier starting at [at] (analyzer points at the first
/// character of the undefined identifier).
String _wordAt(String src, int at) {
  int j = at;
  while (j < src.length && _isIdentChar(src[j])) {
    j++;
  }
  return at < j ? src.substring(at, j) : '';
}

/// Next two non-whitespace characters after [from] (fewer at end of file).
/// Used to distinguish `ident = ...` from `ident == ...`.
String _nextTwoNonWs(String src, int from) {
  final buf = StringBuffer();
  int j = from;
  while (j < src.length && buf.length < 2) {
    final ch = src[j];
    if (ch != ' ' && ch != '\t' && ch != '\n' && ch != '\r') {
      buf.write(ch);
    }
    j++;
  }
  return buf.toString();
}

bool _isIdentChar(String ch) {
  final c = ch.codeUnitAt(0);
  return (c >= 0x61 && c <= 0x7A) ||
      (c >= 0x41 && c <= 0x5A) ||
      (c >= 0x30 && c <= 0x39) ||
      c == 0x5F;
}

/// Offset where the const's "subject" begins: right after `const` + ws.
int _constEndStart(String src, int start) {
  int j = start + 5;
  while (j < src.length && (src[j] == ' ' || src[j] == '\t' || src[j] == '\n' || src[j] == '\r')) {
    j++;
  }
  return j;
}

bool _shouldStrip(String src, int start) {
  int j = _constEndStart(src, start);
  final n = src.length;
  if (j >= n) return false;
  final ch = src[j];

  // Find the balanced region for the subject.
  int regionEnd;
  if (ch == '(' || ch == '[' || ch == '{') {
    regionEnd = _balancedEnd(src, j);
  } else {
    // declaration form: `const T name = expr;` / `const x = expr;`
    regionEnd = _declEnd(src, j);
  }
  if (regionEnd <= j) return false;
  final region = src.substring(j, regionEnd);
  return region.contains('.tr(');
}

/// Is the const at [start] a declaration (`const T x = ...;`) rather than a
/// call/list/map form?
bool _isDeclForm(String src, int start) {
  final ch = src[_constEndStart(src, start)];
  return ch != '(' && ch != '[' && ch != '{';
}

/// End offset (exclusive) of the bracket group starting at the opener at
/// [open], skipping strings/comments.
int _balancedEnd(String src, int open) {
  final opener = src[open];
  final closer = switch (opener) { '(' => ')', '[' => ']', _ => '}' };
  int depth = 0;
  final n = src.length;
  int i = open;
  while (i < n) {
    final ch = src[i];
    if (ch == '/' && i + 1 < n && src[i + 1] == '/') {
      while (i < n && src[i] != '\n') {
        i++;
      }
      continue;
    }
    if (ch == '/' && i + 1 < n && src[i + 1] == '*') {
      int j = i + 2;
      while (j + 1 < n && !(src[j] == '*' && src[j + 1] == '/')) {
        j++;
      }
      i = j + 2;
      continue;
    }
    if (ch == "'") {
      final e = _skipString(src, i);
      if (e == null) return n;
      i = e;
      continue;
    }
    if (ch == opener) {
      depth++;
    } else if (ch == closer) {
      depth--;
      if (depth == 0) return i + 1;
    }
    i++;
  }
  return n;
}

/// End offset (exclusive, after the `;`) for a `const ... = ...;` declaration
/// starting at [at].
int _declEnd(String src, int at) {
  final eq = _indexOfEq(src, at);
  if (eq == null) return at;
  return _semicolonEnd(src, eq);
}

int? _indexOfEq(String src, int from) {
  final n = src.length;
  for (int i = from; i < n; i++) {
    if (src[i] == ';' || src[i] == '{') return null; // not a plain decl
    if (src[i] == '=') {
      if (i + 1 < n && src[i + 1] == '>') return null; // => no constants here
      return i;
    }
  }
  return null;
}

int _semicolonEnd(String src, int from) {
  final n = src.length;
  int i = from;
  while (i < n) {
    final ch = src[i];
    if (ch == "'") {
      final e = _skipString(src, i);
      if (e == null) return n;
      i = e;
      continue;
    }
    if (ch == '/' && i + 1 < n && src[i + 1] == '/') {
      while (i < n && src[i] != '\n') {
        i++;
      }
      continue;
    }
    if (ch == '/' && i + 1 < n && src[i + 1] == '*') {
      int j = i + 2;
      while (j + 1 < n && !(src[j] == '*' && src[j + 1] == '/')) {
        j++;
      }
      i = j + 2;
      continue;
    }
    if (ch == ';') return i + 1;
    i++;
  }
  return n;
}

int? _skipString(String src, int start) {
  final quote = src[start];
  final n = src.length;
  int j = start + 1;
  while (j < n) {
    if (src[j] == '\\') {
      j += 2;
      continue;
    }
    if (src[j] == quote) return j + 1;
    j++;
  }
  return null;
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. analyzer loop
// ═══════════════════════════════════════════════════════════════════════════

void _analyzerLoop() {
  for (int iteration = 1; iteration <= 40; iteration++) {
    // Machine output via cmd redirect to avoid PowerShell encoding loss.
    Process.runSync(
        'cmd',
        ['/c', 'dart analyze lib --format=machine > build\\analyze.txt 2>&1'],
        workingDirectory: Directory.current.path);

    final lines = File('build/analyze.txt').readAsLinesSync();
    final errors = lines
        .where((l) => l.startsWith('ERROR'))
        .map(_parseMachine)
        .whereType<Map<String, dynamic>>()
        .toList();

    stdout.writeln('analyze loop #$iteration: ${errors.length} errors total');

    if (errors.isEmpty) {
      _writeResidualReport(lines);
      return;
    }

    bool changed = false;
    final byFile = <String, List<Map<String, dynamic>>>{};
    for (final e in errors) {
      byFile.putIfAbsent(e['file'] as String, () => []).add(e);
    }
    byFile.forEach((path, errs) {
      final f = File(path);
      var src = f.readAsStringSync();

      // const-keyword offsets (string/comment aware).
      final consts = <int>[];
      int i = 0;
      final n = src.length;
      while (i < n) {
        final ch = src[i];
        if (ch == "'") {
          final en = _skipString(src, i);
          if (en == null) break;
          i = en;
          continue;
        }
        if (ch == 'c' && _wordAtIs(src, i, 'const')) {
          consts.add(i);
          i += 5;
          continue;
        }
        i++;
      }

      // Plan edits per error (offsets valid against the live src BEFORE any
      // edit in this file; applied descending below).
      final planned = <({int at, String kind})>[];
      for (final e in errs) {
        final msg = e['msg'] as String;
        final code = e['code'] as String;
        final at = _offsetOf(src, e['line'] as int, e['col'] as int);

        if (kConstantHints.any((h) => msg.contains(h))) {
          int? nearest;
          for (final c in consts) {
            if (c < at) nearest = c;
          }
          if (nearest == null) continue;
          planned.add((
            at: nearest,
            kind: _isDeclForm(src, nearest) ? 'constDecl' : 'constCall',
          ));
          continue;
        }

        if (code == 'EXPECTED_TOKEN' && msg.contains("Expected to find ';'")) {
          // Guard: never insert into an existing `;` run, and never insert
          // onto a closing bracket (that class — e.g. `get x => [...]`
          // missing its terminator — is fixed positionally by
          // _fixGetterTerminators; inserting here would corrupt the list).
          final chAt = at < src.length ? src[at] : '\n';
          final prevCh = at > 0 ? src[at - 1] : ' ';
          if (chAt == ';' || prevCh == ';') continue;
          if (chAt == ')' || chAt == ']' || chAt == '}') continue;
          planned.add((at: at, kind: 'semicolon'));
          continue;
        }

        if (code == 'UNDEFINED_IDENTIFIER') {
          final ident = _wordAt(src, at);
          final before =
              at > 0 ? src[at - 1] : ' ';
          if (ident.isNotEmpty &&
              (before == ' ' || before == '\n' || before == '\r' || before == '\t')) {
            final eq = _nextTwoNonWs(src, at + ident.length);
            if (eq.startsWith('=') && !eq.startsWith('==') && !eq.startsWith('=>')) {
              planned.add((at: at, kind: 'finalPrefix'));
            }
          }
          continue;
        }
      }

      if (planned.isEmpty) return;
      final sorted = [...planned]..sort((a, b) => b.at - a.at);
      var fileSrc = src;
      for (final p in sorted) {
        switch (p.kind) {
          case 'constDecl':
            if (_isDeclForm(fileSrc, p.at)) {
              fileSrc = fileSrc.substring(0, p.at) +
                  'final ' +
                  fileSrc.substring(_constEndStart(fileSrc, p.at));
            } else {
              int en = p.at + 5;
              while (en < fileSrc.length &&
                  (fileSrc[en] == ' ' || fileSrc[en] == '\t')) {
                en++;
              }
              fileSrc = fileSrc.substring(0, p.at) + fileSrc.substring(en);
            }
            break;
          case 'constCall':
            int en = p.at + 5;
            while (en < fileSrc.length &&
                (fileSrc[en] == ' ' || fileSrc[en] == '\t')) {
              en++;
            }
            fileSrc = fileSrc.substring(0, p.at) + fileSrc.substring(en);
            break;
          case 'semicolon':
            fileSrc = fileSrc.substring(0, p.at) + ';' + fileSrc.substring(p.at);
            break;
          case 'finalPrefix':
            fileSrc =
                fileSrc.substring(0, p.at) + 'final ' + fileSrc.substring(p.at);
            break;
        }
      }

      if (fileSrc != src) {
        f.writeAsStringSync(fileSrc);
        changed = true;
        final kinds = planned.map((p) => '${p.kind}@${p.at}').join(', ');
        stdout.writeln('EDIT ${f.path}: [$kinds]');
      }
    });
    if (!changed) {
      _writeResidualReport(lines);
      return;
    }
  }
  final lines = File('build/analyze.txt').readAsLinesSync();
  _writeResidualReport(lines);
}

/// Machine format: ERROR|TYPE|CODE|URI|LINE|COL|LENGTH|MESSAGE...
Map<String, dynamic>? _parseMachine(String line) {
  final parts = line.split('|');
  if (parts.length < 8) return null;
  final uri = Uri.parse(parts[3]);
  String path = uri.isScheme('file') ? uri.toFilePath() : parts[3];
  if (path.startsWith('\\') && path.length > 1 && path[2] != ':') {
    path = path.substring(1);
  }
  return {
    'file': path,
    'code': parts[2],
    'line': int.tryParse(parts[4]) ?? 0,
    'col': int.tryParse(parts[5]) ?? 0,
    'msg': parts.sublist(7).join('|'),
  };
}

void _writeResidualReport(List<String> lines) {
  Directory('build').createSync(recursive: true);
  final output = <Map<String, dynamic>>[];
  for (final l in lines) {
    if (l.startsWith('ERROR') || l.startsWith('WARNING') || l.startsWith('INFO')) {
      final p = _parseMachine(l);
      if (p != null) {
        p.removeWhere((k, v) => k == 'offset');
        output.add(p);
      }
    }
  }
  File('build/l10n_residual_errors.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(output));
  stdout.writeln('residual issues: ${output.length} (build/l10n_residual_errors.json)');
}

/// Converts analyzer line/col into a character offset against [src]. Analyzer
/// columns count UTF-16 code units, matching Dart String indices.
int _offsetOf(String src, int line, int col) {
  int off = 0;
  int ln = 1;
  while (ln < line && off < src.length) {
    final c = src.codeUnitAt(off);
    if (c == 0x0A) ln++;
    off++;
  }
  final end = (off + (col - 1)).clamp(off, src.length);
  return end;
}
