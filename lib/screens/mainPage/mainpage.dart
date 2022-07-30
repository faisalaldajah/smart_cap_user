// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, prefer_final_fields, non_constant_identifier_names, deprecated_member_use, sized_box_for_whitespace, missing_return, prefer_const_literals_to_create_immutables

import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_cap_user/globalvariable.dart';
import 'package:smart_cap_user/screens/mainPage/main_page_controller.dart';
import 'package:smart_cap_user/widgets/MainMenuWidget/MenuButton.dart';
import 'package:smart_cap_user/widgets/MainMenuWidget/RequestSheet.dart';
import 'package:smart_cap_user/widgets/MainMenuWidget/RideDetailsSheet.dart';
import 'package:smart_cap_user/widgets/MainMenuWidget/SearchSheet.dart';
import 'package:smart_cap_user/widgets/MainMenuWidget/TripSheet.dart';
import 'package:smart_cap_user/widgets/TheDrawer.dart';

// ignore: must_be_immutable
class MainPage extends GetView<MainPageController> {
  static const String id = 'mainpage';

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  int markerIdCounter = 0;

  String markerIdVal({bool increment = false}) {
    String val = 'marker_id_$markerIdCounter';
    if (increment) markerIdCounter++;
    return val;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: Container(
        width: 250,
        color: Colors.white,
        child: TheDrawer(controller: controller),
      ),
      body: Obx(
        () => Stack(
          children: <Widget>[
            GoogleMap(
              padding:
                  EdgeInsets.only(bottom: controller.mapBottomPadding.value),
              mapType: MapType.normal,
              myLocationButtonEnabled: true,
              initialCameraPosition: googlePlex,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,
              polylines: controller.polylines,
              markers: controller.markers,
              circles: controller.circles,
              onMapCreated: (GoogleMapController? googleMapController) {
                controller.googleMapController.complete(googleMapController);
                controller.mapController!.value = googleMapController!;
                controller.mapBottomPadding.value =
                    (Platform.isAndroid) ? 280 : 270;
              },
            ),

            ///MenuButtonDraewr
            Positioned(
              top: 44,
              left: 20,
              child: GestureDetector(
                onTap: () {
                  if (controller.drawerCanOpen.value &&
                      controller.locationOnMap.value == false) {
                    scaffoldKey.currentState!.openDrawer();
                  } else {
                    controller.resetApp();
                  }
                },
                child: MenuButton(),
              ),
            ),

            /// SearchSheet
            Positioned(left: 0, right: 0, bottom: 0, child: SearchSheet()),

            /// RideDetailsSheet
            Positioned(left: 0, right: 0, bottom: 0, child: RideDetailsSheet()),

            /// RequestSheet
            Positioned(left: 0, right: 0, bottom: 0, child: RequestSheet()),

            /// TripSheet
            Positioned(left: 0, right: 0, bottom: 0, child: TripSheet()),

            ///Location from map
            (controller.locationOnMap.value)
                ? Positioned(
                    top: 225,
                    right: 165,
                    child: Image.asset('images/desticon.png'),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
