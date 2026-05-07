import 'package:shared_preferences/shared_preferences.dart';

import '../constants/constant.dart';

class Api {
 // static const baseUrl = "http://62.171.181.21/";
/*  static const baseUrl = "https://magskr.com/";
  static const baseUrlTest = "https://magskr.de/";*/

/*  static const String _prodUrl  = 'https://magskr.com/';
  static const String _testUrl = 'https://magskr.de/';*/
  static const String _prodUrl  = 'https://magskr.com/';
  // Will be filled in `init()`
  static  String _baseUrl='https://magskr.com/';
  static String get baseUrl => _baseUrl;

  /// Call once – e.g. in `main()` – before any network call
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    String? getBaseURl = prefs.getString(valueShared_BASEURL);
    // pick the URL you need
    _baseUrl = getBaseURl ?? _prodUrl;
    // If you also want a staging flag, add more logic here.
  }

}
