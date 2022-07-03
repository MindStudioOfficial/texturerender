import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ffi/ffi.dart' as ffi;
import 'dart:ffi' as ffi;

class Texturerender {
  static const MethodChannel _channel = MethodChannel('texturerender');
  final Map<int, ValueNotifier<Tex>> _ids = {};

  Set<int> get ids => _ids.keys.toSet();

  int getUniqueId() {
    if (_ids.isEmpty) return 0;
    return _ids.keys.reduce((a, b) => a > b ? a : b) + 1;
  }

  /*
  Texturerender() {
    WidgetsFlutterBinding.ensureInitialized();
    _channel.setMethodCallHandler((call) async {
      if (call.method.compareTo("FreeBuffer") == 0) {
        print(call.arguments);
      }
      return true;
    });
  }*/

  Future<bool> register(int id) async {
    Completer<bool> c = Completer<bool>();
    if (_ids.containsKey(id)) {
      c.complete(false);
    }
    _registerTexture(id).then((texId) {
      _ids.addAll(
        {
          id: ValueNotifier<Tex>(
            Tex(
              textureId: texId,
              size: Size.zero,
              previousFrame: ffi.nullptr,
            ),
          ),
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

  Future<void> dispose() async {
    for (int id in _ids.keys) {
      await _unregisterTexture(id);
    }
    _ids.clear();
  }

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Size? texSize(int id) {
    if (_ids[id] != null) return _ids[id]!.value.size;
    return null;
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
    _ids[id]!.value.size = Size(width.toDouble(), height.toDouble());

    await _channel.invokeMethod('UpdateFrame', {
      "id": id,
      "width": width,
      "height": height,
      "buffer": buffer.address,
    });
    ffi.Pointer prev = _ids[id]!.value.previousFrame;
    Future.delayed(const Duration(milliseconds: 10), () {
      if (prev != ffi.nullptr) ffi.calloc.free(prev);
    });
    _ids[id]!.value.previousFrame = buffer;
  }

  Future<void> _unregisterTexture(int id) async {
    await _channel.invokeMethod(
      "UnregisterTexture",
      {
        "id": id,
      },
    );
  }

  Widget widget(int id) {
    return ValueListenableBuilder<Tex>(
      valueListenable: _ids[id]!,
      builder: (context, tex, _) {
        if (tex.textureId != null) {
          return SizedBox(
            width: tex.size.width,
            height: tex.size.height,
            child: Texture(textureId: tex.textureId!),
          );
        }
        return Container();
      },
    );
  }

  ValueListenable<Tex>? textureInfo(int id) => _ids[id];
}

class Tex {
  int? textureId;
  Size size;
  ffi.Pointer<ffi.Uint8> previousFrame = ffi.nullptr;

  Tex({required this.textureId, required this.size, required this.previousFrame});
}
