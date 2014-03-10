google-jsapi-picker.dart
========================

Google File picker access from Dart

[Online demo](http://gstest.tekartik.com/google-jsapi-picker/example/google_jsapi_picker_example.html)

### Description

Dart library to use for Google File Picker jsapi / Client-side flow

### Usage/Installation

Go to [Google APIs Console](https://code.google.com/apis/console/) and create a new Project
Create a new `Client ID` for web applications in "API Access"
Set JavaScript origins to your server or for example `http://127.0.0.1:3030/` for local testing in Dartium

Add this dependency to your pubspec.yaml

```
  dependencies:
     tekartik_google_jsapi_picker:
       git: https://github.com/alextekartik/google-jsapi.dart.git
```


### Web applications

Import the library in your dart application

```
  import "package:tekartik_jsapi_picker/picker.dart";
```

Initialize the library with your parameters

### Pick files

```
  PickerBuilder builder = new PickerBuilder(gpicker);
  
  PickerView pickerView = new PickerView(gpicker, gpicker.viewId.DOCS);
  builder.addView(pickerView); 
  
  builder.developerKey = DEVELOPER_KEY;
  builder.oauthToken = _authToken;
  
  Picker uiPicker = builder.build();
  uiPicker.pick().then((PickerDataDocuments docs) {
    ...
    // handle the docs here
    print(docs);
    ... 
  
  });
```
