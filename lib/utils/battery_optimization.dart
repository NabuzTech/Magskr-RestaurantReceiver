import 'package:flutter/services.dart';

Future<bool> isIgnoringBatteryOptimizations() async {
  const platform = MethodChannel('com.magskrReciever.app/battery');
  try {
    final bool result = await platform.invokeMethod('isIgnoringBatteryOptimizations');
    return result;
  } on PlatformException {
    return false;
  }
}
