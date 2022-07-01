import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ffi/ffi.dart' as ffi;
import 'dart:ffi' as ffi;

class Texturerender {
  static const MethodChannel _channel = MethodChannel('texturerender');
  int id;
  ffi.Pointer<ffi.Uint8> _previousFrame = ffi.nullptr;
  final ValueNotifier<int?> textureId = ValueNotifier<int?>(null);

  Texturerender({required this.id, required void Function() onRegistered}) {
    _registerTexture().then((_) => onRegistered());
  }

  dispose() {
    _unregisterTexture();
  }

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<void> _registerTexture() async {
    textureId.value = await _channel.invokeMethod(
      "RegisterTexture",
      {
        "id": id,
      },
    );
  }

  Future<void> update(int id, ffi.Pointer<ffi.Uint8> buffer, int width, int height) async {
    await _channel.invokeMethod('UpdateFrame', {
      "id": id,
      "width": width,
      "height": height,
      "buffer": buffer.address,
    });
    if (_previousFrame != ffi.nullptr) ffi.calloc.free(_previousFrame);
    _previousFrame = buffer;
  }

  Future<void> _unregisterTexture() async {
    await _channel.invokeMethod(
      "UnregisterTexture",
      {
        "id": id,
      },
    );
  }
}
