## 0.6.0

- Improved log output.
- New Options:
  - `timeout`: for all tests timeout (in seconds).
  - `force-collect`: to force collect of coverage using an STDOUT mark, avoiding Isolate pause issues.
  - `force-exit-after-collect`: forces process to exit after collect coverage.
  - `gen-report`: generates HTML report.
  - `open-report`: opens HTML report in default browser.
- Fix issue when trying to kill process when Dart is executed from a `bash`/`sh` script.
  (usually in Flutter SDK installations).
- Improved documentation.

## 0.5.0

- Updated dependency on coverage package to ^0.14.1 (#24)
- Badge generation now honours the corresponding command line argument (#27)

## 0.4.3

- Fix support for --[no-]badge. (#21)

## 0.4.2

* Minimal coverage percentage & test output to console

## 0.4.1

* Fixed test generator for windows platform (#11)

## 0.4.0

* Upgraded to coverage 0.13.0 (#8)

## 0.3.0

* Refactor code for Dart 2.0 features.
* Added `--exclude`, `--port`, `--help` and `--[no-]badge` options. See `pub run test_coverage -h`
  for more details.
* Coverage badge moved from `coverage/badge.svg` to `coverage_badge.svg` (in the package root)
  which makes it easier to manage `coverage/` in `.gitignore`, allows you to commit the badge
  to your repo and include it in the `README.md`.

## 0.2.4

* Upgraded dependencies.
* Bumped SDK constraint to `2.3.0`.

## 0.2.3

* Prepare for Dart 2 stable.

## 0.2.2

* Renamed `coverage/coverage.lcov` to `coverage/lcov.info`.

## 0.2.1

* Generate coverage badge in `coverage/badge.svg`.

## 0.2.0

* Moved generated reports to `coverage/` subfolder.
* Added tests.
* Updated usage instructions to recommend local `dev_dependencies`
  and `pub run test_coverage` instead of global installation.

## 0.1.1

* Make paths in lcov file relative to the project root.

## 0.1.0

* Initial version
