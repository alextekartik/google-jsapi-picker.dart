import 'dart:async';
import 'dart:io';

import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  stdout.writeln('http://localhost:8081/google_jsapi_picker_example.html');
  await shell.run('''
  
  dart pub global run webdev serve example:8081 --auto=refresh --hostname 0.0.0.0
  
  ''');
}
