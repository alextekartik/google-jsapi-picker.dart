library gapi_picker;

import 'dart:async';
import 'dart:js';

import 'package:tekartik_google_jsapi/gapi.dart';

// https://developers.google.com/picker/docs/results

class Picker {
  GooglePicker picker;
  JsObject _jsObject;

  Picker._(this.picker);

  /**
   * Single stream controller
   * 
   * only onData is called
   */
  Stream<PickerData> get stream {
    return ctlr.stream;
  }

  StreamController<PickerData> ctlr = new StreamController();

  void _callback(JsObject jsData) {
    //print(jsObjectAsMap(jsData));
    PickerData data = new PickerData(picker, jsData);
    ctlr.add(data);
  }

  void set visible(bool _visible) {
    _jsObject.callMethod('setVisible', [_visible]);
  }

  /**
   * Return Future<null> on cancel
   */
  Future<PickerDataDocuments> pick() {
    Completer<PickerDataDocuments> completer = new Completer();
    visible = true;
    stream.listen((PickerData data) {
      // print(data);
      if (data.action == picker.action.CANCEL) {
        completer.completeError(new GapiException("cancel"));
      }
      if (data.action == picker.action.PICKED) {
        completer.complete(data.documents);
      }
    }).onError((e) {
      completer.complete(e);
    });
    return completer.future;
  }



}

class PickerView {
  JsObject _jsObject;

  PickerView._();

  PickerView(GooglePicker picker, String viewId) {
    _jsObject = new JsObject(picker._pickerViewConstructor, [viewId]);
  }
  JsObject get jsPickerView => _jsObject;

  void set mimeTypes(List<String> mimeTypes) {
    _jsObject.callMethod('setMimeTypes', [mimeTypes.join(',')]);
  }
}

class PickerDocsView extends PickerView {

  PickerDocsView(GooglePicker picker, String viewId): super._() {
    _jsObject = new JsObject(picker._pickerDocsViewConstructor, [viewId]);
  }
  JsObject get jsPickerView => _jsObject;

  void set selectFolderEnabled(bool enabled) {
    _jsObject.callMethod('setSelectFolderEnabled', [enabled]);
  }
  void set includeFolders(bool include) {
    _jsObject.callMethod('setIncludeFolders', [include]);
  }
}

class PickerBuilder {
  JsObject jsPickerBuilder;
  GooglePicker gpicker;

  PickerBuilder(this.gpicker) {
    jsPickerBuilder = new JsObject(gpicker._pickerBuilderConstructor);
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

  void set oauthToken(String _oauthToken) {
    jsPickerBuilder.callMethod('setOAuthToken', [_oauthToken]);
  }

  void set developerKey(String _developerKey) {
    jsPickerBuilder.callMethod('setDeveloperKey', [_developerKey]);
  }

  void set selectableMimeTypes(List<String> mimeTypes) {
    jsPickerBuilder.callMethod('setSelectableMimeTypes', [mimeTypes.join(',')]);
  }



  Picker build() {
    Picker picker = new Picker._(gpicker);
    jsPickerBuilder.callMethod('setCallback', [picker._callback]);
    JsObject jsPicker = jsPickerBuilder.callMethod('build');
    picker._jsObject = jsPicker;
    return picker;
  }

}

class PickerDataDocument {
  JsObject jsObject;
  GooglePicker picker;
  PickerDataDocument(this.picker, this.jsObject);

  String get url => jsObject[picker.document.URL];
  String get description => jsObject[picker.document.DESCRIPTION];
  String get id => jsObject[picker.document.ID];
  String get mimeType => jsObject[picker.document.MIME_TYPE];
  String get name => jsObject[picker.document.NAME];
  int get version => jsObject[picker.document.VERSION];

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

  PickerDataDocument operator [](int index) => new PickerDataDocument(picker,
      jsArray[index]);
  int get length => jsArray.length;

  List asList() {
    List<Map> docs = [];
    for (int i = 0; i < length; i++) {
      docs.add(this[i].asMap());
    }
    return docs;
  }

  String toString() {
    return asList().toString();
  }
}

class PickerData {
  JsObject jsObject;
  GooglePicker picker;
  PickerData(this.picker, this.jsObject);

  String get action => jsObject[picker.response.ACTION];
  PickerDataDocuments _documents;
  PickerDataDocuments get documents {
    if (_documents == null) {
      _documents = new PickerDataDocuments(picker,
          jsObject[picker.response.DOCUMENTS]);
    }
    return _documents;
  }

  String toString() {
    var map = {};
    if (jsObject != null) {
      map['action'] = action;
      if (action == picker.action.PICKED) {
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
  String get PHOTOS => jsObject['PHOTOS'];
  String get DOCS => jsObject['DOCS'];
}

class PickerAction {
  JsObject jsObject;
  PickerAction(this.jsObject);
  String get PICKED => jsObject['PICKED'];
  String get CANCEL => jsObject['CANCEL'];
}

class PickerResponse {
  JsObject jsObject;
  PickerResponse(this.jsObject);
  String get ACTION => jsObject['ACTION'];
  String get DOCUMENTS => jsObject['DOCUMENTS'];
}

class PickerFeature {
  JsObject _jsObject;
  PickerFeature(this._jsObject);

  String get MULTISELECT_ENABLED => _jsObject['MULTISELECT_ENABLED'];
}

class PickerDocument {
  JsObject jsObject;
  PickerDocument(this.jsObject);
  String get URL => jsObject['URL'];
  String get DESCRIPTION => jsObject['DESCRIPTION'];
  String get ID => jsObject['ID'];
  String get MIME_TYPE => jsObject['MIME_TYPE'];
  String get VERSION => jsObject['VERSION'];
  String get NAME => jsObject['NAME'];
}

class GooglePicker {

  static const String SCOPE_DRIVE_APP_FILE =
      'https://www.googleapis.com/auth/drive.file'; // files created/opened by the app

  JsObject jsObject;

  PickerAction _action;
  PickerAction get action {
    if (_action == null) {
      _action = new PickerAction(jsObject['Action']);
    }
    return _action;
  }

  PickerResponse _response;
  PickerResponse get response {
    if (_response == null) {
      _response = new PickerResponse(jsObject['Response']);
    }
    return _response;
  }

  PickerDocument _document;
  PickerDocument get document {
    if (_document == null) {
      _document = new PickerDocument(jsObject['Document']);
    }
    return _document;
  }

  PickerFeature _feature;
  PickerFeature get feature {
    if (_feature == null) {
      _feature = new PickerFeature(jsObject['Feature']);
    }
    return _feature;
  }

  ViewId _viewId;
  ViewId get viewId {
    if (_viewId == null) {
      _viewId = new ViewId(jsObject['ViewId']);
    }
    return _viewId;
  }

  JsFunction get _pickerBuilderConstructor => jsObject['PickerBuilder'];
  JsFunction get _pickerViewConstructor => jsObject['View'];
  JsFunction get _pickerDocsViewConstructor => jsObject['DocsView'];


  GooglePicker(this.jsObject);
}

GooglePicker _picker;

Future<GooglePicker> loadPicker(Gapi gapi) {
  if (_picker == null) {
    return gapi.load('picker').then((_) {
      _picker = new GooglePicker(context['google']['picker']);
      return _picker;
    });
  }
  return new Future.sync(() => _picker);
}
