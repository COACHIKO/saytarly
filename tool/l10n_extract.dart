// Tool: l10n_extract.dart
//
// Bulk-extracts hardcoded Arabic string literals from lib/**/*.dart into l10n
// ARB resources and rewrites call sites to `'...'.tr([args])`.
//
// Design:
//  * Source-as-key: the Arabic text (interpolations normalized to {name}) is
//    the lookup key, e.g. 'مرحبا $name يا ${expr}' -> 'مرحبا {name} يا {p1}'.
//  * Identical source text anywhere always maps to the same key (no mapping
//    file needed; code stays readable and reviewable).
//  * Logic-critical contexts are skipped (not replaced) and reported:
//    comparison operands, case labels, ternary else branches, map keys,
//    index expressions, RegExp/pattern args, debug prints, DB query args,
//    already-translated literals (`.tr(`), and nested interpolation strings.
//  * Adjacent string literals ('a' 'b' with Arabic) are rewritten as
//    ('a'.tr() + 'b'.tr()) since adjacency and method calls cannot mix.
//  * `static const X = '...'.tr()` cannot stay const: single-declaration
//    forms are converted to static getters automatically.
//  * Files are rewritten in place; UTF-8 and line endings preserved.
//  * Emits app_ar.arb, app_en.arb (identity seed merged with any existing
//    translations) and lib/core/localization/generated/app_messages.dart.
//
// Idempotent: previously translated call sites are re-registered, not rewrapped.
//
// Usage:  dart run tool/l10n_extract.dart

import 'dart:convert';
import 'dart:io';

const String kLibDir = 'lib';
const String kArbDir = 'lib/l10n';
const String kGenDart = 'lib/core/localization/generated/app_messages.dart';
const String kImportLine =
    "import 'package:saytarly/core/localization/messages.dart';";
const String kImportNeedle = 'core/localization/messages.dart';

// Callee words whose call arguments must never be translated: pattern
// matching, debugging output, raw SQL. Conservative (over-skip is safe).
const Set<String> kSkipCallTargets = {
  'RegExp',
  'RegExpCase',
  'contains',
  'any',
  'every',
  'startsWith',
  'endsWith',
  'indexOf',
  'lastIndexOf',
  'replaceAll',
  'replaceAllMapped',
  'replaceFirst',
  'replaceFirstMapped',
  'split',
  'splitMapJoin',
  'padLeft',
  'padRight',
  'print',
  'debugPrint',
  'log',
  'writeln',
  'write',
  'writeAll',
  'assert',
  'query',
  'rawQuery',
  'execute',
  'rawInsert',
  'rawUpdate',
  'rawDelete',
  'firstMatch',
  'allMatches',
  'hash',
  'fromEnvironment',
};

