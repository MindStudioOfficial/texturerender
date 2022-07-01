import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ffi/ffi.dart' as ffi;
import 'dart:ffi' as ffi;

class Texturerender {
  static const MethodChannel _channel = MethodChannel('texturerender');
  final Set<int> _ids = {};
  ffi.Pointer<ffi.Uint8> _previousFrame = ffi.nullptr;
  final ValueNotifier<int?> textureId = ValueNotifier<int?>(null);

  register(
    int id,
    Function(bool success) onDone,
  ) {
    if (_ids.contains(id)) {
      onDone(false);
      return;
    }
    _registerTexture(id).then((_) {
      onDone(true);
      _ids.add(id);
    });
  }

  Set<int> get ids => _ids;

  unregister(int id, Function(bool success) onDone) {
    if (!_ids.contains(id)) {
      onDone(false);
      return;
    }
    _unregisterTexture(id).then((_) {
      onDone(true);
    });
    _ids.remove(id);
  }

  dispose() {
    for (var id in _ids) {
      _unregisterTexture(id);
    }
    _ids.clear();
  }

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<void> _registerTexture(int id) async {
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

  Future<void> _unregisterTexture(int id) async {
    await _channel.invokeMethod(
      "UnregisterTexture",
      {
        "id": id,
      },
    );
  }

  Widget widget(int width, int height) => ValueListenableBuilder<int?>(
      valueListenable: textureId,
      builder: (context, texId, _) {
        if (texId != null) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: width.toDouble(),
              height: height.toDouble(),
              child: Texture(textureId: texId),
            ),
          );
        }
        return Container();
      });
}
