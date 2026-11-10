## 0.3.0

- `dart:js_interop` and `package:web` instead of `dart:js`: builds with
  dart2js and dart2wasm. Breaking: the wrapped javascript objects are
  `JSObject` (`JSArray<JSObject>` for `PickerDataDocuments.jsArray`) instead
  of `JsObject` / `JsArray`; the Dart API is unchanged.
- Requires `tekartik_google_jsapi` 0.3.0 (and `tekartik_bootstrap` 0.4.0 for
  the example).
- `PickerDataDocuments.length` is 0 for a response without documents (was a
  null check error).
- The library is no longer `@Deprecated`.

## 0.2.2+1

- `pick()` can be called twice.