void main() {
  final files = collectDartFiles();
  final tokensScanned = <_Tok>[];
  int wrappedCount = 0;
  int rewrittenFiles = 0;
  final corpus = <String>{};

  // Merge in keys already present in the arb files (translations from
  // earlier runs must be preserved).
  _mergeExistingArb(corpus);

  final skipped = <Map<String, dynamic>>[];

  for (final path in files) {
    final src = File(path).readAsStringSync();
    final tk = _Tokenizer(src);
    final toks = tk.run();
    tokensScanned.addAll(toks);

    // Report nested-interpolation string literals once (they stay hardcoded
    // and are excluded from chain processing so adjacency stays valid).
    for (final o in tk.orphans) {
      if (o.hasArabic) {
        skipped.add(_skipEntry(path, src, o, 'nested-interpolation'));
      }
    }

    // Group adjacent literals (whitespace-only gap) into chains.
    final chainOf = List<int>.filled(toks.length, -1);
    for (int i = 0; i < toks.length; i++) {
      chainOf[i] = (i > 0 && _gapWhitespaceOnly(src, toks[i - 1].end, toks[i].start))
          ? chainOf[i - 1]
          : i;
    }

    final replacements = <({int start, int end, String text})>[];
    final doneChain = <int>{};

    for (int i = 0; i < toks.length; i++) {
      final tok = toks[i];
      if (!tok.hasArabic) continue;
      // Orphan inner-interpolation strings: skip outright (reported).
      if (tok.orphan) {
        skipped.add(_skipEntry(path, src, tok, 'nested-interpolation'));
        continue;
      }

      final chainStart = _chainStartAt(i, chainOf, toks, src);
      final chainEnd = _chainEndAt(i, chainOf, toks, src);

      if (doneChain.contains(chainStart)) continue;
      doneChain.add(chainStart);

      // A chain is processable only if every Arabic member is non-skipped.
      String? partialReason;
      bool anyAr = false;

      final members = <_Tok>[];
      for (int j = chainStart; j <= chainEnd; j++) {
        members.add(toks[j]);
      }

      final chainParts = <({String text, bool isAr})>[];
      for (final m in members) {
        if (!m.hasArabic) {
          chainParts.add((text: m.raw, isAr: false));
          continue;
        }
        // Already translated?
        if (_followedByTr(src, m.end)) {
          final parsed = _parseLiteral(m.raw, m.isRaw);
          if (parsed != null) corpus.add(parsed.template);
          chainParts.add((text: m.raw, isAr: false)); // leave untouched
          continue;
        }
        final reason = _skipReason(src, m);
        if (reason != null) {
          partialReason = reason;
          break;
        }
        final parsed = _parseLiteral(m.raw, m.isRaw);
        if (parsed == null) {
          partialReason = 'unparseable';
          break;
        }
        anyAr = true;
        corpus.add(parsed.template);
        final literal = _emitDartLiteral(parsed.template);
        final call = parsed.namedArgs.isEmpty
            ? '$literal.tr()'
            : '$literal.tr(${_emitArgsLiteral(parsed.namedArgs)})';
        chainParts.add((text: call, isAr: true));
      }

      if (chainParts.isEmpty || partialReason != null) {
        skipped.add(_skipEntry(path, src, toks[i], partialReason ?? 'unknown'));
        continue;
      }

      final start = members.first.start;
      final end = members.last.end;
      final String text;
      if (chainParts.length == 1) {
        text = chainParts.first.text;
      } else {
        text = '(${chainParts.map((p) => p.text).join(' + ')})';
      }
      if (!anyAr) continue; // nothing to do for this chain
      replacements.add((start: start, end: end, text: text));
      wrappedCount += chainParts.where((p) => p.isAr).length;

      for (final m in members) {
        if (m.hasArabic) {
          final parsed = _parseLiteral(m.raw, m.isRaw);
          if (parsed != null) corpus.add(parsed.template);
        }
      }
    }

    if (replacements.isNotEmpty) {
      var out = _applyReplacements(src, replacements);
      out = _dedupeStaticConstWithTr(out);
      // `part of` bodies cannot carry their own import directives — the
      // parent library must already import messages.dart for .tr() to resolve.
      final isPartFile =
          RegExp(r'^\s*part\s+of\s', multiLine: true).hasMatch(out);
      if (!isPartFile && !out.contains(kImportNeedle)) {
        out = _ensureImport(out);
      }
      File(path).writeAsStringSync(out);
      rewrittenFiles++;
    }
  }

  _writeArbs(corpus);
  _writeMessagesDart(corpus);
  _writeReport(files, rewrittenFiles, wrappedCount, skipped, corpus);

  stdout.writeln('files scanned   : ${files.length}');
  stdout.writeln('files rewritten : $rewrittenFiles');
  stdout.writeln('literals wrapped: $wrappedCount');
  stdout.writeln('literals skipped: ${skipped.length}');
  stdout.writeln('unique messages : ${corpus.length}');
  stdout.writeln('report: build/l10n_report.json (all messages ASCII-safe, inspect via tools)');
}

// ═══════════════════════════════════════════════════════════════════════════
// Tokenizer
// ═══════════════════════════════════════════════════════════════════════════

class _Tok {
  final int start;
  final int end;
  final String raw;
  final bool isRaw;
  final String prevNonWs; // last non-ws char before the token
  final String prevNonWs2; // and the one before it (2-char window)
  final String prevWord; // identifier/keyword directly before (over ws only)
  final String nextNonWs; // first non-ws char after the token
  final String enclosingCall; // callee word of the innermost open '('
  final bool orphan; // string nested inside a template interpolation

  _Tok(this.start, this.end, this.raw, this.isRaw, this.prevNonWs,
      this.prevNonWs2, this.prevWord, this.nextNonWs, this.enclosingCall,
      this.orphan);

  bool get hasArabic => containsArabic(raw);
}

class _Tokenizer {
  final String src;
  final List<_Tok> toks = [];
  final List<_Tok> orphans = []; // strings nested inside interpolations

  // Flow state.
  String _prevNonWs = '';
  String _prevNonWs2 = '';
  String _lastWord = '';
  final List<String> _callStack = []; // callee words pushed at '('

  _Tokenizer(this.src);

