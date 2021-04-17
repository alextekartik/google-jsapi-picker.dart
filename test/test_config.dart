library test_config;

class AppOptions {
  // The developer key needed for the picker API
  String? developerKey;
  // The Client ID obtained from the Google Cloud Console.
  String? clientId;

  AppOptions.fromMap(Map<String, dynamic> map) {
    developerKey = map['developerKey']?.toString();
    clientId = map['clientId']?.toString();
  }
}
