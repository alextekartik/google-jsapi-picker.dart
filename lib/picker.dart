/// The Google Drive file picker (the `google.picker` javascript api) from
/// Dart, on `dart:js_interop`: works with dart2js and dart2wasm.
///
/// ```dart
/// var gapi = await loadGapiPlatform();
/// var gpicker = await loadPicker(gapi);
/// var builder = PickerBuilder(gpicker)
///   ..addView(PickerView(gpicker, gpicker.viewId.docs))
///   ..developerKey = apiKey
///   ..oauthToken = accessToken;
/// var docs = await builder.build().pick(); // throws on cancel
/// ```
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:tekartik_google_jsapi/gapi.dart';

// https://developers.google.com/workspace/drive/picker/reference/picker

/// The value of [key] in [object], as a string (null when absent).
String? _getString(JSObject? object, String? key) {
  if (object == null || key == null) {
    return null;
  }
  var value = object[key].dartify();
  return value?.toString();
}

/// The value of [key] in [object], as an int (null when absent or not a
/// number).
int? _getInt(JSObject? object, String? key) {
  if (object == null || key == null) {
    return null;
  }
  var value = object[key].dartify();
  return value is num ? value.toInt() : null;
}

/// A picker dialog, built by [PickerBuilder.build].
class Picker {
  /// The picker namespace.
  GooglePicker? picker;
  JSObject? _jsObject;

  Picker._(this.picker);

  /// Every callback of the dialog (loaded, picked, cancel...), a broadcast
  /// stream: [pick] can be called several times.
  ///
  /// only onData is called
  Stream<PickerData> get stream {
    return ctlr.stream;
  }

  /// The controller of [stream].
  StreamController<PickerData> ctlr = StreamController.broadcast();

  void _callback(JSAny? jsData) {
    if (jsData.isA<JSObject>()) {
      ctlr.add(PickerData(picker, jsData as JSObject));
    }
  }

  /// Shows or hides the dialog.
  set visible(bool visible) {
    _jsObject!.callMethod('setVisible'.toJS, visible.toJS);
  }

  /// Shows the dialog and completes with the documents picked.
  ///
  /// Throws a [GapiException] (`cancel`) when the user cancels.
  Future<PickerDataDocuments> pick() {
    final completer = Completer<PickerDataDocuments>();
    visible = true;
    late StreamSubscription<PickerData> subscription;
    subscription = stream.listen(
      (PickerData data) {
        if (data.action == picker!.action.cancel) {
          unawaited(subscription.cancel());
          completer.completeError(const GapiException('cancel'));
        } else if (data.action == picker!.action.picked) {
          unawaited(subscription.cancel());
          completer.complete(data.documents);
        }
      },
      onError: (Object e) {
        unawaited(subscription.cancel());
        completer.completeError(e);
      },
    );
    return completer.future;
  }
}

/// A view of the dialog (`google.picker.View`).
class PickerView {
  JSObject? _jsObject;

  PickerView._();

  /// A view of [viewId] (`gpicker.viewId.docs`).
  PickerView(GooglePicker picker, String? viewId) {
    _jsObject = picker._pickerViewConstructor!.callAsConstructor<JSObject>(
      viewId?.toJS,
    );
  }

  /// The javascript view.
  JSObject? get jsPickerView => _jsObject;

  /// The mime types shown.
  set mimeTypes(List<String> mimeTypes) {
    _jsObject!.callMethod('setMimeTypes'.toJS, mimeTypes.join(',').toJS);
  }
}

/// A Drive view (`google.picker.DocsView`), to pick folders too.
class PickerDocsView extends PickerView {
  /// A Drive view of [viewId] (`gpicker.viewId.docs`).
  PickerDocsView(GooglePicker picker, String? viewId) : super._() {
    _jsObject = picker._pickerDocsViewConstructor!.callAsConstructor<JSObject>(
      viewId?.toJS,
    );
  }

  @override
  JSObject? get jsPickerView => _jsObject;

  /// Whether a folder can be picked.
  set selectFolderEnabled(bool enabled) {
    _jsObject!.callMethod('setSelectFolderEnabled'.toJS, enabled.toJS);
  }

