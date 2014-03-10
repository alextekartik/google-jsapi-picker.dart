library all_test_browser;

import 'package:unittest/html_config.dart';
import 'all_test.dart' as all_test;

main() {
  useHtmlConfiguration();
  all_test.main();
}

