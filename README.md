google-jsapi-picker.dart
========================

Open the Google Drive file picker (the `google.picker` javascript api) from a
Dart web app and get the picked documents as Dart objects. Built on
`dart:js_interop` and `package:web`: works with dart2js and dart2wasm.

## Getting started

Not on pub.dev, add it as a git dependency, with the gapi loader:

```yaml
dependencies:
  tekartik_google_jsapi_picker:
    git:
      url: https://github.com/alextekartik/google-jsapi-picker.dart
  tekartik_google_jsapi:
    git:
      url: https://github.com/alextekartik/google-jsapi.dart
```

Platforms: browser only (dart2js, dart2wasm, Flutter web).

You need, from the [Google Cloud console](https://console.cloud.google.com/):
a browser API key (the picker's `developerKey`) and an OAuth access token for
the `https://www.googleapis.com/auth/drive.file` scope
(`GooglePicker.scopeDriveAppFile`), obtained with Google Identity Services
(the example uses `requestAccessCredentials` of `googleapis_auth`).

```dart
import 'package:tekartik_google_jsapi/gapi.dart';
import 'package:tekartik_google_jsapi_picker/picker.dart';

/// Lets the user pick Drive documents, null on cancel.
Future<PickerDataDocuments?> pickDocuments({
  required String apiKey,
  required String accessToken,
}) async {
  var gapi = await loadGapiPlatform();
  var gpicker = await loadPicker(gapi);
  var builder = PickerBuilder(gpicker)
    ..addView(PickerView(gpicker, gpicker.viewId.docs))
    ..developerKey = apiKey
    ..oauthToken = accessToken;
  try {
    var docs = await builder.build().pick();
    for (var i = 0; i < docs.length; i++) {
      print('${docs[i].name} ${docs[i].id} ${docs[i].mimeType}');
    }
    return docs;
  } on GapiException {
    // The user closed the dialog.
    return null;
  }
}
```

## What to use

- `loadPicker(gapi)`: loads the `picker` module (once, later calls return the
  first `GooglePicker`).
- `GooglePicker`: the constants (`action`, `response`, `document`, `feature`,
  `viewId`).
- `PickerBuilder`: `addView`, `addViewId`, `developerKey`, `oauthToken`,
  `selectableMimeTypes`, `enableFeature` (`gpicker.feature.multiSelectEnabled`),
  then `build()`.
- `PickerView` (`mimeTypes`), `PickerDocsView` (`selectFolderEnabled`,
  `includeFolders`: to pick a folder).
- `Picker.pick()`: shows the dialog, completes with the `PickerDataDocuments`
  (`length`, `[i]`: `id`, `name`, `url`, `mimeType`, `description`,
  `version`, `asMap()`). A picker can be shown again. `Picker.stream` gives
  every callback (loaded, picked, cancel).

## Pitfalls

- A cancel completes `pick()` with a `GapiException('cancel')`: catch it.
- The picker returns metadata only: download the content with the Drive api
  and the same access token.
- The access token expires (about an hour): request a new one before
  building a picker.
- Show the picker from a user gesture (a click) to avoid popup blockers.

## Migrating from 0.2

0.3.0 moved from `dart:js` to `dart:js_interop`: the wrapped javascript
objects are `JSObject` (`JSArray<JSObject>` for `PickerDataDocuments.jsArray`,
`JSFunction` constructors) instead of `JsObject` / `JsArray`, for
`GooglePicker(jsObject)`, `PickerView.jsPickerView`,
`PickerBuilder.jsPickerBuilder`, `PickerData` / `PickerDataDocument` /
`PickerDataDocuments` and the constant classes. Code that only uses the Dart
API (as above) has nothing to change. It needs `tekartik_google_jsapi`
0.3.0 (also on `dart:js_interop`).

## Example and tests

- `example/google_jsapi_picker_example.html`: load, authorize, pick. Copy
  `example/sample.local.config.yaml` to `example/local.config.yaml` (git
  ignored) with your API key, OAuth client id and client secret (the example
  checks the three), then
  `dart run tool/webdev_serve.dart` and open
  <http://localhost:8081/google_jsapi_picker_example.html>.
- `dart test`: `test/picker_fake_test.dart` drives the API on a fake
  `google.picker` (no network, no credentials), `test/picker_test.dart` loads
  the real picker module (network); its dialog test is skipped (it needs
  credentials in `test/local.config.yaml` and a user).
