library google_jsapi_example;

import 'dart:html';
import 'package:tekartik_google_jsapi/google_jsapi.dart';
import 'package:tekartik_google_jsapi_picker/picker.dart';

Gapi gapi;
GooglePicker gpicker;

Storage storage = window.localStorage;

String _STORAGE_KEY_PREF = 'com.tekartik.google_jsapi_picker_example';
dynamic storageGet(String key) {
  return storage['$_STORAGE_KEY_PREF.$key'];
}
void storageSet(String key, String value) {
  if (value == null) {
    storage.remove(key);
  } else {
    storage['$_STORAGE_KEY_PREF.$key'] = value;
  }
}

String AUTH_AUTO_AUTH = 'auth_autoauth'; // boolean
String AUTH_APPROVAL_PROMPT = 'auth_approval_prompt'; // boolean
String CLIENT_ID_KEY = 'client_id';
String DEVELOPER_KEY_KEY = 'developer_key';
String MIME_TYPES_KEY = 'mime_types';
String SELECT_FOLDER_ENABLED_KEY = 'select_folder_enabled';
String INCLUDE_FOLDERS_KEY = 'include_folders';

InputElement developerKeyInput;
Element pickResult;
String _authToken;
InputElement mimeTypesInput;

void _pick() {
  String mimeTypesText = mimeTypesInput.value;
  storageSet(MIME_TYPES_KEY, mimeTypesText);



  String developerKey = developerKeyInput.value;
  storageSet(DEVELOPER_KEY_KEY, developerKey);

  PickerBuilder builder = new PickerBuilder(gpicker);

  PickerView pickerView;

  bool selectFolderEnabled = storageGet(SELECT_FOLDER_ENABLED_KEY) ==
      true.toString();
  bool includeFolders = storageGet(INCLUDE_FOLDERS_KEY) ==
        true.toString();
  
  print('selectFolderEnbled: $selectFolderEnabled');
  print('includeFolders: $includeFolders');
  // use docs view for folder
  if (selectFolderEnabled || includeFolders) {
    PickerDocsView pickerDocsView = new PickerDocsView(gpicker,
        gpicker.viewId.DOCS);
    pickerDocsView.selectFolderEnabled = true;
    pickerDocsView.includeFolders = true;
    pickerView = pickerDocsView;
  } else {
    pickerView = new PickerView(gpicker, gpicker.viewId.DOCS);
  }
  List<String> mimeTypes = mimeTypesText.split(',');
  if (mimeTypes.length >= 1 && mimeTypes[0].length > 0) {
    pickerView.mimeTypes = mimeTypes;
  }

  builder.addView(pickerView);

  builder.developerKey = developerKey;
  builder.oauthToken = _authToken;
  Picker uiPicker = builder.build();
  uiPicker.pick().then((PickerDataDocuments docs) {
    pickResult.innerHtml = docs.toString();

    //pickResult.innerHtml = docs[0].id;
  });
}
void pickerMain(String authToken) {
  _authToken = authToken;

  Element pickerForm = querySelector('form.app-picker');
  pickResult = pickerForm.querySelector('.app-result');
  pickerForm.classes.remove('hidden');
  developerKeyInput = pickerForm.querySelector('input#appInputDeveloperKey');
  mimeTypesInput = pickerForm.querySelector('input#appInputMimeTypes');
  Element pickButton = pickerForm.querySelector('button.app-pick');

  CheckboxInputElement selectFolderEnabledInput = pickerForm.querySelector(
      '#appInputSelectFolderEnabled');
  bool selectFolderEnabled = storageGet(SELECT_FOLDER_ENABLED_KEY) ==
      true.toString();
  selectFolderEnabledInput.checked = selectFolderEnabled;
  selectFolderEnabledInput.onChange.listen((_) {
    storageSet(SELECT_FOLDER_ENABLED_KEY,
        selectFolderEnabledInput.checked.toString());
  });
  
  CheckboxInputElement includeFoldersInput = pickerForm.querySelector(
       '#appInputIncludeFolders');
   bool includeFolders = storageGet(INCLUDE_FOLDERS_KEY) ==
       true.toString();
   includeFoldersInput.checked = includeFolders;
   includeFoldersInput.onChange.listen((_) {
     storageSet(INCLUDE_FOLDERS_KEY,
                includeFoldersInput.checked.toString());
   });

  developerKeyInput.value = storageGet(DEVELOPER_KEY_KEY);
  mimeTypesInput.value = storageGet(MIME_TYPES_KEY);

  pickButton.onClick.listen((Event event) {
    event.preventDefault();
    _pick();

  });
}

Element authorizeResult;
InputElement clientIdInput;

void _authorize() {
  String clientId = clientIdInput.value;
  if (clientId.length < 1) {
    authorizeResult.innerHtml = 'Missing CLIENT ID';
    return;
  }
  storageSet(CLIENT_ID_KEY, clientId);

  String approvalPrompt = storageGet(AUTH_APPROVAL_PROMPT);
  List<String> scopes = [GooglePicker.SCOPE_DRIVE_APP_FILE];
  gapi.auth.authorize(clientId, scopes, approvalPrompt: approvalPrompt).then(
      (String oauthToken) {
    authorizeResult.innerHtml =
        "client id '$clientId' authorized for '$scopes'";
    pickerMain(oauthToken);
  });
}
void authMain() {
  Element authForm = querySelector('form.app-auth');
  authForm.classes.remove('hidden');
  Element authorizeButton = authForm.querySelector('button.app-authorize');
  clientIdInput = authForm.querySelector('input#appInputClientId');

  authorizeResult = authForm.querySelector('.app-result');
  CheckboxInputElement approvalPromptCheckbox = authForm.querySelector(
      '.app-approval-prompt');
  CheckboxInputElement autoAuthCheckbox = authForm.querySelector('.app-autoauth'
      );

  clientIdInput.value = storageGet(CLIENT_ID_KEY);

  String approvalPrompt = storageGet(AUTH_APPROVAL_PROMPT);

  approvalPromptCheckbox.checked = (approvalPrompt ==
      GapiAuth.APPROVAL_PROMPT_FORCE);

  authorizeButton.onClick.listen((Event event) {
    event.preventDefault();
    _authorize();

  });

  approvalPromptCheckbox.onChange.listen((_) {
    approvalPrompt = approvalPromptCheckbox.checked ?
        GapiAuth.APPROVAL_PROMPT_FORCE : null;
    storageSet(AUTH_APPROVAL_PROMPT, approvalPrompt);
  });


  bool autoAuth = storageGet(AUTH_AUTO_AUTH) == true.toString();

  autoAuthCheckbox.checked = autoAuth;
  if (autoAuth) {
    _authorize();
  }

  autoAuthCheckbox.onChange.listen((_) {
    storageSet(AUTH_AUTO_AUTH, autoAuthCheckbox.checked.toString());
  });
}

Element loadGapiResult;

void _loadPicker() {
  loadGapiResult.innerHtml = 'loading Gapi...';
  loadGapi().then((Gapi gapi_) {
    gapi = gapi_;
    loadGapiResult.innerHtml = 'loading GooglePicker...';
    return loadPicker(gapi_).then((GooglePicker _picker) {
      gpicker = _picker;
      loadGapiResult.innerHtml = 'GooglePicker loaded';
      authMain();
    });

  }, onError: (e, st) {
    loadGapiResult.innerHtml = 'load failed $e';
  });
}
void main() {
  Element loadGapiForm = querySelector('form.app-gapi');
  loadGapiResult = loadGapiForm.querySelector('.app-result');

  _loadPicker();

}
