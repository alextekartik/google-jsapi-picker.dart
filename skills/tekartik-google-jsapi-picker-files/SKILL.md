---
name: tekartik-google-jsapi-picker-files
description: >-
  Use when a Dart web app opens the Google Drive file picker (google.picker)
  with tekartik_google_jsapi_picker: loadPicker, GooglePicker, PickerBuilder
  (developerKey, oauthToken, addView, addViewId, selectableMimeTypes),
  PickerView, PickerDocsView, Picker.pick / Picker.visible / Picker.stream,
  PickerData, PickerDataDocuments, PickerDataDocument, ViewId, PickerAction,
  GooglePicker.scopeDriveAppFile and the picker.dart import. Deprecated legacy
  package: read it before touching existing picker code.
---

# Google Drive file picker (tekartik_google_jsapi_picker)

`tekartik_google_jsapi_picker` wraps the `google.picker` javascript api: it
loads the `picker` gapi module through `tekartik_google_jsapi`, builds a picker
dialog and returns the picked Drive documents as Dart objects.

Both this package and `tekartik_google_jsapi` are marked deprecated (`picker.dart`
is `@Deprecated('TO MIGRATE')`) and use the legacy `dart:js` interop. Use this
skill to read or repair an existing browser app, not to start a new one.

## Guidelines

* Dependencies (git only, both packages live at their repo root, so no
  `path:`); you need the gapi package too because `loadPicker` takes a `Gapi`:
  ```yaml
  dependencies:
    tekartik_google_jsapi_picker:
      git:
        url: https://github.com/alextekartik/google-jsapi-picker.dart
    tekartik_google_jsapi:
      git:
        url: https://github.com/alextekartik/google-jsapi.dart
  ```
* Browser only (`dart:js`): compiles with `dart compile js` /
  `build_web_compilers`, not to wasm, and tests are `@TestOn('browser')`
  (`dart run build_runner test -- -p chrome`). One import:
  `package:tekartik_google_jsapi_picker/picker.dart`.
* Loading, in order: `var gapi = await loadGapiPlatform();` (from
  `package:tekartik_google_jsapi/gapi.dart`, the bare `platform.js` is enough)
  then `var gpicker = await loadPicker(gapi);`. `loadPicker` calls
  `gapi.load('picker')` and reads `window.google.picker`. It caches the
  `GooglePicker` in a library global, so later calls ignore the `Gapi` you
  pass and return the first one.
* `GooglePicker` exposes the js constant objects: `gpicker.action`
  (`picked`, `cancel`), `gpicker.response` (`action`, `documents`),
  `gpicker.document` (`url`, `id`, `name`, `mimeType`, `description`,
  `version`), `gpicker.feature` (`multiSelectEnabled`) and `gpicker.viewId`
  (only `docs` and `photos` have getters). For any other view id read the raw
  js map, `gpicker.viewId.jsObject!['SPREADSHEETS'] as String?`, or pass the
  documented string to `addViewId`. Every ALL_CAPS member (`DOCS`, `PICKED`,
  `SCOPE_DRIVE_APP_FILE`, ...) is a deprecated alias of the camelCase one.
* Build a dialog with `PickerBuilder(gpicker)`: `addView(PickerView)` or
  `addViewId(String?)`, `developerKey = <api key>`, `oauthToken = <access
  token>`, `selectableMimeTypes = [...]`, `enableFeature(...)` /
  `disableFeature(...)` (feature names from `gpicker.feature`), then
  `build()`, which returns a `Picker`.
* Views: `PickerView(gpicker, gpicker.viewId.docs)` with an optional
  `mimeTypes = ['application/pdf']` (joined with commas for js).
  `PickerDocsView(gpicker, gpicker.viewId.docs)` adds
  `selectFolderEnabled = true` and `includeFolders = true`, which is the only
  way to let the user pick a folder.
* Showing it: `await picker.pick()` sets `visible = true` and completes with a
  `PickerDataDocuments`. **A cancel completes the future with an error**, a
  `GapiException('cancel')` from `package:tekartik_google_jsapi/gapi.dart`, so
  always wrap `pick()` in a try/catch. For custom handling use
  `picker.visible = true` plus `picker.stream` (`PickerData.action` compared
  with `gpicker.action.picked` / `gpicker.action.cancel`).
* `Picker.stream` is a single-subscription controller and `pick()` subscribes
  to it, so one `Picker` serves one pick: call `builder.build()` again (or
  rebuild the builder) for the next one. Neither the controller nor the js
  dialog is disposed for you.
* Results: `docs.length`, `docs[i]` -> `PickerDataDocument` with `id`, `name`,
  `url`, `mimeType`, `description`, `version` and `asMap()`;
  `docs.asList()` / `docs.toString()` give a loggable `List<Map>`. The picker
  returns metadata only: download the content with the Drive api and the same
  access token.
