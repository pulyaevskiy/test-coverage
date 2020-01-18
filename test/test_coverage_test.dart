import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_coverage/test_coverage.dart';

void main() {
  final stubPath = path.join(Directory.current.path, 'test', 'stub_package');
  final stubDir = Directory(stubPath);
  group('findTestFiles', () {
    test('finds only test files', () {
      final result = findTestFiles(stubDir);
      expect(result, hasLength(2));
      final filenames =
          result.map((f) => f.path.split(path.separator).last).toList();
      expect(filenames, contains('a_test.dart'));
      expect(filenames, contains('b_test.dart'));
      expect(filenames, isNot(contains('c.dart')));
    });
  });

  group('smoke test', () {
    final coverageDir = Directory(path.join(stubPath, 'coverage'));
    final savedCurrent = Directory.current;
    final testFile = File(path.join(stubPath, 'test', '.test_coverage.dart'));
    final lcovFile = File(path.join(coverageDir.path, 'lcov.info'));
    final badgeFile = File(path.join(stubPath, 'coverage_badge.svg'));

    setUp(() {
      Process.runSync('pub', ['get'], workingDirectory: stubPath);

      if (testFile.existsSync()) testFile.deleteSync();
      if (coverageDir.existsSync()) coverageDir.deleteSync(recursive: true);
      if (badgeFile.existsSync()) badgeFile.deleteSync();

      // Set working directory for current process because Lcov formatter
      // relies on it to resolve absolute paths for dart files in stub_package.
      Directory.current = stubPath;
    });

    tearDown(() {
      Directory.current = savedCurrent.path;
    });

    test('run', () async {
      final files = findTestFiles(stubDir);
      generateMainScript(stubDir, files);
      expect(testFile.existsSync(), isTrue);
      final content = testFile.readAsStringSync();
      expect(content, contains('a_test.main();'));
      expect(content, contains('nested_b_test.main();'));

      // Set custom port so that when running test_coverage for this test
      // we can start another Observatory for stub_package on the default port.
      await runTestsAndCollect(stubPath, '8585');

      expect(lcovFile.existsSync(), isTrue);

      final coverageValue = calculateLineCoverage(lcovFile);
      expect(coverageValue, 1.0);
      generateBadge(stubDir, coverageValue);

      expect(badgeFile.existsSync(), isTrue);
    });
  });

  group('$TestFileInfo', () {
    test('for file', () {
      final a = File(path.join(stubPath, 'test', 'a_test.dart'));
      final info = TestFileInfo.forFile(a);
      expect(info.alias, 'a_test');
      expect(info.import, "import 'a_test.dart' as a_test;");
      expect(info.testFile, a);
    });

    test('for nested file', () {
      final b = File(path.join(stubPath, 'test', 'nested', 'b_test.dart'));
      final info = TestFileInfo.forFile(b);
      expect(info.alias, 'nested_b_test');
      expect(info.import, "import 'nested/b_test.dart' as nested_b_test;");
      expect(info.testFile, b);
    });
  });
}
