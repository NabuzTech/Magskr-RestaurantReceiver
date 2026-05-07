import 'package:get/get.dart';

import '../constants/params_args.dart';
import '../controller/AppController.dart';
import '../controller/MapController.dart';
import '../controller/WidgetController.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AppController(), tag: ParamsArgus.APP, fenix: true);
    Get.lazyPut(() => MapController(), tag: ParamsArgus.APP, fenix: true);
    Get.lazyPut(() => WidgetController(), tag: ParamsArgus.WIDGET, fenix: true);
  }
}
