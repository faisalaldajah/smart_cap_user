import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_cap_user/datamodels/user.dart';

String serverKey =
    'key=AAAAfSv3M30:APA91bGsv2U2KFDn-hGhSyGn5chdUsPRkERjZoDc05H4RoM6_bqL3Sl43Eb5X2lL5RjhfxzuCV1wxRdq55Xs2mDtq_aRihj2kZNVdYRB9eS6WV0nqjBGM4pY7qG1N4fi4UvnxTWFGFMU';

String mapKey = 'AIzaSyALY906rdwqFYGffSyDo-j3OOAPdGUoscA';

const CameraPosition googlePlex = CameraPosition(
  target: LatLng(31.954066, 35.931066),
  zoom: 14.4746,
);
User? currentFirebaseUser;
LatLng? pos;
UserData? currentUserInfo;
RxBool homeAddresscheck = false.obs;

String driverCarStyle = '';
var geoLocator = Geolocator();
Position? currentPosition;
late GoogleMapController mapController;
RxString homeAddress = ''.obs;
//LatLng(31.954066, 35.931066)