library;

class AppOptions {
  // The developer key needed for the picker API
  String? developerKey;
  // The Client ID obtained from the Google Cloud Console.
  String? clientId;
  // The Client Secret obtained from the Google Cloud Console.
  String? clientSecret;

  AppOptions.fromMap(Map<String, dynamic> map) {
    developerKey = (map['developerKey'] ?? map['api_key'])?.toString();
    clientId = (map['clientId'] ?? map['client_id'])?.toString();
    clientSecret = (map['clientSecret'] ?? map['client_secret'])?.toString();
  }

  @override
  String toString() => {
        'developerKey': developerKey,
        'clientId': clientId,
        'clientSecret': clientSecret
      }.toString();
}
