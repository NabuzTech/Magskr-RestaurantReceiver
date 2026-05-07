import 'package:get/get.dart';

import '../splash_screen.dart';
/*import 'package:raxar_project/ui/splash_screen.dart';

import '../ui/home_screen.dart';*/

appRoutes() => [
  GetPage(
    name: '/splash',
    page: () => const SplashScreen(),
    transition: Transition.leftToRightWithFade,
    transitionDuration: const Duration(milliseconds: 500),
  ),
 /* GetPage(
    name: '/home',
    page: () => HomeScreen(),
    middlewares: [MyMiddelware()],
    transition: Transition.leftToRightWithFade,
    transitionDuration: Duration(milliseconds: 500),
  ),*/
 /* GetPage(
    name: '/third',
    page: () => ThirdPage(),
    middlewares: [MyMiddelware()],
    transition: Transition.leftToRightWithFade,
    transitionDuration: Duration(milliseconds: 500),
  ),*/
];

class MyMiddelware extends GetMiddleware {
  @override
  GetPage? onPageCalled(GetPage? page) {
    print(page?.name);
    return super.onPageCalled(page);
  }
}