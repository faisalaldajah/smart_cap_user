import 'package:get/get.dart';
import 'package:smart_cap_user/Services/AuthenticationService/Core/manager.dart';
import 'package:smart_cap_user/screens/LogIn/login_controller.dart';

class LogInBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LogInController>(() => LogInController());
    Get.lazyPut<AuthenticationManager>(() => AuthenticationManager());
  }
}
