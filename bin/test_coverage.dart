// Copyright (c) 2018, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;
import 'package:test_coverage/test_coverage.dart';

final String _DEFAULT_COLLECT_LINE_MARK = '[__TEST_COVERAGE__FINISHED__]';
final String _DEFAULT_OPEN_CMD = 'open';

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

  parser.addOption('timeout',
      abbr: 't', help: 'The timeout to run tests (in seconds).');

  parser.addFlag(
    'badge',
    help: 'Generate coverage badge SVG image in your package root',
    defaultsTo: true,
    negatable: true,
  );

  parser.addFlag('print-test-output',
      help: 'Print Test output', defaultsTo: false);

  parser.addFlag('force-collect',
      help:
          'Will collect coverage when a line-mark is printed, avoiding Isolate pause issues.',
      defaultsTo: false);

  parser.addOption('line-mark',
      help:
          'The line mark used by `force-collect` to indicate that tests have been completed and collect can be performed.',
      defaultsTo: _DEFAULT_COLLECT_LINE_MARK);

  parser.addFlag('force-exit-after-collect',
      help: 'Kills tests process after collect coverage.', defaultsTo: false);

  parser.addOption('min-coverage',
      help: 'Min coverage to pass', defaultsTo: '0');

  parser.addFlag('gen-report',
      help: "Generate report HTML, using 'genhtml' command.",
      defaultsTo: false);

  parser.addFlag('open-report', help: 'Opens report at: coverage/index.html');
  parser.addOption('open-cmd',
      help: 'The command to open the report', defaultsTo: _DEFAULT_OPEN_CMD);

  final options = parser.parse(arguments);

  if (options.wasParsed('help')) {
    print(parser.usage);
    return;
  }

  logBreakLine();

  Glob excludeGlob;
  if (options['exclude'] is String) {
    excludeGlob = Glob(options['exclude']);
  }

  var port = options['port'] as String;
  var printTestOutput = options.wasParsed('print-test-output');
  var badge = options['badge'];
  var timeout = options['timeout'];
  var forceCollect = _parseForceCollect(options);
  var forceExitAfterCollect = options['force-exit-after-collect'];
  var genReport = options['gen-report'];
  var openReport = _parseOpenReport(options);
  final minCoverage = int.parse(options['min-coverage']);

  final testFiles = findTestFiles(packageRoot, excludeGlob: excludeGlob);
  logLine('Found ${testFiles.length} test files.');

  generateMainScript(packageRoot, testFiles, forceCollect: forceCollect);
  logLine('Generated test-all script in test/.test_coverage.dart. '
      'Please make sure it is added to .gitignore.');

  Duration timeoutDuration;
  if (timeout != null) {
    timeoutDuration = Duration(seconds: int.tryParse(timeout) ?? 60);
    logLine('Test process timeout: ${timeoutDuration.inSeconds}s');
  }

  await runTestsAndCollect(
    Directory.current.path,
    port,
    printOutput: printTestOutput,
    timeout: timeoutDuration,
    forceCollect: forceCollect,
    forceExitAfterCollect: forceExitAfterCollect,
  ).then((_) {
    logLine('Coverage report saved to "coverage/lcov.info".');
  });

  if (genReport ?? false) {
    var genhtmlPath = await getGenHTMLBinaryPath();
    if (genhtmlPath != null) {
      logLine('Generating HTML report (command: $genhtmlPath)');
      var genResult = await Process.run(
          genhtmlPath, ['coverage/lcov.info', '-o', 'coverage'],
          workingDirectory: Directory.current.path);
      logLine(genResult.stdout, prefix: '>>> -- ');
    } else {
      logLine("Can't find 'genhtml' command! Can't generate report!");
    }
  }

  final lcov = File(path.join(packageRoot.path, 'coverage', 'lcov.info'));
  final lineCoverage = calculateLineCoverage(lcov);

  if (badge) generateBadge(packageRoot, lineCoverage);

  if (openReport != null) {
    var openBin = await findCommandPath(openReport);
    if (openBin != null) {
      var openProcess = await Process.run(openBin, ['coverage/index.html'],
              includeParentEnvironment: true,
              runInShell: true,
              workingDirectory: Directory.current.path)
          .timeout(Duration(seconds: 5));
      logLine(
          'Opened report! cmd: $openBin ; pid: ${openProcess.pid} ; exitCode: ${openProcess.exitCode}');
    } else {
      logLine("Can't open report. Command not found: $openReport");
    }
  }

  final coveragePct = (lineCoverage * 100).floor();
  logLine('Overall line coverage rate: $coveragePct%.');

  if (coveragePct < minCoverage) {
    logLine(
        'Overall coverage $coveragePct is less than minimum required coverage $minCoverage');
    exit(1);
  } else {
    exit(0);
  }
}

String _parseForceCollect(ArgResults options) {
  var forceCollect = options['force-collect'];

  if (forceCollect is bool && forceCollect) {
    var lineMark = options['line-mark'] as String;
    return lineMark != null && lineMark.isNotEmpty
        ? lineMark
        : _DEFAULT_COLLECT_LINE_MARK;
  }

  return null;
}

String _parseOpenReport(ArgResults options) {
  var openReport = options['open-report'];

  if (openReport is bool && openReport) {
    var openCmd = options['open-cmd'] as String;
    return openCmd != null && openCmd.isNotEmpty ? openCmd : _DEFAULT_OPEN_CMD;
  }

  return null;
}
