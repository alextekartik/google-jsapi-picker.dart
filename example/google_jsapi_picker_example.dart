// ignore_for_file: deprecated_member_use_from_same_package, deprecated_member_use

library;

//import 'dart:html';
import 'dart:js_interop';

import 'package:googleapis_auth/auth_browser.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_google_jsapi/gapi.dart';
import 'package:tekartik_google_jsapi/gapi_auth2.dart';
import 'package:tekartik_google_jsapi_picker/picker.dart';
import 'package:web/web.dart' as web;
import 'test_config.dart';
import 'test_setup.dart';

GapiAuth2? gapiAuth;
GooglePicker? gpicker;

web.Element? authorizeResult;
AppOptions? appOptions;
ClientId? authClientId;
final _setupLock = Lock();
web.Storage storage = web.window.localStorage;

String storageKeyPref = 'com.tekartik.google_jsapi_picker_example';

String? storageGet(String key) {
  return storage['$storageKeyPref.$key'];
}

void storageSet(String key, String? value) {
  var prefKey = '$storageKeyPref.$key';
  if (value == null) {
    storage.removeItem(prefKey);
  } else {
    storage[prefKey] = value;
  }
}

String appAuthAutoAuth = 'auth_autoauth'; // boolean
String appAuthApprovalPromptKey = 'auth_approval_prompt'; // boolean
String appMimeTypesKey = 'mime_types';
String selectFolderEnabledKey = 'select_folder_enabled';
String includeFoldersKey = 'include_folders';

web.Element? pickResult;
String? _authToken;
web.HTMLInputElement? mimeTypesInput;

void _pick() {
  final mimeTypesText = mimeTypesInput!.value;
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
    pickResult!.innerHTML = docs.toString().toJS;

    //pickResult.innerHtml = docs[0].id;
  });
}

void pickerMain(String authToken) {
  authorizeResult!.innerHTML = 'Authorize token $authToken'.toJS;
  print('token: $authToken');
  _authToken = authToken;

  final pickerForm = web.document.querySelector('form.app-picker')!;
  pickResult = pickerForm.querySelector('.app-result');
  pickerForm.classList.remove('hidden');
  mimeTypesInput =
      pickerForm.querySelector('input#appInputMimeTypes')
          as web.HTMLInputElement?;
  final pickButton = pickerForm.querySelector('button.app-pick')!;

  final selectFolderEnabledInput =
      pickerForm.querySelector('#appInputSelectFolderEnabled')
          as web.HTMLInputElement;
  final selectFolderEnabled =
      storageGet(selectFolderEnabledKey) == true.toString();
  selectFolderEnabledInput.checked = selectFolderEnabled;
  selectFolderEnabledInput.onChange.listen((_) {
    storageSet(
      selectFolderEnabledKey,
      selectFolderEnabledInput.checked.toString(),
    );
  });

  final includeFoldersInput =
      pickerForm.querySelector('#appInputIncludeFolders')
          as web.HTMLInputElement;
  final includeFolders = storageGet(includeFoldersKey) == true.toString();
  includeFoldersInput.checked = includeFolders;
  includeFoldersInput.onChange.listen((_) {
    storageSet(includeFoldersKey, includeFoldersInput.checked.toString());
  });

  mimeTypesInput!.value = storageGet(appMimeTypesKey) ?? '';

  pickButton.onClick.listen((web.Event event) {
    event.preventDefault();
    _pick();
  });
}

Future configSetup() async {
  if (authClientId == null) {
    await _setupLock.synchronized(() async {
      if (authClientId == null) {
        appOptions = await setup();

        void errorSetup() {
          authorizeResult!.textContent = '''
ERROR: Missing clientId, clientSecret or developerKey
Create local.config.yaml from sample.local.config.yaml ($appOptions)''';
        }

        final clientId = appOptions?.clientId;
        final clientSecret = appOptions?.clientSecret;
        if (clientId?.isNotEmpty != true ||
            clientSecret?.isNotEmpty != true ||
            appOptions!.developerKey?.isNotEmpty != true) {
          errorSetup();
          return;
        }

        authClientId = ClientId(
          appOptions!.clientId!,
          appOptions!.clientSecret,
        );

        // auth2flow = await createImplicitBrowserFlow(authClientId, scopes);
      }
    });
  }
}

Future _authorize({bool? auto}) async {
  auto ??= false;
  await configSetup();

  final scopes = <String>[GooglePicker.scopeDriveAppFile];

  var accessCredentials = await requestAccessCredentials(
    clientId: authClientId!.identifier,
    scopes: scopes,
  );
  print('accessCredentials: $accessCredentials');
  print('accessCredentials: ${accessCredentials.accessToken.data}');
  print('accessCredentials: ${accessCredentials.refreshToken}');

  //var result = await auth2flow!.runHybridFlow(immediate: auto);
  var oauthToken = accessCredentials.accessToken.data;
  pickerMain(oauthToken);
}

void authMain() {
  final authForm = web.document.querySelector('form.app-auth')!;
  authForm.classList.remove('hidden');
  final authorizeButton = authForm.querySelector('button.app-authorize')!;

  authorizeResult = authForm.querySelector('.app-result');
  final autoAuthCheckbox =
      authForm.querySelector('.app-autoauth') as web.HTMLInputElement;

  authorizeButton.onClick.listen((web.Event event) {
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

late web.Element loadGapiResult;

Future _loadPicker() async {
  loadGapiResult.textContent = 'loading Gapi...';
  try {
    final gapi = await loadGapiPlatform();
    loadGapiResult.textContent = 'loading GooglePicker...';
    gpicker = await loadPicker(gapi);
    loadGapiResult.textContent = 'GooglePicker loaded';
  } catch (e) {
    loadGapiResult.textContent = 'load failed $e';
    rethrow;
  }
  authMain();
}

Future main() async {
  final loadGapiForm = web.document.querySelector('form.app-gapi')!;
  loadGapiResult = loadGapiForm.querySelector('.app-result')!;

  await await _loadPicker();
  authMain();
}
