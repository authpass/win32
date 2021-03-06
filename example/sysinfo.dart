// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Get general Windows system information

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

bool testFlag(int value, int attribute) => value & attribute == attribute;

/// Test for a minimum version of Windows.
///
/// Per:
/// https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getversionexw,
/// applications not manifested for Windows 8.1 or Windows 10 will return the
/// Windows 8 OS version value (6.2).
bool isWindowsVersionAtLeast(int majorVersion, int minorVersion) {
  final versionInfo = OSVERSIONINFO.allocate();

  try {
    final result = GetVersionEx(versionInfo.addressOf);

    if (result != 0) {
      if (versionInfo.dwMajorVersion >= majorVersion) {
        if (versionInfo.dwMinorVersion >= minorVersion) {
          return true;
        }
      }
      return false;
    } else {
      throw WindowsException(HRESULT_FROM_WIN32(GetLastError()));
    }
  } finally {
    free(versionInfo.addressOf);
  }
}

/// Test if running Windows is at least Windows XP.
bool isWindowsXPOrGreater() => isWindowsVersionAtLeast(5, 1);

/// Test if running Windows is at least Windows Vista.
bool isWindowsVistaOrGreater() => isWindowsVersionAtLeast(6, 0);

/// Test if running Windows is at least Windows 7.
bool isWindows7OrGreater() => isWindowsVersionAtLeast(6, 1);

/// Test if running Windows is at least Windows 8.
bool isWindows8OrGreater() => isWindowsVersionAtLeast(6, 2);

/// Return a value representing the physically installed memory in the computer.
/// This may not be the same as available memory.
int getSystemMemoryInMegabytes() {
  final memory = allocate<Uint64>();

  try {
    final result = GetPhysicallyInstalledSystemMemory(memory);
    if (result != 0) {
      return (memory.value / 1024).floor();
    } else {
      throw WindowsException(HRESULT_FROM_WIN32(GetLastError()));
    }
  } finally {
    free(memory);
  }
}

/// Get the computer's fully-qualified DNS name, where available.
String getComputerName() {
  final nameLength = allocate<Uint32>()..value = 0;
  String name;

  GetComputerNameEx(
      COMPUTER_NAME_FORMAT.ComputerNameDnsFullyQualified, nullptr, nameLength);

  final namePtr = allocate<Uint8>(count: nameLength.value * 2).cast<Utf16>();

  try {
    final result = GetComputerNameEx(
        COMPUTER_NAME_FORMAT.ComputerNameDnsFullyQualified,
        namePtr,
        nameLength);

    if (result != 0) {
      name = namePtr.unpackString(nameLength.value);
    } else {
      throw WindowsException(HRESULT_FROM_WIN32(GetLastError()));
    }
  } finally {
    free(namePtr);
    free(nameLength);
  }
  return name;
}

/// Retrieve a value from the registry.
Object getRegistryValue(int key, String subKey, String valueName) {
  Object dataValue;

  final subKeyPtr = TEXT(subKey);
  final valueNamePtr = TEXT(valueName);
  final openKeyPtr = allocate<IntPtr>();
  final dataType = allocate<Uint32>();

  // 256 bytes is more than enough, and Windows will throw ERROR_MORE_DATA if
  // not, so there won't be an overrun.
  final data = allocate<Uint8>(count: 256);
  final dataSize = allocate<Uint32>()..value = 256;

  try {
    var result = RegOpenKeyEx(key, subKeyPtr, 0, KEY_READ, openKeyPtr);
    if (result == ERROR_SUCCESS) {
      result = RegQueryValueEx(openKeyPtr.value, valueNamePtr, nullptr,
          dataType, data.cast(), dataSize);

      if (result == ERROR_SUCCESS) {
        if (dataType.value == REG_DWORD) {
          dataValue = data.value;
        } else if (dataType.value == REG_SZ) {
          dataValue = data.cast<Utf16>().unpackString(dataSize.value);
        } else {
          // other data types are available, but this is a sample
        }
      } else {
        throw WindowsException(HRESULT_FROM_WIN32(result));
      }
    } else {
      throw WindowsException(HRESULT_FROM_WIN32(result));
    }
  } finally {
    free(subKeyPtr);
    free(valueNamePtr);
    free(openKeyPtr);
    free(data);
    free(dataSize);
  }
  RegCloseKey(openKeyPtr.value);

  return dataValue;
}

/// Print battery information.
///
/// Uses the GetSystemPowerStatus API call to get information about the battery.
/// More information on the reported values can be found in the Windows API
/// documentation, here:
/// https://docs.microsoft.com/en-us/windows/win32/api/winbase/ns-winbase-system_power_status
void printBatteryInfo() {
  final powerStatus = SYSTEM_POWER_STATUS.allocate();

  try {
    final result = GetSystemPowerStatus(powerStatus.addressOf);
    if (result != 0) {
      print('Power status:');

      if (powerStatus.ACLineStatus == 0) {
        print(' - Disconnected from AC power');
      } else if (powerStatus.ACLineStatus == 1) {
        print(' - Connected to AC power');
      } else {
        print(' - AC power status unknown');
      }

      if (powerStatus.BatteryLifePercent == 255) {
        print(' - Battery status unknown.');
      } else {
        if (testFlag(powerStatus.BatteryFlag, 128)) {
          print(' - No battery installed');
        } else {
          // We know we have a battery
          print(
              ' - ${powerStatus.BatteryLifePercent}% percent battery remaining.');
          if (powerStatus.BatteryLifeTime != 0xFFFFFFFF) {
            print(
                ' - ${powerStatus.BatteryLifeTime / 60} minutes of power estimated to remain.');
          }
          if (powerStatus.SystemStatusFlag == 1) {
            print(' - Battery saver is on. Save energy where possible.');
          }
        }
      }
    } else {
      throw WindowsException(HRESULT_FROM_WIN32(GetLastError()));
    }
  } finally {
    free(powerStatus.addressOf);
  }
}

void main() {
  print('This version of Windows supports the APIs in:');
  if (isWindowsXPOrGreater()) print(' - Windows XP');
  if (isWindowsVistaOrGreater()) print(' - Windows Vista');
  if (isWindows7OrGreater()) print(' - Windows 7');
  if (isWindows8OrGreater()) print(' - Windows 8');

  // For more recent versions of Windows, Microsoft strongly recommends that
  // developers avoid version testing because of app compat issues caused by
  // buggy version testing. Indeed, the API goes to some lengths to make it hard
  // to test versions. Yet version detection is the only reliable solution for
  // certain API calls, so the recommendation is noted but not followed.
  final buildNumber = int.parse(getRegistryValue(
      HKEY_LOCAL_MACHINE,
      'SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\',
      'CurrentBuildNumber') as String);
  if (buildNumber >= 10240) print(' - Windows 10');

  print('\nWindows build number is: $buildNumber');

  print(
      '\nRAM physically installed on this computer: ${getSystemMemoryInMegabytes()}MB');
  print('\nComputer name is: ${getComputerName()}\n');

  printBatteryInfo();
}
