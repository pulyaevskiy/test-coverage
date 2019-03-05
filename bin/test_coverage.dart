// Copyright (c) 2018, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test_coverage/test_coverage.dart';

Future main(List<String> arguments) async {
  final packageRoot = Directory.current;
  final testFiles = findTestFiles(packageRoot);
  print('Found ${testFiles.length} test files.');
  generateMainScript(packageRoot, testFiles);
  print('Generated test-all script in test/.test_coverage.dart. '
      'Please make sure it is added to .gitignore.');
  await runTestsAndCollect(Directory.current.path).then((_) {
    print('Coverage report saved to "coverage/lcov.info".');
  });
  final lcov = File(path.join(packageRoot.path, 'coverage', 'lcov.info'));
  final lineCoverage = calculateLineCoverage(lcov);
  generateBadge(packageRoot, lineCoverage);
  final coveragePct = (lineCoverage * 100).floor();
  print('Overall line coverage rate: $coveragePct%.');
}
