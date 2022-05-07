// ignore_for_file: use_key_in_widget_constructors
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:smart_cap_user/Services/settings_service.dart';
import 'package:smart_cap_user/Services/translation_service.dart';
import 'package:smart_cap_user/Utilities/RoutesManagement/pages.dart';
import 'package:smart_cap_user/dataprovider/appdata.dart';
import 'package:smart_cap_user/globalvariable.dart';
import 'package:smart_cap_user/screens/LogIn/login_binding.dart';
import 'package:smart_cap_user/screens/LogIn/loginpage.dart';
import 'package:smart_cap_user/screens/SignUp/signUpView.dart';
import 'package:smart_cap_user/screens/mainPage/mainpage.dart';
import 'package:smart_cap_user/screens/splash/splash_binding.dart';
import 'package:smart_cap_user/screens/splash/splash_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Get.putAsync(() => SettingsService().init());
  LogInBinding().dependencies();
  SplashBinding().dependencies();
  await GetStorage.init();
  currentFirebaseUser = FirebaseAuth.instance.currentUser;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppData(),
      child: GetMaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        debugShowCheckedModeBanner: false,
        translations: TranslationService(),
        locale: SettingsService().getLocale(),
        fallbackLocale: TranslationService.fallbackLocale,
        theme: Get.find<SettingsService>().getLightTheme(),
        getPages: AppPages.routes,
        home: currentFirebaseUser == null
            ? const LoginPage()
            : const SplashView(),
        routes: {
          SignUpView.id: (context) => SignUpView(),
          LoginPage.id: (context) => const LoginPage(),
          MainPage.id: (context) => MainPage(),
        },
      ),
    );
  }
}
