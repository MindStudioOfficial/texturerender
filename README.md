# texturerender

A flutter plugin to directly Interface with the Texture Widget on Windows using a Pointer

| Android | iOS | Linux | Windows | MacOS | Web |
| ------- | --- | ----- | ------- | ----- | --- |
| ❌       | ❌   | ❌     | ✅       | ❌     | ❌   |

## How to use

### Initialize a new Texture with an ID
```dart
int id = 0;
Texturerender tr = Texturerender(id: id, onRegistered: () {
    print(tr.textureId.value);
    // now you can start rendering to the texture
});
```

### Update the pixelbuffer

```dart
int id = 0;
ffi.Pointer<Uint8> bytes = ...; // use ffi.calloc or get an external Pointer
int width = 1920;
int height = 1080;
tr.update(id,bytes, width, height);

// the last Pointer is automatically freed when receiving a new buffer
```

### Display the Texture in your Widgettree 
```dart
 ValueListenableBuilder(
    valueListenable: tr.textureId,
    builder: (context, textureId, _) {
        if (tr.textureId.value != null) {
            return FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                    width: width.toDouble(),
                    height: height.toDouble(),
                    child: Texture(textureId: tr.textureId.value!),
                ),
            );
        }
        return Container();
});
```