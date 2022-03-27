@TestOn('browser')
library picker_test;

import 'dart:async';

import 'package:tekartik_browser_utils/js_utils.dart';
import 'package:tekartik_google_jsapi/gapi.dart';
import 'package:tekartik_google_jsapi/gapi_auth.dart';
import 'package:tekartik_google_jsapi_picker/picker.dart';
import 'package:test/test.dart';

import 'test_config.dart';
import 'test_setup.dart';

Gapi? gapi;

Future<Gapi?> testLoadGapi() async {
  gapi = await loadGapi();
  return gapi;
}

void main() {
  group('picker', () {
    pickerMain();
  });
}

GooglePicker? gpicker;
AppOptions? options;

void pickerMain() {
  setUp(() async {
    options = await setup();
    return testLoadGapi().then((Gapi? gapi) {
      return loadPicker(gapi).then((GooglePicker picker) {
        gpicker = picker;
        return gpicker;
      });
    });
  });

  test('constants', () {
    Map pickerMap = jsObjectAsMap(gpicker!.jsObject)!;
    print(pickerMap['ViewId']);
    expect(gpicker!.response.action, 'action');
    expect(gpicker!.action.picked, 'picked');
    expect(gpicker!.response.documents, 'docs');
    expect(gpicker!.document.url, 'url');
  });

  test('picker', () async {
    if (options != null) {
      final gapiAuth = await loadGapiAuth(gapi);
      return gapiAuth
          .authorize(options!.clientId!, [GooglePicker.scopeDriveAppFile]).then(
              (String oauthToken) {
        final builder = PickerBuilder(gpicker);
        builder.addViewId(gpicker!.viewId.photos);
        builder.developerKey = options!.developerKey;
        builder.oauthToken = null; // optopnnull;
        final uiPicker = builder.build();
        uiPicker.visible = true;
      });
    }
  }, skip: true);

  /// test to skip
  /*
  test('pick', () {

    return gapi.auth.authorize(CLIENT_ID, [GooglePicker.SCOPE_DRIVE_APP_FILE]
        ).then((String oauthToken) {
      PickerBuilder builder = new PickerBuilder(gpicker);
      builder.addViewId(gpicker.viewId.DOCS);
      builder.developerKey = DEVELOPER_KEY;
      builder.oauthToken = oauthToken;
      Picker uiPicker = builder.build();
      return uiPicker.pick().then((PickerDataDocuments docs) {
        print(docs);
      });
    });
  });
  */
}
