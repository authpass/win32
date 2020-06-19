// IShellItemFilter.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../constants.dart';
import '../exceptions.dart';
import '../macros.dart';
import '../structs.dart';
import '../prototypes.dart';
import '../com/combase.dart';

import 'IUnknown.dart';

const IID_IShellItemFilter = '{2659B475-EEB8-48b7-8F07-B378810F48CF}';

typedef _IncludeItem_Native = Int32 Function(
    Pointer obj, Pointer<COMObject> psi);
typedef _IncludeItem_Dart = int Function(Pointer obj, Pointer<COMObject> psi);

typedef _GetEnumFlagsForItem_Native = Int32 Function(
    Pointer obj, Pointer<COMObject> psi, Pointer<Uint32> pgrfFlags);
typedef _GetEnumFlagsForItem_Dart = int Function(
    Pointer obj, Pointer<COMObject> psi, Pointer<Uint32> pgrfFlags);

class IShellItemFilter extends IUnknown {
  // vtable begins at 3, ends at 4

  @override
  Pointer<COMObject> ptr;

  IShellItemFilter(this.ptr) : super(ptr);

  int IncludeItem(Pointer<COMObject> psi) =>
      Pointer<NativeFunction<_IncludeItem_Native>>.fromAddress(
              ptr.ref.vtable.elementAt(3).value)
          .asFunction<_IncludeItem_Dart>()(ptr.ref.lpVtbl, psi);

  int GetEnumFlagsForItem(Pointer<COMObject> psi, Pointer<Uint32> pgrfFlags) =>
      Pointer<NativeFunction<_GetEnumFlagsForItem_Native>>.fromAddress(
                  ptr.ref.vtable.elementAt(4).value)
              .asFunction<_GetEnumFlagsForItem_Dart>()(
          ptr.ref.lpVtbl, psi, pgrfFlags);
}
