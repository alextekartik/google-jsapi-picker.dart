library gapi_picker;

import 'dart:async';
import 'dart:js';

import 'package:tekartik_google_jsapi/gapi.dart';

// https://developers.google.com/picker/docs/results

class Picker {
  GooglePicker picker;
  JsObject _jsObject;

  Picker._(this.picker);

  /// Single stream controller
  ///
  /// only onData is called
  Stream<PickerData> get stream {
    return ctlr.stream;
  }

  StreamController<PickerData> ctlr = StreamController();

  void _callback(JsObject jsData) {
    //print(jsObjectAsMap(jsData));
    final data = PickerData(picker, jsData);
    ctlr.add(data);
  }

  set visible(bool _visible) {
    _jsObject.callMethod('setVisible', [_visible]);
  }

  /// Return Future<null> on cancel
  Future<PickerDataDocuments> pick() {
    final completer = Completer<PickerDataDocuments>();
    visible = true;
    stream.listen((PickerData data) {
      // print(data);
      if (data.action == picker.action.cancel) {
        completer.completeError(const GapiException('cancel'));
      }
      if (data.action == picker.action.picked) {
        completer.complete(data.documents);
      }
    }).onError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }
}

class PickerView {
  JsObject _jsObject;

  PickerView._();

  PickerView(GooglePicker picker, String viewId) {
    _jsObject = JsObject(picker._pickerViewConstructor, [viewId]);
  }

  JsObject get jsPickerView => _jsObject;

  set mimeTypes(List<String> mimeTypes) {
    _jsObject.callMethod('setMimeTypes', [mimeTypes.join(',')]);
  }
}

class PickerDocsView extends PickerView {
  PickerDocsView(GooglePicker picker, String viewId) : super._() {
    _jsObject = JsObject(picker._pickerDocsViewConstructor, [viewId]);
  }

  @override
  JsObject get jsPickerView => _jsObject;

  set selectFolderEnabled(bool enabled) {
    _jsObject.callMethod('setSelectFolderEnabled', [enabled]);
  }

  set includeFolders(bool include) {
    _jsObject.callMethod('setIncludeFolders', [include]);
  }
}

class PickerBuilder {
  JsObject jsPickerBuilder;
  GooglePicker gpicker;

  PickerBuilder(this.gpicker) {
    jsPickerBuilder = JsObject(gpicker._pickerBuilderConstructor);
  }

  void addView(PickerView view) {
    jsPickerBuilder.callMethod('addView', [view.jsPickerView]);
  }

  void addViewId(String viewId) {
    jsPickerBuilder.callMethod('addView', [viewId]);
  }

  void disableFeature(String feature) {
    jsPickerBuilder.callMethod('disableFeature', [feature]);
  }

  void enableFeature(String feature) {
    jsPickerBuilder.callMethod('enableFeature', [feature]);
  }

  set oauthToken(String _oauthToken) {
    jsPickerBuilder.callMethod('setOAuthToken', [_oauthToken]);
  }

  set developerKey(String _developerKey) {
    jsPickerBuilder.callMethod('setDeveloperKey', [_developerKey]);
  }

  set selectableMimeTypes(List<String> mimeTypes) {
    jsPickerBuilder.callMethod('setSelectableMimeTypes', [mimeTypes.join(',')]);
  }

  Picker build() {
    final picker = Picker._(gpicker);
    jsPickerBuilder.callMethod('setCallback', [picker._callback]);
    final jsPicker = jsPickerBuilder.callMethod('build') as JsObject;
    picker._jsObject = jsPicker;
    return picker;
  }
}

class PickerDataDocument {
  JsObject jsObject;
  GooglePicker picker;

  PickerDataDocument(this.picker, this.jsObject);

  String get url => jsObject[picker.document.url] as String;

  String get description => jsObject[picker.document.description] as String;

  String get id => jsObject[picker.document.id] as String;

  String get mimeType => jsObject[picker.document.mimeType] as String;

  String get name => jsObject[picker.document.name] as String;

  int get version => jsObject[picker.document.version] as int;