  List<_Tok> run() {
    int i = 0;
    final n = src.length;
    while (i < n) {
      final ch = src[i];
      // -------- whitespace --------
      if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r') {
        i++;
        continue;
      }
      // -------- comments --------
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
      // -------- strings --------
      if (ch == 'r' && i + 1 < n && (src[i + 1] == "'" || src[i + 1] == '"')) {
        final end = _scanLit(i + 1, isRaw: true);
        if (end != null) {
          _push(i, end, true);
          _updatePunct(src[i]); // 'r'
          _updatePunct(src[i + 1]); // quote char (already consumed inside)
          i = end;
          continue;
        }
      }
      if (ch == "'" || ch == '"') {
        final end = _scanLit(i, isRaw: false);
        if (end != null) {
          _push(i, end, false);
          _updatePunct(ch);
          i = end;
          continue;
        }
      }
      // -------- identifiers / keywords --------
      if (_isIdentStart(ch)) {
        int j = i;
        while (j < n && _isIdentPart(src[j])) {
          j++;
        }
        _lastWord = src.substring(i, j);
        _updatePunct(ch);
        // mark the rest of the word chars as punct so '… =' windows stay right
        for (int k = i + 1; k < j; k++) {
          _updatePunct(src[k]);
        }
        i = j;
        continue;
      }
      // -------- parens --------
      if (ch == '(') {
        _callStack.add(_lastWord);
        _lastWord = '';
        _updatePunct(ch);
        i++;
        continue;
      }
      if (ch == ')') {
        if (_callStack.isNotEmpty) _callStack.removeLast();
        _lastWord = '';
        _updatePunct(ch);
        i++;
        continue;
      }
      // -------- other punctuation --------
      _updatePunct(ch);
      if (ch != '.') _lastWord = '';
      i++;
    }
    return toks;
  }

  void _updatePunct(String ch) {
    _prevNonWs2 = _prevNonWs;
    _prevNonWs = ch;
  }

  void _push(int start, int end, bool isRaw) {
    final raw = src.substring(start, end);
    final next = _nextNonWsChar(end);
    toks.add(_Tok(
      start,
      end,
      raw,
      isRaw,
      _prevNonWs,
      _prevNonWs2,
      _lastWord,
      next,
      _callStack.isEmpty ? '' : _callStack.last,
      false,
    ));
  }

  String _nextNonWsChar(int from) {
    for (int j = from; j < src.length; j++) {
      final c = src[j];
      if (c != ' ' && c != '\t' && c != '\n' && c != '\r') return c;
    }
    return '\u0000';
  }

  /// Scans a literal starting at the quote position; returns the offset after
  /// the closing quote, or null when a nested unparseable piece was found
  /// (the caller then treats the char as punctuation and moves on). Inner
  /// interpolation strings are RE-scanned and appended as orphan tokens.
  int? _scanLit(int start, {required bool isRaw}) {
    final quote = src[start];
    final bool triple;
    if (_peekIs(start + 1, quote) && _peekIs(start + 2, quote)) {
      triple = true;
    } else {
      triple = false;
    }
    int j = start + (triple ? 3 : 1);
    final n = src.length;
    while (j < n) {
      final ch = src[j];
      if (!isRaw && ch == '\\') {
        j += 2;
        continue;
      }
      if (ch == quote) {
        if (triple) {
          if (j + 2 < n && src[j + 1] == quote && src[j + 2] == quote) {
            return j + 3;
          }
        } else {
          return j + 1;
        }
      }
      if (!isRaw && ch == '\$') {
        if (j + 1 < n && src[j + 1] == '{') {
          final end = _scanTemplate(j + 2, isRaw: isRaw);
          if (end == null) return null;
          j = end;
          continue;
        }
        if (j + 1 < n && _isInterpIdentStart(src[j + 1])) {
          int k = j + 1;
          while (k < n && _isInterpIdentPart(src[k])) {
            k++;
          }
          j = k;
          continue;
        }
      }
      j++;
    }
    return triple ? null : j + 0; // unterminated single-line: bail via no more
  }

  /// Scans `... }` of a `${` template from `start` (char after the brace).
  /// Returns offset after the matching `}` — or null on anomaly. Inner string
  /// literals inside the expression are collected as orphan tokens.
  int? _scanTemplate(int start, {required bool isRaw}) {
    int depth = 1;
    int j = start;
    final n = src.length;
    while (j < n) {
      final ch = src[j];
      if (ch == '/') {
        if (j + 1 < n && src[j + 1] == '/') {
          while (j < n && src[j] != '\n') {
            j++;
          }
          continue;
        }
        if (j + 1 < n && src[j + 1] == '*') {
          int k = j + 2;
          while (k + 1 < n && !(src[k] == '*' && src[k + 1] == '/')) {
            k++;
          }
          j = k + 2;
          continue;
        }
      }
      if (ch == 'r' && j + 1 < n && (src[j + 1] == "'" || src[j + 1] == '"')) {
        final end = _scanInnerLit(j + 1, isRaw: true);
        if (end == null) return null;
        j = end;
        continue;
      }
      if (ch == "'" || ch == '"') {
        final end = _scanInnerLit(j, isRaw: false);
        if (end == null) return null;
        j = end;
        continue;
      }
      if (ch == '{') {
        depth++;
        j++;
        continue;
      }
      if (ch == '}') {
        depth--;
        if (depth == 0) return j + 1;
        j++;
        continue;
      }
      j++;
    }
    return null;
  }

  /// Like [_scanLit] but registers the token as `orphan` (nested).
  int? _scanInnerLit(int start, {required bool isRaw}) {
    int? end = _scanLit(start, isRaw: isRaw);
    if (end == null) return null;
    final endOffset = end;
    final raw = src.substring(start, endOffset);
    orphans.add(_Tok(
      start,
      endOffset,
      raw,
      isRaw,
      '{',
      '{',
      '',
      endOffset < src.length ? src[endOffset] : '\u0000',
      '',
      true,
    ));
    return endOffset;
  }

  bool _peekIs(int i, String ch) =>
      i >= 0 && i < src.length && src[i] == ch;
}