* Credentials: `developerKey` is the browser API key and `oauthToken` an
  OAuth access token for `GooglePicker.scopeDriveAppFile`
  (`https://www.googleapis.com/auth/drive.file`). Read both from a runtime
  config (the package example uses a git-ignored `local.config.yaml` copied
  from `sample.local.config.yaml`); never commit a key, a client id or a
  token. The JavaScript origin of your dev server must be registered for that
  client id in the Google Cloud console.
* Getting the token: the legacy path is `loadGapiAuth(gapi)` then
  `authorize(clientId, [GooglePicker.scopeDriveAppFile])` from
  `package:tekartik_google_jsapi/gapi_auth.dart`; the package example uses the
  current Google Identity Services instead, with
  `requestAccessCredentials(clientId: ..., scopes: ...)` from
  `package:googleapis_auth/auth_browser.dart`. Prefer the latter in code you
  still maintain. Trigger either from a click handler or the popup is blocked.

## Examples

### Load the picker and pick files

```dart
// ignore_for_file: deprecated_member_use
import 'package:tekartik_google_jsapi/gapi.dart';
import 'package:tekartik_google_jsapi_picker/picker.dart';

/// [developerKey] and [oauthToken] come from a runtime config / sign-in,
/// never from the source.
Future<List<Map>> pickFiles({
  required String developerKey,
  required String oauthToken,
}) async {
  var gapi = await loadGapiPlatform();
  var gpicker = await loadPicker(gapi);

  var builder = PickerBuilder(gpicker)
    ..developerKey = developerKey
    ..oauthToken = oauthToken
    ..addView(PickerView(gpicker, gpicker.viewId.docs));

  var picker = builder.build();
  try {
    var docs = await picker.pick();
    return docs.asList();
  } on GapiException catch (e) {
    print('picker cancelled: $e');
    return <Map>[];
  }
}
```

### Pick a folder, or only some mime types

```dart
// ignore_for_file: deprecated_member_use
import 'package:tekartik_google_jsapi_picker/picker.dart';

/// Folder selection needs a [PickerDocsView], not a plain [PickerView].
Picker buildFolderPicker(
  GooglePicker gpicker, {
  required String developerKey,
  required String oauthToken,
}) {
  var view = PickerDocsView(gpicker, gpicker.viewId.docs)
    ..selectFolderEnabled = true
    ..includeFolders = true;
  view.mimeTypes = ['application/vnd.google-apps.folder'];
  return (PickerBuilder(gpicker)
        ..developerKey = developerKey
        ..oauthToken = oauthToken
        ..addView(view))
      .build();
}
```

### Handle the raw picker events instead of pick()

```dart
// ignore_for_file: deprecated_member_use
import 'package:tekartik_google_jsapi_picker/picker.dart';

void showAndListen(GooglePicker gpicker, Picker picker) {
  picker.stream.listen((PickerData data) {
    if (data.action == gpicker.action.picked) {
      for (var i = 0; i < data.documents.length; i++) {
        var doc = data.documents[i];
        print('${doc.id} ${doc.name} ${doc.mimeType} ${doc.url}');
      }
    } else if (data.action == gpicker.action.cancel) {
      print('cancelled');
    }
  });
  picker.visible = true;
}
```

### Get an access token with Google Identity Services, then pick

```dart
// ignore_for_file: deprecated_member_use
import 'package:googleapis_auth/auth_browser.dart';
import 'package:tekartik_google_jsapi/gapi.dart';
import 'package:tekartik_google_jsapi_picker/picker.dart';
import 'package:web/web.dart' as web;

/// Call from a click handler; [clientId] looks like
/// `<my-id>.apps.googleusercontent.com` and is read from a runtime config.
void setupPickButton({
  required String clientId,
  required String developerKey,
}) {
  web.document.querySelector('button.app-pick')!.onClick.listen((event) async {
    event.preventDefault();
    var credentials = await requestAccessCredentials(
      clientId: clientId,
      scopes: [GooglePicker.scopeDriveAppFile],
    );
    var gpicker = await loadPicker(await loadGapiPlatform());
    var picker = (PickerBuilder(gpicker)
          ..developerKey = developerKey
          ..oauthToken = credentials.accessToken.data
          ..addViewId(gpicker.viewId.docs))
        .build();
    try {
      print(await picker.pick());
    } on GapiException catch (_) {
      print('cancelled');
    }
  });
}
```

## Common mistakes

* Calling `loadPicker` without loading gapi first, or expecting a second
  `loadPicker` call with a different `Gapi` to rebuild the picker.
* Treating a cancel as an empty result: `pick()` completes with
  `GapiException('cancel')`.
* Reusing one `Picker` for two `pick()` calls (the stream is already
  listened): build a new one.
* Forgetting `developerKey` or `oauthToken`, or using a token without the
  `drive.file` scope: the dialog opens empty or errors.
* Using `PickerView` and wondering why folders cannot be selected.
* Hardcoding the client id, api key or a token in the source.
