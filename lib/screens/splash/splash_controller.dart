import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:smart_cap_user/Services/AuthenticationService/Core/manager.dart';
import 'package:smart_cap_user/Utilities/Constants/AppColors.dart';
import 'package:smart_cap_user/helpers/helpermethods.dart';
import 'package:smart_cap_user/screens/LogIn/login_binding.dart';
import 'package:smart_cap_user/screens/LogIn/loginpage.dart';

class SplashController extends GetxController {
  AuthenticationManager authManager = Get.find();

  @override
  void onInit() async {
    HelperMethods.getCurrentUserInfo();
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {}
    } on SocketException catch (_) {
      authManager.commonTools.showFailedSnackBar('No internet connectivity');
    }
    super.onInit();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    Get.to(() => const LoginPage(), binding: LogInBinding());
  }

  Scaffold waitingView() {
    return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(
          child: SvgPicture.asset(
            'images/karaz_logo.svg',
            width: Get.width * 0.4,
            height: Get.width * 0.4,
          ),
        ));
  }
}
