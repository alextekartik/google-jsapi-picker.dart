// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package

@TestOn('browser')
library;

import 'dart:js';

import 'package:tekartik_google_jsapi/gapi.dart';
import 'package:tekartik_google_jsapi_picker/picker.dart';
import 'package:test/test.dart';

/// Fake google.picker namespace, no Google script is loaded.
const _fakePickerJs = '''
(function() {
  var ns = {
    Action: { CANCEL: 'cancel', PICKED: 'picked' },
    Response: { ACTION: 'action', DOCUMENTS: 'docs' },
    Document: { ID: 'id' },
    PickerBuilder: function() {
      this.setCallback = function(cb) { ns.callback = cb; };
      this.build = function() {
        return { setVisible: function(visible) { ns.visible = visible; } };
      };
    },
    fire: function(data) { ns.callback(data); }
  };
  return ns;
})()
''';

void main() {
  test('pick twice', () async {
    var jsPicker = context.callMethod('eval', [_fakePickerJs]) as JsObject;
    var picker = PickerBuilder(GooglePicker(jsPicker)).build();

    var future = picker.pick();
    expect(jsPicker['visible'], isTrue);
    jsPicker.callMethod('fire', [
      JsObject.jsify({'action': 'cancel'}),
    ]);
    await expectLater(future, throwsA(isA<GapiException>()));
    expect(picker.ctlr.hasListener, isFalse);

    future = picker.pick();
    jsPicker.callMethod('fire', [
      JsObject.jsify({
        'action': 'picked',
        'docs': [
          {'id': 'doc1'},
        ],
      }),
    ]);
    var docs = await future;
    expect(docs.length, 1);
    expect(docs[0].id, 'doc1');
    expect(picker.ctlr.hasListener, isFalse);
  });
}
