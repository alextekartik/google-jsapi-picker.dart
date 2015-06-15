@TestOn("browser")

library picker_test;

import 'dart:async';

import 'package:test/test.dart';

import 'package:tekartik_google_jsapi_picker/picker.dart';
import 'package:tekartik_google_jsapi/google_jsapi.dart';
import 'test_config.dart';

import 'package:tekartik_google_jsapi/js_utils.dart';

Gapi gapi;
Future<Gapi> testLoadGapi() {
  return loadGapi().then((Gapi _gapi) {
    gapi = _gapi;
    return gapi;
  });
}


void main() {

  group('picker', () {
    pickerMain();
  });
}

GooglePicker gpicker;
void pickerMain() {
  setUp(() {
    return testLoadGapi().then((Gapi gapi) {
      return loadPicker(gapi).then((GooglePicker _picker) {
        gpicker = _picker;
        return gpicker;
      });
    });
  });

  test('constants', () {
    Map pickerMap = jsObjectAsMap(gpicker.jsObject);
    print(pickerMap['ViewId']);
    expect(gpicker.response.ACTION, 'action');
    expect(gpicker.action.PICKED, 'picked');
    expect(gpicker.response.DOCUMENTS, 'docs');
    expect(gpicker.document.URL, 'url');
  });

  test('picker', () {
    return gapi.auth.authorize(CLIENT_ID, [GooglePicker.SCOPE_DRIVE_APP_FILE]
        ).then((String oauthToken) {
      PickerBuilder builder = new PickerBuilder(gpicker);
      builder.addViewId(gpicker.viewId.PHOTOS);
      builder.developerKey = DEVELOPER_KEY;
      builder.oauthToken = DEVELOPER_KEY;
      Picker uiPicker = builder.build();
      uiPicker.visible = true;
    });
  });

  /**
     * test to skip
     */
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
