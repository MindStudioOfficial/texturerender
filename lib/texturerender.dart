import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ffi/ffi.dart' as ffi;
import 'dart:ffi' as ffi;

class Texturerender {
  static const MethodChannel _channel = MethodChannel('texturerender');
  final Map<int, ValueNotifier<int?>> _ids = {};
  ffi.Pointer<ffi.Uint8> _previousFrame = ffi.nullptr;

  Set<int> get ids => _ids.keys.toSet();

  int getUniqueId() {
    if (_ids.isEmpty) return 0;
    return _ids.keys.reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<bool> register(int id) async {
    Completer<bool> c = Completer<bool>();
    if (_ids.containsKey(id)) {
      c.complete(false);
    }
    _registerTexture(id).then((texId) {
      _ids.addAll(
        {
          id: ValueNotifier<int?>(texId),
        },
      );
      c.complete(true);
    });
    return c.future;
  }

  Future<bool> unregister(int id) async {
    Completer<bool> c = Completer<bool>();
    if (!_ids.containsKey(id)) {
      c.complete(false);
    }
    _unregisterTexture(id).then((_) {
      c.complete(true);
    });
    _ids.remove(id);
    return c.future;
  }

  dispose() {
    _ids.forEach((id, texId) {
      _unregisterTexture(id);
    });
    _ids.clear();
  }

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<int> _registerTexture(int id) async {
    int texId = await _channel.invokeMethod(
      "RegisterTexture",
      {
        "id": id,
      },
    );
    return texId;
  }

  Future<void> update(int id, ffi.Pointer<ffi.Uint8> buffer, int width, int height) async {
    if (!_ids.containsKey(id)) {
      ffi.calloc.free(buffer);
      return;
    }
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

  Widget? widget(int id, int width, int height) {
    if (_ids.containsKey(id)) {
      return ValueListenableBuilder<int?>(
          valueListenable: _ids[id]!,
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
    return null;
  }
}
