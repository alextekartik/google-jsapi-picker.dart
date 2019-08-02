import 'dart:async';

import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  print('http://localhost:8081/google_jsapi_picker_example.html');
  await shell.run('''
  
  pub global run webdev serve example:8081 --live-reload --hostname 0.0.0.0
  
  ''');
}
