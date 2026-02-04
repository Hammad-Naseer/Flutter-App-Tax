import 'package:get/get.dart';
import '../features/navigation/nav_controller.dart';
import '../features/dashboard/controller/dashboard_controller.dart';
import '../core/services/update_service.dart';

class InjectionContainer {
  InjectionContainer._();

  static void init() {
    Get.put(NavController(), permanent: true);
    Get.put(DashboardController(), permanent: true);
    Get.put(UpdateService(), permanent: true);
  }
}