// ═══════════════════════════════════════════════════════════════════════════
// Skip heuristics
// ═══════════════════════════════════════════════════════════════════════════

bool _gapWhitespaceOnly(String src, int from, int to) {
  if (from > to) return false;
  if (from == to) return true; // truly adjacent literals form a chain
  for (int i = from; i < to; i++) {
    final c = src[i];
    if (c != ' ' && c != '\t' && c != '\n' && c != '\r') return false;
  }
  return true;
}

int _chainStartAt(int i, List<int> chainOf, List<_Tok> toks, String src) {
  int s = i;
  while (s > 0 && chainOf[s] == chainOf[s - 1]) {
    s--;
  }
  return s;
}

int _chainEndAt(int i, List<int> chainOf, List<_Tok> toks, String src) {
  int e = i;
  while (e + 1 < toks.length && chainOf[e + 1] == chainOf[e]) {
    e++;
  }
  return e;
}

String? _skipReason(String src, _Tok tok) {
  final pp = tok.prevNonWs;
  final pp2 = tok.prevNonWs2;
  final nc = tok.nextNonWs;

  // `case 'ع':`
  if (tok.prevWord == 'case') return 'case-label';
  // 'a' == x / 'a' != x … and x == 'a'
  if ((pp2 == '=' && pp == '=') || (pp2 == '!' && pp == '=')) {
    return 'comparison-op';
  }
  // Next-side: 'ع' == x
  if (nc == '=' || nc == '!') {
    final t = _nextTwoNonWs(src, tok.end);
    if (t == '==' || t == '!=') return 'comparison-op';
  }
  // ternary else: cond ? 'a' : 'b'
  if (pp == ':') {
    if (!_colonIsLabel(src, tok.start)) return 'ternary-else';
  }
  // map keys / `{'مفتاح': v}` and `{'مفتاح', 'آخر'}` suspect set entries
  if (pp == '{' || pp == ',') {
    if (nc == ':') return 'map-key';
  }
  // index expressions lists['ع']
  if (pp == '[') return 'index-like';
  // call args of pattern/debug/sql functions
  if (tok.enclosingCall.isNotEmpty && kSkipCallTargets.contains(tok.enclosingCall)) {
    return 'call-arg:${tok.enclosingCall}';
  }
  return null;
}

/// Walks back from a token (whose immediate previous non-ws char is `:`) to
/// decide if the colon belongs to a named-argument label (return true) or a
/// ternary/other expression (return false).
bool _colonIsLabel(String src, int tokenStart) {
  // find the colon position: first non-ws char scanning back
  int j = tokenStart - 1;
  while (j >= 0 && (src[j] == ' ' || src[j] == '\t' || src[j] == '\n' || src[j] == '\r')) {
    j--;
  }
  if (j < 0 || src[j] != ':') return false;
  int c = j - 1;
  // skip ws before the colon
  while (c >= 0 && (src[c] == ' ' || src[c] == '\t' || src[c] == '\n' || src[c] == '\r')) {
    c--;
  }
  // the identifier should END at c
  if (c < 0 || !_isIdentPart(src[c])) return false;
  int s = c;
  while (s >= 0 && _isIdentPart(src[s])) {
    s--;
  }
  final pc = s >= 0 ? src[s] : '\n';
  // label identifiers are preceded by whitespace / openers / separators
  if (pc == ' ' || pc == '\t' || pc == '\n' || pc == '\r' || pc == '(' || pc == ',' || pc == '{') {
    // must also be a simple identifier (not e.g. `.foo` — pc would be '.')
    return true;
  }
  return false;
}

