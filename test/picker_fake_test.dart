@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:tekartik_google_jsapi/gapi.dart';
import 'package:tekartik_google_jsapi_picker/picker.dart';
import 'package:test/test.dart';

/// Fake google.picker namespace, no Google script is loaded: the builder and
/// the views record their calls in `ns.calls`.
const _fakePickerJs = '''
(function() {
  var ns = {
    calls: [],
    Action: { CANCEL: 'cancel', PICKED: 'picked' },
    Response: { ACTION: 'action', DOCUMENTS: 'docs' },
    Document: {
      ID: 'id', NAME: 'name', URL: 'url', MIME_TYPE: 'mimeType',
      DESCRIPTION: 'description', VERSION: 'version'
    },
    Feature: { MULTISELECT_ENABLED: 'multiselectEnabled' },
    ViewId: { DOCS: 'all', PHOTOS: 'photos' },
    View: function(viewId) {
      ns.calls.push(['View', viewId]);
      this.setMimeTypes = function(types) { ns.calls.push(['setMimeTypes', types]); };
    },
    DocsView: function(viewId) {
      ns.calls.push(['DocsView', viewId]);
      this.setMimeTypes = function(types) { ns.calls.push(['setMimeTypes', types]); };
      this.setSelectFolderEnabled = function(v) { ns.calls.push(['setSelectFolderEnabled', v]); };
      this.setIncludeFolders = function(v) { ns.calls.push(['setIncludeFolders', v]); };
    },
    PickerBuilder: function() {
      var record = function(name) {
        return function(arg) {
          ns.calls.push([name, (arg && arg.setMimeTypes) ? 'view' : arg]);
        };
      };
      this.addView = record('addView');
      this.enableFeature = record('enableFeature');
      this.disableFeature = record('disableFeature');
      this.setOAuthToken = record('setOAuthToken');
      this.setDeveloperKey = record('setDeveloperKey');
      this.setSelectableMimeTypes = record('setSelectableMimeTypes');
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

JSObject _newFakePicker() =>
    globalContext.callMethod<JSObject>('eval'.toJS, _fakePickerJs.toJS);

void _fire(JSObject jsPicker, Map<String, Object?> data) {
  jsPicker.callMethod('fire'.toJS, data.jsify());
}

void main() {
  const timeout = Timeout(Duration(seconds: 30));

  test('pick twice', () async {
    var jsPicker = _newFakePicker();
    var picker = PickerBuilder(GooglePicker(jsPicker)).build();

    var future = picker.pick();
    expect(jsPicker['visible'].dartify(), isTrue);
    _fire(jsPicker, {'action': 'cancel'});
    await expectLater(future, throwsA(isA<GapiException>()));
    expect(picker.ctlr.hasListener, isFalse);

    future = picker.pick();
    // The other actions (loaded) are ignored
    _fire(jsPicker, {'action': 'loaded'});
    _fire(jsPicker, {
      'action': 'picked',
      'docs': [
        {'id': 'doc1'},
      ],
    });
    var docs = await future;
    expect(docs.length, 1);
    expect(docs[0].id, 'doc1');
    expect(picker.ctlr.hasListener, isFalse);
  }, timeout: timeout);

  test('documents', () async {
    var jsPicker = _newFakePicker();
    var gpicker = GooglePicker(jsPicker);
    var picker = PickerBuilder(gpicker).build();
    var future = picker.pick();
    _fire(jsPicker, {
      'action': 'picked',
      'docs': [
        {
          'id': 'doc1',
          'name': 'My doc',
          'url': 'https://drive.google.com/doc1',
          'mimeType': 'application/pdf',
          'description': 'A pdf',
          'version': 12,
        },
        {'id': 'doc2'},
      ],
    });
    var docs = await future;
    expect(docs.length, 2);
    var doc = docs[0];
    expect(doc.name, 'My doc');
    expect(doc.url, 'https://drive.google.com/doc1');
    expect(doc.mimeType, 'application/pdf');
    expect(doc.description, 'A pdf');
    expect(doc.version, 12);
    expect(doc.asMap(), {
      'url': 'https://drive.google.com/doc1',
      'id': 'doc1',
      'name': 'My doc',
      'version': 12,
      'description': 'A pdf',
      'mimeType': 'application/pdf',
    });
    expect(docs.asList(), [
      doc.asMap(),
      {'id': 'doc2'},
    ]);
  }, timeout: timeout);

  test('a response without documents', () async {
    var gpicker = GooglePicker(_newFakePicker());
    var data = PickerData(gpicker, {'action': 'cancel'}.jsify() as JSObject);
    expect(data.action, gpicker.action.cancel);
    // Used to throw a null check error
    expect(data.documents.length, 0);
    expect(data.documents.asList(), isEmpty);
    expect(data.toString(), '{action: cancel}');
  }, timeout: timeout);

  test('constants', () {
    var gpicker = GooglePicker(_newFakePicker());
    expect(gpicker.action.picked, 'picked');
    expect(gpicker.action.cancel, 'cancel');
    expect(gpicker.response.action, 'action');
    expect(gpicker.response.documents, 'docs');
    expect(gpicker.document.id, 'id');
    expect(gpicker.document.version, 'version');
    expect(gpicker.feature.multiSelectEnabled, 'multiselectEnabled');
    expect(gpicker.viewId.docs, 'all');
    expect(gpicker.viewId.photos, 'photos');
  });

  test('builder and views', () {
    var jsPicker = _newFakePicker();
    var gpicker = GooglePicker(jsPicker);
    var builder = PickerBuilder(gpicker);
    var view = PickerView(gpicker, gpicker.viewId.photos)
      ..mimeTypes = ['image/png', 'image/jpeg'];
    var docsView = PickerDocsView(gpicker, gpicker.viewId.docs)
      ..selectFolderEnabled = true
      ..includeFolders = false;
    builder
      ..addView(view)
      ..addView(docsView)
      ..addViewId(gpicker.viewId.docs)
      ..enableFeature(gpicker.feature.multiSelectEnabled!)
      ..disableFeature('other')
      ..developerKey = 'my_key'
      ..oauthToken = 'my_token'
      ..selectableMimeTypes = ['application/pdf', 'text/plain'];
    builder.build().visible = false;
    expect(jsPicker['visible'].dartify(), isFalse);
    expect(jsPicker['calls'].dartify(), [
      ['View', 'photos'],
      ['setMimeTypes', 'image/png,image/jpeg'],
      ['DocsView', 'all'],
      ['setSelectFolderEnabled', true],
      ['setIncludeFolders', false],
      ['addView', 'view'],
      ['addView', 'view'],
      ['addView', 'all'],
      ['enableFeature', 'multiselectEnabled'],
      ['disableFeature', 'other'],
      ['setDeveloperKey', 'my_key'],
      ['setOAuthToken', 'my_token'],
      ['setSelectableMimeTypes', 'application/pdf,text/plain'],
    ]);
  });
}