  Map asMap() {
    var map = {};
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

class PickerDataDocuments {
  JsArray jsArray;
  GooglePicker picker;

  PickerDataDocuments(this.picker, this.jsArray);

  PickerDataDocument operator [](int index) =>
      PickerDataDocument(picker, jsArray[index] as JsObject);

  int get length => jsArray.length;

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

class PickerData {
  JsObject jsObject;
  GooglePicker picker;

  PickerData(this.picker, this.jsObject);

  String get action => jsObject[picker.response.action] as String;
  PickerDataDocuments _documents;

  PickerDataDocuments get documents => _documents ??= PickerDataDocuments(
      picker, jsObject[picker.response.documents] as JsArray);

  @override
  String toString() {
    var map = {};
    if (jsObject != null) {
      map['action'] = action;
      if (action == picker.action.picked) {
        map['documents'] = documents.asList();
      }
    }
    return map.toString();
  }
}

// {DOCS: all, DOCS_IMAGES: docs-images, DOCS_IMAGES_AND_VIDEOS: docs-images-and-videos, DOCS_VIDEOS: docs-videos, DOCUMENTS: documents, DRAWINGS: drawings, FOLDERS: folders, FORMS: forms, IMAGE_SEARCH: image-search, MAPS: maps, PDFS: pdfs, PHOTO_ALBUMS: photo-albums, PHOTOS: photos, PHOTO_UPLOAD: photo-upload, PRESENTATIONS: presentations, RECENTLY_PICKED: recently-picked, SPREADSHEETS: spreadsheets, VIDEO_SEARCH: video-search, WEBCAM: webcam, YOUTUBE: youtube}
class ViewId {
  JsObject jsObject;

  ViewId(this.jsObject);

  String get photos => jsObject['PHOTOS'] as String;

  String get docs => jsObject['DOCS'] as String;

  @deprecated
  // ignore: non_constant_identifier_names
  String get PHOTOS => jsObject['PHOTOS'] as String;

  @deprecated
  // ignore: non_constant_identifier_names
  String get DOCS => jsObject['DOCS'] as String;
}

class PickerAction {
  JsObject jsObject;

  PickerAction(this.jsObject);

  String get picked => jsObject['PICKED'] as String;

  String get cancel => jsObject['CANCEL'] as String;

  @deprecated
  // ignore: non_constant_identifier_names
  String get PICKED => jsObject['PICKED'] as String;

  @deprecated
  // ignore: non_constant_identifier_names
  String get CANCEL => jsObject['CANCEL'] as String;
}

class PickerResponse {
  JsObject jsObject;

  PickerResponse(this.jsObject);

  String get action => jsObject['ACTION'] as String;

  String get documents => jsObject['DOCUMENTS'] as String;
  @deprecated
  // ignore: non_constant_identifier_names
  String get ACTION => jsObject['ACTION'] as String;
  @deprecated
  // ignore: non_constant_identifier_names
  String get DOCUMENTS => jsObject['DOCUMENTS'] as String;
}

class PickerFeature {
  final _jsObject;

  PickerFeature(this._jsObject);

  String get multiSelectEnabled => _jsObject['MULTISELECT_ENABLED'] as String;

  @Deprecated('Use multiSelectEnabled')
  // ignore: non_constant_identifier_names
  String get MULTISELECT_ENABLED => multiSelectEnabled;
}

class PickerDocument {
  JsObject jsObject;

  PickerDocument(this.jsObject);

  String get url => jsObject['URL'] as String;

  String get description => jsObject['DESCRIPTION'] as String;

  String get id => jsObject['ID'] as String;

  String get mimeType => jsObject['MIME_TYPE'] as String;

  String get version => jsObject['VERSION'] as String;

  String get name => jsObject['NAME'] as String;

  @deprecated
  // ignore: non_constant_identifier_names
  String get URL => jsObject['URL'] as String;

  @deprecated
  // ignore: non_constant_identifier_names
  String get DESCRIPTION => jsObject['DESCRIPTION'] as String;

  @deprecated
  // ignore: non_constant_identifier_names
  String get ID => jsObject['ID'] as String;

  @deprecated
  // ignore: non_constant_identifier_names
  String get MIME_TYPE => jsObject['MIME_TYPE'] as String;

  @deprecated
  // ignore: non_constant_identifier_names
  String get VERSION => jsObject['VERSION'] as String;

  @deprecated
  // ignore: non_constant_identifier_names
  String get NAME => jsObject['NAME'] as String;
}

class GooglePicker {
  static const String scopeDriveAppFile =
      'https://www.googleapis.com/auth/drive.file'; // files created/opened by the app
  @deprecated
  // ignore: constant_identifier_names
  static const String SCOPE_DRIVE_APP_FILE =
      'https://www.googleapis.com/auth/drive.file'; // files created/opened by the app
  JsObject jsObject;

  PickerAction _action;

  PickerAction get action =>
      _action ??= PickerAction(jsObject['Action'] as JsObject);

  PickerResponse _response;

  PickerResponse get response =>
      _response ??= PickerResponse(jsObject['Response'] as JsObject);

  PickerDocument _document;

  PickerDocument get document =>
      _document ??= PickerDocument(jsObject['Document'] as JsObject);

  PickerFeature _feature;

  PickerFeature get feature =>
      _feature ??= PickerFeature(jsObject['Feature'] as JsObject);

  ViewId _viewId;

  ViewId get viewId => _viewId ??= ViewId(jsObject['ViewId'] as JsObject);

  JsFunction get _pickerBuilderConstructor =>
      jsObject['PickerBuilder'] as JsFunction;

  JsFunction get _pickerViewConstructor => jsObject['View'] as JsFunction;

  JsFunction get _pickerDocsViewConstructor =>
      jsObject['DocsView'] as JsFunction;

  GooglePicker(this.jsObject);
}

GooglePicker _picker;

Future<GooglePicker> loadPicker(Gapi gapi) {
  if (_picker == null) {
    return gapi.load('picker').then((_) {
      _picker = GooglePicker(context['google']['picker'] as JsObject);
      return _picker;
    });
  }
  return Future.sync(() => _picker);
}