String _nextTwoNonWs(String src, int from) {
  final buf = StringBuffer();
  int j = from;
  while (j < src.length && buf.length < 2) {
    final c = src[j];
    if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
      j++;
      continue;
    }
    buf.write(c);
    j++;
  }
  return buf.toString();
}

bool _followedByTr(String src, int end) {
  int i = end;
  while (i < src.length && (src[i] == ' ' || src[i] == '\t' || src[i] == '\n' || src[i] == '\r')) {
    i++;
  }
  return src.startsWith('.tr(', i);
}

Map<String, dynamic> _skipEntry(String path, String src, _Tok tok, String reason) {
  return {
    'file': path.replaceAll('\\', '/'),
    'line': _lineOf(src, tok.start),
    'reason': reason,
  };
}

int _lineOf(String src, int off) {
  int line = 1;
  for (int i = 0; i < off && i < src.length; i++) {
    if (src[i] == '\n') line++;
  }
  return line;
}

// ═══════════════════════════════════════════════════════════════════════════
// Literal parsing: raw -> (template, named args in order)
// ═══════════════════════════════════════════════════════════════════════════

typedef _ArgEntry = ({String name, String expr});

class _Parsed {
  final String template;
  final List<_ArgEntry> namedArgs; // ordered, deduped
  _Parsed(this.template, this.namedArgs);
}

_Parsed? _parseLiteral(String raw, bool isRaw) {
  String content;
  // strip prefix r + quotes
  int i = 0;
  if (raw.startsWith('r') && raw.length > 3) i = 1;
  final quote = raw[i];
  if (quote != "'" && quote != '"') return null;
  final bool triple;
  if (raw.length >= i + 6 && raw[i + 1] == quote && raw[i + 2] == quote) {
    triple = true;
  } else {
    triple = false;
  }
  final qLen = triple ? 3 : 1;
  final endCut = triple ? 3 : 1;
  if (raw.length < i + qLen * 2) return null;
  content = raw.substring(i + qLen, raw.length - endCut);

  final staticBuf = StringBuffer();
  final args = <_ArgEntry>[];
  int k = 0;
  final n = content.length;
  while (k < n) {
    final ch = content[k];
    if (!isRaw && ch == '\\') {
      if (k + 1 < n) {
        final c2 = content[k + 1];
        switch (c2) {
          case 'r':
            staticBuf.write('\r');
            break;
          case 't':
            staticBuf.write('\t');
            break;
          case 'n':
            staticBuf.write('\n');
            break;
          case 'b':
            staticBuf.write('\b');
            break;
          case 'f':
            staticBuf.write('\f');
            break;
          case 'v':
            staticBuf.write('\v');
            break;
          case 'x':
            if (k + 3 < n) {
              final hex = content.substring(k + 2, k + 4);
              final v = int.tryParse(hex, radix: 16);
              if (v != null) {
                staticBuf.writeCharCode(v);
                k += 4;
                continue;
              }
            }
            staticBuf.write('x');
            break;
          case 'u':
            // \uXXXX or \u{XXXXX}
            if (k + 2 < n && content[k + 2] == '{') {
              int e = k + 3;
              String hexs = '';
              while (e < n && content[e] != '}') {
                hexs += content[e];
                e++;
              }
              final v = int.tryParse(hexs, radix: 16);
              if (v != null && hexs.isNotEmpty) {
                staticBuf.write(String.fromCharCode(v));
                k = e + 1;
                continue;
              }
              staticBuf.write('u');
            } else {
              final hex = content.substring(k + 2, k + 6);
              final v = int.tryParse(hex, radix: 16);
              if (v != null) {
                staticBuf.write(String.fromCharCode(v));
                k += 6;
                continue;
              }
              staticBuf.write('u');
            }
            break;
          case '"':
            staticBuf.write('"');
            break;
          case "'":
            staticBuf.write("'");
            break;
          case '\\':
            staticBuf.write('\\');
            break;
          default:
            // \" etc — keep the target char
            staticBuf.write(c2);
        }
        k += 2;
        continue;
      }
      staticBuf.write(ch);
      k++;
      continue;
    }
    if (!isRaw && ch == '\$') {
      if (k + 1 < n && content[k + 1] == '{') {
        int depth = 1;
        int e = k + 2;
        final exprBuf = StringBuffer();
        while (e < n && depth > 0) {
          final c = content[e];
          if (c == '{') {
            depth++;
            exprBuf.write(c);
          } else if (c == '}') {
            depth--;
            if (depth == 0) break;
            exprBuf.write(c);
          } else {
            exprBuf.write(c);
          }
          e++;
        }
        if (depth != 0) return null; // malformed — caller skips
        final placeholder = 'v${args.length + 1}';
        staticBuf.write('{$placeholder}');
        args.add((name: placeholder, expr: exprBuf.toString()));
        k = e + 1;
        continue;
      }
      if (k + 1 < n && _isInterpIdentStart(content[k + 1])) {
        int e = k + 1;
        while (e < n && _isInterpIdentPart(content[e])) {
          e++;
        }
        final name = content.substring(k + 1, e);
        staticBuf.write('{$name}');
        args.add((name: name, expr: name));
        k = e;
        continue;
      }
      staticBuf.write(ch);
      k++;
      continue;
    }
    staticBuf.write(ch);
    k++;
  }

  // Deduplicate named args (same name twice -> keep first).
  final seen = <String>{};
  final deduped = <_ArgEntry>[];
  for (final a in args) {
    if (seen.add(a.name)) deduped.add(a);
  }
  return _Parsed(staticBuf.toString(), deduped);
}

