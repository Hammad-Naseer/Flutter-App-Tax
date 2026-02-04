import 'package:get/get.dart';
import '../../core/constants/app_routes.dart';

class NavController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;
    switch (index) {
      case 0:
        Get.offAllNamed(AppRoutes.dashboard);
        break;
      case 1:
        Get.offAllNamed(AppRoutes.invoices);
        break;
      case 2:
        Get.offAllNamed(AppRoutes.clients);
        break;
      case 3:
        Get.offAllNamed(AppRoutes.more);
        break;
    }
  }
}
