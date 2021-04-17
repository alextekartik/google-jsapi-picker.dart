library google_jsapi_example;

import 'dart:async';
import 'dart:html';

import 'package:googleapis_auth/auth_browser.dart';
import 'package:synchronized/synchronized.dart';
import 'package:tekartik_browser_utils/browser_utils_import.dart';
import 'package:tekartik_google_jsapi/gapi.dart';
import 'package:tekartik_google_jsapi/gapi_auth2.dart';
import 'package:tekartik_google_jsapi_picker/picker.dart';

import 'test_config.dart';
import 'test_setup.dart';

GapiAuth2? gapiAuth;
GooglePicker? gpicker;

Storage storage = window.localStorage;

String storageKeyPref = 'com.tekartik.google_jsapi_picker_example';

String? storageGet(String key) {
  return storage['$storageKeyPref.$key'];
}

void storageSet(String key, String? value) {
  var prefKey = '$storageKeyPref.$key';
  if (value == null) {
    storage.remove(prefKey);
  } else {
    storage[prefKey] = value;
  }
}

String appAuthAutoAuth = 'auth_autoauth'; // boolean
String appAuthApprovalPromptKey = 'auth_approval_prompt'; // boolean
String appMimeTypesKey = 'mime_types';
String selectFolderEnabledKey = 'select_folder_enabled';
String includeFoldersKey = 'include_folders';

Element? pickResult;
String? _authToken;
InputElement? mimeTypesInput;

void _pick() {
  final mimeTypesText = mimeTypesInput!.value!;
  storageSet(appMimeTypesKey, mimeTypesText);

  final builder = PickerBuilder(gpicker);

  PickerView pickerView;

  final selectFolderEnabled =
      storageGet(selectFolderEnabledKey) == true.toString();
  final includeFolders = storageGet(includeFoldersKey) == true.toString();

  print('selectFolderEnbled: $selectFolderEnabled');
  print('includeFolders: $includeFolders');
  // use docs view for folder
  if (selectFolderEnabled || includeFolders) {
    final pickerDocsView = PickerDocsView(gpicker!, gpicker!.viewId.docs);
    pickerDocsView.selectFolderEnabled = true;
    pickerDocsView.includeFolders = true;
    pickerView = pickerDocsView;
  } else {
    pickerView = PickerView(gpicker!, gpicker!.viewId.docs);
  }
  final mimeTypes = mimeTypesText.split(',');
  if (mimeTypes.isNotEmpty && mimeTypes[0].isNotEmpty) {
    pickerView.mimeTypes = mimeTypes;
  }

  builder.addView(pickerView);

  builder.developerKey = appOptions!.developerKey;
  builder.oauthToken = _authToken;
  final uiPicker = builder.build();
  uiPicker.pick().then((PickerDataDocuments docs) {
    pickResult!.innerHtml = docs.toString();

    //pickResult.innerHtml = docs[0].id;
  });
}

void pickerMain(String authToken) {
  authorizeResult!.innerHtml = 'Authorize token $authToken';
  print('token: $authToken');
  _authToken = authToken;

  final pickerForm = querySelector('form.app-picker')!;
  pickResult = pickerForm.querySelector('.app-result');
  pickerForm.classes.remove('hidden');
  mimeTypesInput =
      pickerForm.querySelector('input#appInputMimeTypes') as InputElement?;
  final pickButton = pickerForm.querySelector('button.app-pick')!;

  final selectFolderEnabledInput = pickerForm
      .querySelector('#appInputSelectFolderEnabled') as CheckboxInputElement;
  final selectFolderEnabled =
      storageGet(selectFolderEnabledKey) == true.toString();
  selectFolderEnabledInput.checked = selectFolderEnabled;
  selectFolderEnabledInput.onChange.listen((_) {
    storageSet(
        selectFolderEnabledKey, selectFolderEnabledInput.checked.toString());
  });

  final includeFoldersInput = pickerForm
      .querySelector('#appInputIncludeFolders') as CheckboxInputElement;
  final includeFolders = storageGet(includeFoldersKey) == true.toString();
  includeFoldersInput.checked = includeFolders;
  includeFoldersInput.onChange.listen((_) {
    storageSet(includeFoldersKey, includeFoldersInput.checked.toString());
  });

  mimeTypesInput!.value = storageGet(appMimeTypesKey);

  pickButton.onClick.listen((Event event) {
    event.preventDefault();
    _pick();
  });
}

Element? authorizeResult;
BrowserOAuth2Flow? auth2flow;
AppOptions? appOptions;
final _setupLock = Lock();

Future configSetup() async {
  if (auth2flow == null) {
    await _setupLock.synchronized(() async {
      if (auth2flow == null) {
        appOptions = await setup();

        void _errorSetup() {
          authorizeResult!.innerText = '''
ERROR: Missing clientId, clientSecret or developerKey
Create local.config.yaml from sample.local.config.yaml ($appOptions)''';
        }

        final clientId = appOptions?.clientId;
        final clientSecret = appOptions?.clientSecret;
        if (clientId?.isNotEmpty != true ||
            clientSecret?.isNotEmpty != true ||
            appOptions!.developerKey?.isNotEmpty != true) {
          _errorSetup();
          return;
        }

        var authClientId =
            ClientId(appOptions!.clientId!, appOptions!.clientSecret);
        final scopes = <String>[GooglePicker.scopeDriveAppFile];

        auth2flow?.close();
        auth2flow = await createImplicitBrowserFlow(authClientId, scopes);
      }
    });
  }
}

Future _authorize({bool? auto}) async {
  auto ??= false;
  await configSetup();

  var result = await auth2flow!.runHybridFlow(immediate: auto);
  var oauthToken = result.credentials.accessToken.data;
  pickerMain(oauthToken);
}

void authMain() {
  final authForm = querySelector('form.app-auth')!;
  authForm.classes.remove('hidden');
  final authorizeButton = authForm.querySelector('button.app-authorize')!;

  authorizeResult = authForm.querySelector('.app-result');
  final autoAuthCheckbox =
      authForm.querySelector('.app-autoauth') as CheckboxInputElement;

  authorizeButton.onClick.listen((Event event) {
    event.preventDefault();
    _authorize();
  });

  final autoAuth = storageGet(appAuthAutoAuth) == true.toString();

  autoAuthCheckbox.onChange.listen((_) {
    storageSet(appAuthAutoAuth, autoAuthCheckbox.checked.toString());
  });

  autoAuthCheckbox.checked = autoAuth;
  if (autoAuth) {
    _authorize(auto: true);
  }
}

Element? loadGapiResult;

Future _loadPicker() async {
  loadGapiResult!.innerHtml = 'loading Gapi...';
  try {
    final gapi = await loadGapiPlatform();
    loadGapiResult!.innerHtml = 'loading GooglePicker...';
    gpicker = await loadPicker(gapi);
    loadGapiResult!.innerHtml = 'GooglePicker loaded';
  } catch (e) {
    loadGapiResult!.innerHtml = 'load failed $e';
    rethrow;
  }
  authMain();
}

Future main() async {
  final loadGapiForm = querySelector('form.app-gapi')!;
  loadGapiResult = loadGapiForm.querySelector('.app-result');

  await await _loadPicker();
  authMain();
}