bool _isIdentStart(String ch) {
  final c = ch.codeUnitAt(0);
  return (c >= 0x41 && c <= 0x5A) ||
      (c >= 0x61 && c <= 0x7A) ||
      ch == '_' ||
      ch == '\$';
}

/// Identifier characters for `$ident` interpolations: Dart's
/// IDENTIFIER_NO_DOLLAR — dollars are NOT part of these (a `$` starts a new
/// interpolation instead: `'$a$b'`).
bool _isInterpIdentStart(String ch) {
  final c = ch.codeUnitAt(0);
  return (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A) || ch == '_';
}

bool _isInterpIdentPart(String ch) =>
    _isInterpIdentStart(ch) || (ch != r'$' && _isDigit(ch));

bool _isIdentPart(String ch) => _isIdentStart(ch) || _isDigit(ch);

bool _isDigit(String ch) {
  final c = ch.codeUnitAt(0);
  return c >= 0x30 && c <= 0x39;
}

bool containsArabic(String s) {
  for (int i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if ((c >= 0x0600 && c <= 0x06FF) ||
        (c >= 0x0750 && c <= 0x077F) ||
        (c >= 0x08A0 && c <= 0x08FF) ||
        (c >= 0xFB50 && c <= 0xFDFF) ||
        (c >= 0xFE70 && c <= 0xFEFF)) {
      return true;
    }
  }
  return false;
}

// ═══════════════════════════════════════════════════════════════════════════
// Emit helpers
// ═══════════════════════════════════════════════════════════════════════════

/// Produces a Dart single-quoted literal from the decoded template. Dollar
/// signs are data here, so they must be escaped.
String _emitDartLiteral(String template) {
  final buf = StringBuffer("'");
  for (int i = 0; i < template.length; i++) {
    final ch = template[i];
    switch (ch) {
      case '\\':
        buf.write('\\\\');
        break;
      case "'":
        buf.write("\\'");
        break;
      case '\$':
        buf.write('\\\$');
        break;
      case '\n':
        buf.write('\\n');
        break;
      case '\r':
        buf.write('\\r');
        break;
      case '\t':
        buf.write('\\t');
        break;
      default:
        buf.write(ch);
    }
  }
  buf.write("'");
  return buf.toString();
}

String _emitArgsLiteral(List<_ArgEntry> args) {
  final entries = <String>[];
  for (final a in args) {
    entries.add("'${a.name}': ${a.expr}");
  }
  return '{${entries.join(', ')}}';
}

String _applyReplacements(String src, List<({int start, int end, String text})> reps) {
  final sorted = [...reps]..sort((a, b) => a.start - b.start);
  final buf = StringBuffer();
  int cursor = 0;
  for (final r in sorted) {
    if (r.start < cursor) continue;
    buf.write(src.substring(cursor, r.start));
    buf.write(r.text);
    cursor = r.end;
  }
  buf.write(src.substring(cursor));
  return buf.toString();
}

String _ensureImport(String src) {
  if (src.contains(kImportNeedle)) return src;
  final lines = src.split('\n');
  final hasCr = src.contains('\r\n');

  // Comment-aware: a whole-file `/* ... */` copy must not absorb the import.
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
  final importLine = hasCr ? '$kImportLine\r' : kImportLine;
  final at = coreAppLast >= 0 ? coreAppLast : importsEnd;
  if (at >= 0) {
    lines.insert(at + 1, importLine);
  } else {
    lines.insert(0, importLine);
  }
  return lines.join('\n');
}

