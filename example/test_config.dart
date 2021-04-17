library test_config;

class AppOptions {
  // The developer key needed for the picker API
  String? developerKey;
  // The Client ID obtained from the Google Cloud Console.
  String? clientId;
  // The Client Secret obtained from the Google Cloud Console.
  String? clientSecret;

  AppOptions.fromMap(Map<String, dynamic> map) {
    developerKey = map['developerKey']?.toString();
    clientId = map['clientId']?.toString();
    clientSecret = map['clientSecret']?.toString();
  }

  @override
  String toString() => {
        'developerKey': developerKey,
        'clientId': clientId,
        'clientSecret': clientSecret
      }.toString();
}