  /// Whether the folders are shown.
  set includeFolders(bool include) {
    _jsObject!.callMethod('setIncludeFolders'.toJS, include.toJS);
  }
}

/// Builds a [Picker] (`google.picker.PickerBuilder`).
class PickerBuilder {
  /// The javascript builder.
  late JSObject jsPickerBuilder;

  /// The picker namespace.
  GooglePicker? gpicker;

  /// A builder of the picker namespace [gpicker] (see [loadPicker]).
  PickerBuilder(this.gpicker) {
    jsPickerBuilder = gpicker!._pickerBuilderConstructor!
        .callAsConstructor<JSObject>();
  }

  /// Adds [view].
  void addView(PickerView view) {
    jsPickerBuilder.callMethod('addView'.toJS, view.jsPickerView);
  }

  /// Adds the view of [viewId] (`gpicker.viewId.docs`).
  void addViewId(String? viewId) {
    jsPickerBuilder.callMethod('addView'.toJS, viewId?.toJS);
  }

  /// Disables [feature] (`gpicker.feature.multiSelectEnabled`).
  void disableFeature(String feature) {
    jsPickerBuilder.callMethod('disableFeature'.toJS, feature.toJS);
  }

  /// Enables [feature] (`gpicker.feature.multiSelectEnabled`).
  void enableFeature(String feature) {
    jsPickerBuilder.callMethod('enableFeature'.toJS, feature.toJS);
  }

  /// The OAuth access token (scope [GooglePicker.scopeDriveAppFile]).
  set oauthToken(String? oauthToken) {
    jsPickerBuilder.callMethod('setOAuthToken'.toJS, oauthToken?.toJS);
  }

  /// The browser API key.
  set developerKey(String? developerKey) {
    jsPickerBuilder.callMethod('setDeveloperKey'.toJS, developerKey?.toJS);
  }

  /// The mime types that can be picked.
  set selectableMimeTypes(List<String> mimeTypes) {
    jsPickerBuilder.callMethod(
      'setSelectableMimeTypes'.toJS,
      mimeTypes.join(',').toJS,
    );
  }

  /// The dialog, hidden: [Picker.pick] shows it.
  Picker build() {
    final picker = Picker._(gpicker);
    jsPickerBuilder.callMethod(
      'setCallback'.toJS,
      ((JSAny? data) => picker._callback(data)).toJS,
    );
    picker._jsObject = jsPickerBuilder.callMethod<JSObject?>('build'.toJS);
    return picker;
  }
}

/// A picked document.
class PickerDataDocument {
  /// The javascript document.
  JSObject jsObject;

  /// The picker namespace.
  GooglePicker? picker;

  /// A document of [jsObject].
  PickerDataDocument(this.picker, this.jsObject);

  /// Url.
  String? get url => _getString(jsObject, picker!.document.url);

  /// Description.
  String? get description => _getString(jsObject, picker!.document.description);

  /// Drive id.
  String? get id => _getString(jsObject, picker!.document.id);

  /// Mime type.
  String? get mimeType => _getString(jsObject, picker!.document.mimeType);

  /// Name.
  String? get name => _getString(jsObject, picker!.document.name);

  /// Version.
  int? get version => _getInt(jsObject, picker!.document.version);

  /// The non null fields.
  Map asMap() {
    var map = <String, Object?>{};
    if (url != null) {
      map['url'] = url;
    }
    if (id != null) {
      map['id'] = id;
    }
    if (name != null) {
      map['name'] = name;
    }
    if (version != null) {
      map['version'] = version;
    }
    if (description != null) {
      map['description'] = description;
    }
    if (mimeType != null) {
      map['mimeType'] = mimeType;
    }
    return map;
  }
}

/// The picked documents.
class PickerDataDocuments {
  /// The javascript array, null when the response has none.
  JSArray<JSObject>? jsArray;

  /// The picker namespace.
  GooglePicker? picker;

  /// The documents of [jsArray].
  PickerDataDocuments(this.picker, this.jsArray);

  /// The document at [index].
  PickerDataDocument operator [](int index) =>
      PickerDataDocument(picker, jsArray![index]);

