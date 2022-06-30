import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ffi' as ffi;

class Texturerender {
  final ValueNotifier<int?> textureId = ValueNotifier<int?>(null);

  static const MethodChannel _channel = MethodChannel('texturerender');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<void> getTextureId(int id) async {
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
  }
}