// ═══════════════════════════════════════════════════════════════════════════
// static const/final with `.tr(` -> getter conversion
// ═══════════════════════════════════════════════════════════════════════════

/// Converts `static const T name = <expr containing .tr( ... >;` and the
/// `static final` variant into getters so translations are not frozen:
///   static const String x = '...'.tr(); -> static String?->String get x => ...;
/// Handles multiline statements, single-declaration statements only.
String _dedupeStaticConstWithTr(String src) {
  final pattern = RegExp(r'static\s+(const|final)\s+([\w<>,\.\?\s]+?)\s+(\w+)\s*=');
  int searchFrom = 0;
  int guard = 0;
  while (guard++ < 1000) {
    if (searchFrom >= src.length) break;
    final m = pattern.firstMatch(src.substring(searchFrom));
    if (m == null) break;
    final absStart = searchFrom + m.start;
    final semicolon = _statementEnd(src, absStart);
    if (semicolon == null) break;
    final stmt = src.substring(absStart, semicolon);
    if (stmt.contains('.tr(')) {
      final typePart = m.group(2)!.trim();
      final namePart = m.group(3)!;
      final eqIdx = stmt.indexOf('=');
      String rhs = stmt.substring(eqIdx + 1).trim();
      if (rhs.endsWith(';')) rhs = rhs.substring(0, rhs.length - 1);
      final type = (typePart == 'var' || typePart.isEmpty) ? '' : '$typePart ';
      final replacement = 'static ${type}get $namePart => $rhs;';
      src = src.substring(0, absStart) + replacement + src.substring(semicolon);
      searchFrom = absStart + replacement.length;
    } else {
      searchFrom = semicolon;
    }
  }
  return src;
}