  /// The number of documents, 0 when the response has none.
  int get length => jsArray?.length ?? 0;

  /// The documents as maps.
  List<Map> asList() {
    final docs = <Map>[];
    for (var i = 0; i < length; i++) {
      docs.add(this[i].asMap());
    }
    return docs;
  }

  @override
  String toString() {
    return asList().toString();
  }
}

/// A response of the dialog.
class PickerData {
  /// The javascript response.
  JSObject jsObject;

  /// The picker namespace.
  GooglePicker? picker;

  /// A response of [jsObject].
  PickerData(this.picker, this.jsObject);

  /// `gpicker.action.picked`, `gpicker.action.cancel`, `loaded`...
  String? get action => _getString(jsObject, picker!.response.action);
  PickerDataDocuments? _documents;

  /// The documents picked.
  PickerDataDocuments get documents => _documents ??= PickerDataDocuments(
    picker,
    jsObject[picker!.response.documents!] as JSArray<JSObject>?,
  );

  @override
  String toString() {
    var map = <String, Object?>{};
    map['action'] = action;
    if (action == picker!.action.picked) {
      map['documents'] = documents.asList();
    }
    return map.toString();
  }
}

// {DOCS: all, DOCS_IMAGES: docs-images, DOCS_IMAGES_AND_VIDEOS: docs-images-and-videos, DOCS_VIDEOS: docs-videos, DOCUMENTS: documents, DRAWINGS: drawings, FOLDERS: folders, FORMS: forms, IMAGE_SEARCH: image-search, MAPS: maps, PDFS: pdfs, PHOTO_ALBUMS: photo-albums, PHOTOS: photos, PHOTO_UPLOAD: photo-upload, PRESENTATIONS: presentations, RECENTLY_PICKED: recently-picked, SPREADSHEETS: spreadsheets, VIDEO_SEARCH: video-search, WEBCAM: webcam, YOUTUBE: youtube}
/// `google.picker.ViewId`: read any other id from [jsObject]
/// (`(viewId.jsObject!['SPREADSHEETS'] as JSString).toDart`).
class ViewId {
  /// The javascript constants.
  JSObject? jsObject;

  /// The constants of [jsObject].
  ViewId(this.jsObject);

  /// Photos.
  String? get photos => _getString(jsObject, 'PHOTOS');

  /// Drive documents.
  String? get docs => _getString(jsObject, 'DOCS');

  /// Use [photos].
  @Deprecated('Use photos')
  // ignore: non_constant_identifier_names
  String? get PHOTOS => photos;

  /// Use [docs].
  @Deprecated('Use docs')
  // ignore: non_constant_identifier_names
  String? get DOCS => docs;
}

/// `google.picker.Action`.
class PickerAction {
  /// The javascript constants.
  JSObject? jsObject;

  /// The constants of [jsObject].
  PickerAction(this.jsObject);

  /// Picked.
  String? get picked => _getString(jsObject, 'PICKED');

  /// Cancel.
  String? get cancel => _getString(jsObject, 'CANCEL');

  /// Use [picked].
  @Deprecated('Use picked')
  // ignore: non_constant_identifier_names
  String? get PICKED => picked;

  /// Use [cancel].
  @Deprecated('Use cancel')
  // ignore: non_constant_identifier_names
  String? get CANCEL => cancel;
}

/// `google.picker.Response`.
class PickerResponse {
  /// The javascript constants.
  JSObject? jsObject;

  /// The constants of [jsObject].
  PickerResponse(this.jsObject);

  /// The key of the action.
  String? get action => _getString(jsObject, 'ACTION');

  /// The key of the documents.
  String? get documents => _getString(jsObject, 'DOCUMENTS');

  /// Use [action].
  @Deprecated('Use action')
  // ignore: non_constant_identifier_names
  String? get ACTION => action;

  /// Use [documents].
  @Deprecated('Use documents')
  // ignore: non_constant_identifier_names
  String? get DOCUMENTS => documents;
}

/// `google.picker.Feature`.
class PickerFeature {
  final JSObject? _jsObject;

  /// The constants of a javascript object.
  PickerFeature(this._jsObject);

