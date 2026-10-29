// Temporary sanity harness for the extractor's literal parser on tricky
// source shapes. Run: dart run tool/l10n_test_sample.dart

import 'dart:io';

void main() {
  // Simply run the real tool against lib/ and print its summary; the edge
  // files can then be eyeballed via git diff.
  final result = Process.runSync('dart', ['run', 'tool/l10n_extract.dart'],
      runInShell: true, workingDirectory: Directory.current.path);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
}