/// Offset just AFTER the terminating semicolon of the statement starting at
/// [start], skipping strings/comments.
int? _statementEnd(String src, int start) {
  int i = start;
  final n = src.length;
  while (i < n) {
    final ch = src[i];
    if (ch == "'") {
      final e = _skipDartString(src, i);
      if (e == null) return null;
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
  return null;
}

int? _skipDartString(String src, int start) {
  final quote = src[start];
  final triple = start + 2 < src.length && src[start + 1] == quote && src[start + 2] == quote;
  final n = src.length;
  int j = start + (triple ? 3 : 1);
  while (j < n) {
    final ch = src[j];
    if (ch == '\\') {
      j += 2;
      continue;
    }
    if (ch == quote) {
      if (triple) {
        if (j + 2 < n && src[j + 1] == quote && src[j + 2] == quote) {
          return j + 3;
        }
      } else {
        return j + 1;
      }
    }
    j++;
  }
  return null;
}

// ═══════════════════════════════════════════════════════════════════════════
// File collection
// ═══════════════════════════════════════════════════════════════════════════

List<String> collectDartFiles() {
  final out = <String>[];
  for (final e in Directory(kLibDir).listSync(recursive: true)) {
    if (e is! File) continue;
    final p = e.path.replaceAll('\\', '/');
    if (!p.endsWith('.dart')) continue;
    if (p.contains('/generated/')) continue; // gen-l10n + pack output
    if (p.startsWith('$kArbDir/')) continue;
    out.add(e.path);
  }
  out.sort();
  return out;
}

// ═══════════════════════════════════════════════════════════════════════════
// ARB / messages.dart emission
// ═══════════════════════════════════════════════════════════════════════════

/// Reads lib/l10n/app_ar.arb / app_en.arb and adds their keys to [corpus];
/// returns per-locale values from any previous run so translations survive.
void _mergeExistingArb(Set<String> corpus) {
  for (final name in const ['app_ar.arb', 'app_en.arb']) {
    final f = File('$kArbDir/$name');
    if (f.existsSync()) {
      try {
        final map = json.decode(f.readAsStringSync()) as Map<String, dynamic>;
        for (final key in map.keys) {
          if (key.startsWith('@@')) continue;
          corpus.add(key);
        }
      } catch (_) {
        // stale/unreadable — replaced wholesale below
      }
    }
  }
}

void _writeArbs(Set<String> corpus) {
  Directory(kArbDir).createSync(recursive: true);
  // IMPORTANT: previous hand-translated values for app_en.arb are merged in
  // (see _mergeExistingArb for keys; values live in the old file).
  Map<String, String> oldEn = const {};
  Map<String, String> oldAr = const {};
  final en = File('$kArbDir/app_en.arb');
  if (en.existsSync()) {
    try {
      final m = json.decode(en.readAsStringSync()) as Map<String, dynamic>;
      oldEn = m.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    } catch (_) {}
  }
  final ar = File('$kArbDir/app_ar.arb');
  if (ar.existsSync()) {
    try {
      final m = json.decode(ar.readAsStringSync()) as Map<String, dynamic>;
      oldAr = m.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    } catch (_) {}
  }

  final sorted = corpus.toList()..sort();

  final arbAr = StringBuffer();
  arbAr.writeln('{');
  arbAr.writeln('  "@@locale": "ar",');
  for (int i = 0; i < sorted.length; i++) {
    final k = sorted[i];
    // Arabic refs its source text unless an older translation refined it.
    final value = (oldAr[k]?.isEmpty ?? true) ? k : oldAr[k]!;
    arbAr.write('  ${json.encode(k)}: ${json.encode(value)}');
    arbAr.writeln(i == sorted.length - 1 ? '' : ',');
  }
  arbAr.writeln('}');
  File('$kArbDir/app_ar.arb').writeAsStringSync(arbAr.toString());

  final arbEn = StringBuffer();
  arbEn.writeln('{');
  arbEn.writeln('  "@@locale": "en",');
  for (int i = 0; i < sorted.length; i++) {
    final k = sorted[i];
    // English is seeded identity; a hand-written translation from a
    // previous run is preserved when present.
    final value = (oldEn[k]?.isEmpty ?? true) ? k : oldEn[k]!;
    arbEn.write('  ${json.encode(k)}: ${json.encode(value)}');
    arbEn.writeln(i == sorted.length - 1 ? '' : ',');
  }
  arbEn.writeln('}');
  File('$kArbDir/app_en.arb').writeAsStringSync(arbEn.toString());
}

void _writeMessagesDart(Set<String> corpus) {
  Directory('lib/core/localization/generated').createSync(recursive: true);
  // Values come from the arb files (including refinements), not raw corpus:
  final arMap = <String, String>{};
  final enMap = <String, String>{};
  try {
    final arArb =
        json.decode(File('$kArbDir/app_ar.arb').readAsStringSync()) as Map<String, dynamic>;
    arArb.forEach((k, v) {
      if (!k.startsWith('@')) arMap[k] = v.toString();
    });
    final enArb =
        json.decode(File('$kArbDir/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
    enArb.forEach((k, v) {
      if (!k.startsWith('@')) enMap[k] = v.toString();
    });
  } catch (_) {}

  final b = StringBuffer();
  b.writeln('// GENERATED FILE — regenerage via `dart run tool/l10n_extract.dart`.');
  b.writeln('// Keys are Arabic source templates; values the translations.');
  b.writeln('');

  b.writeln('const Map<String, String> kMessagesAr = {');
  for (final k in arMap.keys.toList()..sort()) {
    b.writeln('  ${_dartLiteral(k)}: ${_dartLiteral(arMap[k]!)},');
  }
  b.writeln('};');
  b.writeln('');
  b.writeln('const Map<String, String> kMessagesEn = {');
  for (final k in enMap.keys.toList()..sort()) {
    b.writeln('  ${_dartLiteral(k)}: ${_dartLiteral(enMap[k]!)},');
  }
  b.writeln('};');

  File(kGenDart).writeAsStringSync(b.toString());
}

String _dartLiteral(String s) {
  final buf = StringBuffer("'");
  for (int i = 0; i < s.length; i++) {
    final ch = s[i];
    switch (ch) {
      case '\\':
        buf.write('\\\\');
        break;
      case "'":
        buf.write("\\'");
        break;
      case '\$':
        buf.write('\\\$');
        break;
      case '\n':
        buf.write('\\n');
        break;
      case '\r':
        buf.write('\\r');
        break;
      case '\t':
        buf.write('\\t');
        break;
      default:
        buf.write(ch);
    }
  }
  buf.write("'");
  return buf.toString();
}

// ═══════════════════════════════════════════════════════════════════════════
// Reporting (ASCII console output; Arabic content goes to the json file)
// ═══════════════════════════════════════════════════════════════════════════

void _writeReport(List<String> files, int rewrittenFiles, int wrapped,
    List<Map<String, dynamic>> skipped, Set<String> corpus) {
  Directory('build').createSync(recursive: true);
  final report = {
    'generatedAt': DateTime.now().toIso8601String(),
    'filesScanned': files.length,
    'filesRewritten': rewrittenFiles,
    'literalsWrapped': wrapped,
    'skipped': skipped,
    'uniqueMessages': corpus.length,
  };
  File('build/l10n_report.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
}

// Placeholder marker removed.
