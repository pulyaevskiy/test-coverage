// Copyright (c) 2018, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:test_coverage/test_coverage.dart';

Future main(List<String> arguments) {
  generateMainScript(Directory.current.path);
  return runTestsAndCollect(Directory.current.path);
}