  /// Several documents can be picked.
  String? get multiSelectEnabled =>
      _getString(_jsObject, 'MULTISELECT_ENABLED');

  /// Use [multiSelectEnabled].
  @Deprecated('Use multiSelectEnabled')
  // ignore: non_constant_identifier_names
  String? get MULTISELECT_ENABLED => multiSelectEnabled;
}

/// `google.picker.Document`: the keys of a picked document.
class PickerDocument {
  /// The javascript constants.
  JSObject? jsObject;

  /// The constants of [jsObject].
  PickerDocument(this.jsObject);

  /// Url key.
  String? get url => _getString(jsObject, 'URL');

  /// Description key.
  String? get description => _getString(jsObject, 'DESCRIPTION');

  /// Id key.
  String? get id => _getString(jsObject, 'ID');

  /// Mime type key.
  String? get mimeType => _getString(jsObject, 'MIME_TYPE');

  /// Version key.
  String? get version => _getString(jsObject, 'VERSION');

  /// Name key.
  String? get name => _getString(jsObject, 'NAME');

  /// Use [url].
  @Deprecated('Use url')
  // ignore: non_constant_identifier_names
  String? get URL => url;

  /// Use [description].
  @Deprecated('Use description')
  // ignore: non_constant_identifier_names
  String? get DESCRIPTION => description;

  /// Use [id].
  @Deprecated('Use id')
  // ignore: non_constant_identifier_names
  String? get ID => id;

  /// Use [mimeType].
  @Deprecated('Use mimeType')
  // ignore: non_constant_identifier_names
  String? get MIME_TYPE => mimeType;

  /// Use [version].
  @Deprecated('Use version')
  // ignore: non_constant_identifier_names
  String? get VERSION => version;

  /// Use [name].
  @Deprecated('Use name')
  // ignore: non_constant_identifier_names
  String? get NAME => name;
}

/// The `google.picker` namespace, from [loadPicker].
class GooglePicker {
  /// The scope of the files created or opened by the app.
  static const String scopeDriveAppFile =
      'https://www.googleapis.com/auth/drive.file';

  /// Use [scopeDriveAppFile].
  @Deprecated('Use scopeDriveAppFile')
  // ignore: constant_identifier_names
  static const String SCOPE_DRIVE_APP_FILE = scopeDriveAppFile;

  /// The javascript namespace.
  JSObject? jsObject;

  PickerAction? _action;

  /// The actions.
  PickerAction get action =>
      _action ??= PickerAction(jsObject!['Action'] as JSObject?);

  PickerResponse? _response;

  /// The response keys.
  PickerResponse get response =>
      _response ??= PickerResponse(jsObject!['Response'] as JSObject?);

  PickerDocument? _document;

  /// The document keys.
  PickerDocument get document =>
      _document ??= PickerDocument(jsObject!['Document'] as JSObject?);

  PickerFeature? _feature;

  /// The features.
  PickerFeature get feature =>
      _feature ??= PickerFeature(jsObject!['Feature'] as JSObject?);

  ViewId? _viewId;

  /// The view ids.
  ViewId get viewId => _viewId ??= ViewId(jsObject!['ViewId'] as JSObject?);

  JSFunction? get _pickerBuilderConstructor =>
      jsObject!['PickerBuilder'] as JSFunction?;

  JSFunction? get _pickerViewConstructor => jsObject!['View'] as JSFunction?;

  JSFunction? get _pickerDocsViewConstructor =>
      jsObject!['DocsView'] as JSFunction?;

  /// The namespace of [jsObject] (`window.google.picker`).
  GooglePicker(this.jsObject);
}

GooglePicker? _picker;

/// Loads the `picker` module with [gapi] (`loadGapiPlatform()`), once: later
/// calls return the first [GooglePicker].
Future<GooglePicker> loadPicker(Gapi? gapi) {
  if (_picker == null) {
    return gapi!.load('picker').then((_) {
      var google = globalContext['google'] as JSObject;
      return _picker = GooglePicker(google['picker'] as JSObject?);
    });
  }
  return Future.sync(() => _picker!);
}
