// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Maps FFI prototypes onto the corresponding Win32 API function calls

import 'dart:ffi';

import 'typedefs.dart';

final _psapi = DynamicLibrary.open('psapi.dll');

/// {@category psapi}
final EnumProcesses = _psapi
    .lookupFunction<enumProcessesNative, enumProcessesDart>('EnumProcesses');

/// {@category psapi}
final EnumProcessModules =
    _psapi.lookupFunction<enumProcessModulesNative, enumProcessModulesDart>(
        'EnumProcessModules');

/// {@category psapi}
final GetModuleBaseName =
    _psapi.lookupFunction<getModuleBaseNameNative, getModuleBaseNameDart>(
        'GetModuleBaseNameW');

/// {@category psapi}
final GetModuleFileNameEx =
    _psapi.lookupFunction<getModuleFileNameExNative, getModuleFileNameExDart>(
        'GetModuleFileNameExW');
