// Copyright (c) 2018, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;
import 'package:test_coverage/test_coverage.dart';

Future main(List<String> arguments) async {
  final packageRoot = Directory.current;

  final parser = ArgParser();
  parser.addFlag('help', abbr: 'h', help: 'Show usage', negatable: false);
  parser.addOption(
    'exclude',
    help:
        'Exclude specific files or directories using glob pattern (relative to package root), '
        'e.g. "subdir/*", "**_vm_test.dart".',
  );
  parser.addOption('port',
      abbr: 'p',
      defaultsTo: '8787',
      help: 'Set custom port for Dart Observatory to use when running tests.');

  parser.addFlag(
    'badge',
    help: 'Generate coverage badge SVG image in your package root',
    defaultsTo: true,
    negatable: true,
  );

  parser.addFlag('import-all-source',
      abbr: 'i',
      help:
          'Import all source files for Dart Observatory when running tests.',
      defaultsTo: false,
      negatable: false);

  parser.addOption(
    'import-all-source-exclude',
    help:
        'Exclude specific source files or directories from Dart Observatory using glob pattern (relative to package root), '
        'e.g. "subdir/*", "**_vm.dart".',
  );

  parser.addFlag('print-test-output',
      help: 'Print Test output', defaultsTo: false);

  parser.addOption('min-coverage',
      help: 'Min coverage to pass', defaultsTo: '0');

  final options = parser.parse(arguments);

  if (options.wasParsed('help')) {
    print(parser.usage);
    return;
  }

  Glob excludeGlob;
  if (options['exclude'] is String) {
    excludeGlob = Glob(options['exclude']);
  }

  Glob allSrcExcludeGlob;
  if (options['import-all-source-exclude'] is String) {
    allSrcExcludeGlob = Glob(options['add-all-source-exclude']);
  }

  String port = options['port'];

  final testFiles = findTestFiles(packageRoot, excludeGlob: excludeGlob);
  final srcFiles = options['import-all-source']
      ? findSourceFiles(packageRoot, excludeGlob: allSrcExcludeGlob) 
      : null;

  print('Found ${testFiles.length} test files.');
  generateMainScript(packageRoot, testFiles, sourceFiles: srcFiles);
  print('Generated test-all script in test/.test_coverage.dart. '
      'Please make sure it is added to .gitignore.');
  await runTestsAndCollect(Directory.current.path, port,
          printOutput: options.wasParsed('print-test-output'))
      .then((_) {
    print('Coverage report saved to "coverage/lcov.info".');
  });
  final lcov = File(path.join(packageRoot.path, 'coverage', 'lcov.info'));
  final lineCoverage = calculateLineCoverage(lcov);
  if (options['badge']) generateBadge(packageRoot, lineCoverage);
  final coveragePct = (lineCoverage * 100).floor();
  print('Overall line coverage rate: $coveragePct%.');
  final minCoverage = int.parse(options['min-coverage']);
  if (coveragePct < minCoverage) {
    print(
        'Overall coverage $coveragePct is less than minimum required coverage $minCoverage');
    exit(1);
  }
}
