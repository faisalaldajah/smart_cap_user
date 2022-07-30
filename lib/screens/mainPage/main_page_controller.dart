import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smart_cap_user/Services/AuthenticationService/Core/manager.dart';
import 'package:smart_cap_user/brand_colors.dart';
import 'package:smart_cap_user/datamodels/address.dart';
import 'package:smart_cap_user/datamodels/directiondetails.dart';
import 'package:smart_cap_user/datamodels/nearbydriver.dart';
import 'package:smart_cap_user/datamodels/prediction.dart';
import 'package:smart_cap_user/dataprovider/appdata.dart';
import 'package:smart_cap_user/globalvariable.dart';
import 'package:smart_cap_user/helpers/firehelper.dart';
import 'package:smart_cap_user/helpers/helpermethods.dart';
import 'package:smart_cap_user/rideVaribles.dart';
import 'package:smart_cap_user/widgets/CollectPaymentDialog.dart';
import 'package:smart_cap_user/widgets/NoDriverDialog.dart';
import 'package:smart_cap_user/widgets/ProgressDialog.dart';

class MainPageController extends GetxController {
  AuthenticationManager authManager = Get.find();
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  RxList<Prediction> destinationPredictionList = <Prediction>[].obs;
  RxString seaechPageResponse = ''.obs;
  RxDouble searchSheetHeight = 300.0.obs;
  RxDouble rideDetailsSheetHeight = 0.0.obs; // (Platform.isAndroid) ? 235 : 260
  RxDouble requestingSheetHeight = 0.0.obs; // (Platform.isAndroid) ? 195 : 220
  RxDouble tripSheetHeight = 0.0.obs; // (Platform.isAndroid) ? 275 : 300
  Rx<Address> mainPickupAddress = Address().obs;
  Rx<Address> destinationAddress = Address().obs;
  Completer<GoogleMapController> googleMapController = Completer();
  TickerProvider? vsync;
  RxDouble mapBottomPadding = 0.0.obs;
  RxBool focused = false.obs;
  List<LatLng> polylineCoordinates = [];
  Set<Polyline> polylines = {};
  Set<Marker> markers = {};
  Set<Circle> circles = {};
  Rx<dynamic>? thisList;
  BitmapDescriptor? nearbyIcon;

  Rx<DirectionDetails> tripDirectionDetails = DirectionDetails().obs;

  RxString appState = 'NORMAL'.obs;

  RxBool drawerCanOpen = true.obs;

  StreamSubscription<DatabaseEvent>? rideSubscription;
  Rx<GoogleMapController>? mapController;
  List<NearbyDriver> availableDrivers = <NearbyDriver>[].obs;

  RxBool nearbyDriversKeysLoaded = false.obs;
  RxString? adder;
  RxBool isRequestingLocationDetails = false.obs;
  RxBool locationOnMap = false.obs;
  RxString pinStatus = 'no pin'.obs;
  RxString? distenationAdrress;
  RxString? pickUpAdrress;
  @override
  Future<void> onInit() async {
    driverCarStyle = 'driversDetails';
    mainPickupAddress.value.latitude = currentPosition!.latitude;
    mainPickupAddress.value.longitude = currentPosition!.longitude;
    mainPickupAddress.value.placeName = homeAddress.value;
    createMarker();
    startGeofireListener();
    super.onInit();
  }

  @override
  void onReady() {
    pickupController.text = homeAddress.value;
    super.onReady();
  }

  void startGeofireListener() {
    Geofire.initialize('driversDetails');
    Geofire.queryAtLocation(
            currentPosition!.latitude, currentPosition!.longitude, 20)!
        .listen((map) {
      log(map.toString());
      if (map != null) {
        var callBack = map['callBack'];

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyDriver nearbyDriver = NearbyDriver();
            nearbyDriver.key = map['key'];
            nearbyDriver.latitude = map['latitude'];
            nearbyDriver.longitude = map['longitude'];
            FireHelper.nearbyDriverList.add(nearbyDriver);
            if (nearbyDriversKeysLoaded.value) {
              updateDriversOnMap();
            }
            break;
          case Geofire.onKeyExited:
            FireHelper.removeFromList(map['key']);
            updateDriversOnMap();
            break;
          case Geofire.onKeyMoved:
            NearbyDriver nearbyDriver = NearbyDriver();
            nearbyDriver.key = map['key'];
            nearbyDriver.latitude = map['latitude'];
            nearbyDriver.longitude = map['longitude'];

            FireHelper.updateNearbyLocation(nearbyDriver);
            updateDriversOnMap();
            break;
          case Geofire.onGeoQueryReady:
            nearbyDriversKeysLoaded.value = true;
            updateDriversOnMap();
            break;
        }
      }
    });
  }

  void updateDriversOnMap() {
    markers.clear();

    Set<Marker> tempMarkers = <Marker>{};

    for (NearbyDriver driver in FireHelper.nearbyDriverList) {
      LatLng driverPosition = LatLng(driver.latitude!, driver.longitude!);
      Marker thisMarker = Marker(
        markerId: MarkerId('driver${driver.key}'),
        position: driverPosition,
        icon: nearbyIcon!,
        rotation: HelperMethods.generateRandomNumber(360),
      );

      tempMarkers.add(thisMarker);
    }

    markers = tempMarkers;
  }

  Future<void> getDirection() async {
    Address pickup = mainPickupAddress.value;

    Address destination = (destinationAddress.value.latitude != null)
        ? destinationAddress.value
        : mainPickupAddress.value;
    print(mainPickupAddress.value.latitude);
    print(mainPickupAddress.value.longitude);
    LatLng pickLatLng = LatLng(
        mainPickupAddress.value.latitude!, mainPickupAddress.value.longitude!);
    LatLng destinationLatLng =
        LatLng(destination.latitude!, destination.longitude!);

    showDialog(
        barrierDismissible: false,
        context: Get.context!,
        builder: (BuildContext context) => ProgressDialog(
              status: 'Please wait...',
            ));

    DirectionDetails thisDetails =
        await HelperMethods.getDirectionDetails(pickLatLng, destinationLatLng);
    log(thisDetails.distanceValue.toString());
    tripDirectionDetails.value = thisDetails;

    Get.back();

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> results =
        polylinePoints.decodePolyline(thisDetails.encodedPoints!);

    polylineCoordinates.clear();
    if (results.isNotEmpty) {
      for (var point in results) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }

    polylines.clear();

    Polyline polyline = Polyline(
      polylineId: const PolylineId('polyid'),
      color: const Color.fromARGB(255, 95, 109, 237),
      points: polylineCoordinates,
      jointType: JointType.round,
      width: 4,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      geodesic: true,
    );

    polylines.add(polyline);

    LatLngBounds bounds;

    if (pickLatLng.latitude > destinationLatLng.latitude &&
        pickLatLng.longitude > destinationLatLng.longitude) {
      bounds =
          LatLngBounds(southwest: destinationLatLng, northeast: pickLatLng);
    } else if (pickLatLng.longitude > destinationLatLng.longitude) {
      bounds = LatLngBounds(
          southwest: LatLng(pickLatLng.latitude, destinationLatLng.longitude),
          northeast: LatLng(destinationLatLng.latitude, pickLatLng.longitude));
    } else if (pickLatLng.latitude > destinationLatLng.latitude) {
      bounds = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, pickLatLng.longitude),
        northeast: LatLng(pickLatLng.latitude, destinationLatLng.longitude),
      );
    } else {
      bounds =
          LatLngBounds(southwest: pickLatLng, northeast: destinationLatLng);
    }

    // mapController!.value
    //     .animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));

    Marker pickupMarker = Marker(
      markerId: const MarkerId('pickup'),
      position: pickLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: pickup.placeName, snippet: 'My Location'),
    );

    Marker destinationMarker = Marker(
      markerId: const MarkerId('destination'),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow:
          InfoWindow(title: destination.placeName, snippet: 'Destination'),
    );

    markers.add(pickupMarker);
    markers.add(destinationMarker);

    Circle pickupCircle = Circle(
      circleId: const CircleId('pickup'),
      strokeColor: Colors.green,
      strokeWidth: 3,
      radius: 12,
      center: pickLatLng,
      fillColor: BrandColors.colorGreen,
    );

    Circle destinationCircle = Circle(
      circleId: const CircleId('destination'),
      strokeColor: BrandColors.colorAccentPurple,
      strokeWidth: 3,
      radius: 12,
      center: destinationLatLng,
      fillColor: BrandColors.colorAccentPurple,
    );

    circles.add(pickupCircle);
    circles.add(destinationCircle);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  void showDetailSheet(String status) async {
    if (status == 'Skip') {
      destinationAddress.value = Address();
    }
    await getDirection();
    searchSheetHeight.value = 0;
    mapBottomPadding.value = (Platform.isAndroid) ? 240 : 230;
    rideDetailsSheetHeight.value = 260;
    drawerCanOpen.value = false;
  }

  void showRequestingSheet() {
    rideDetailsSheetHeight.value = 0;
    requestingSheetHeight.value = (Platform.isAndroid) ? 195 : 220;
    mapBottomPadding.value = (Platform.isAndroid) ? 200 : 190;
    drawerCanOpen.value = true;
    createRideRequest();
  }

  void createRideRequest() {
    DatabaseReference rideRef =
        FirebaseDatabase.instance.ref().child('rideRequest').push();
    if (Provider.of<AppData>(Get.context!, listen: false).destinationAddress ==
        null) {
      if (destinationAddress.value.latitude != null) {
        Provider.of<AppData>(Get.context!, listen: false)
            .updateDestinationAddress(destinationAddress.value);
      } else {
        Provider.of<AppData>(Get.context!, listen: false)
            .updateDestinationAddress(mainPickupAddress.value);
      }
    }
    var pickup =
        Provider.of<AppData>(Get.context!, listen: false).pickupAddress;
    var destination =
        Provider.of<AppData>(Get.context!, listen: false).destinationAddress;
    Map pickupMap = {
      'latitude': pickup!.latitude.toString(),
      'longitude': pickup.longitude.toString(),
    };

    Map destinationMap = {
      'latitude': destination!.latitude.toString(),
      'longitude': destination.longitude.toString(),
    };

    Map rideMap = {
      'created_at': DateTime.now().toString(),
      'rider_name': currentUserInfo!.fullname,
      'rider_phone': currentUserInfo!.phone,
      'pickup_address': pickup.placeName,
      'destination_address': destination.placeName,
      'location': pickupMap,
      'destination': destinationMap,
      'payment_method': 'card',
      'driver_id': 'waiting',
    };

    rideRef.set(rideMap);
    rideSubscription = rideRef.onValue.listen((event) async {
      dynamic data = event.snapshot.value;
      //check for null snapshot
      if (event.snapshot.value == null) {
        return;
      }
      //get car details
      if (data['car_details'] != null) {
        driverCarDetails = data['car_details'].toString();
      }
      // get driver name
      if (data['driver_name'] != null) {
        driverFullName = data['driver_name'].toString();
      }
      // get driver phone number
      if (data['driver_phone'] != null) {
        driverPhoneNumber = data['driver_phone'].toString();
      }

      //get and use driver location updates
      if (data['driver_location'] != null) {
        double driverLat =
            double.parse(data['driver_location']['latitude'].toString());
        double driverLng =
            double.parse(data['driver_location']['longitude'].toString());
        LatLng driverLocation = LatLng(driverLat, driverLng);
        if (status == 'accepted') {
          updateToPickup(driverLocation);
        } else if (status == 'ontrip') {
          updateToDestination(driverLocation);
        } else if (status == 'arrived') {
          tripStatusDisplay = 'Driver has arrived';
        }
      }
      if (data['status'] != null) {
        status = data['status'].toString();
      }
      if (status == 'accepted') {
        showTripSheet();
        Geofire.stopListener();
        removeGeofireMarkers();
      }
      if (status == 'ended') {
        if (data['fares'] != null) {
          int fares = int.parse(data['fares'].toString());

          var response = await showDialog(
            context: Get.context!,
            barrierDismissible: false,
            builder: (BuildContext context) => CollectPayment(
              paymentMethod: 'cash',
              fares: fares,
            ),
          );
          if (response == 'close') {
            rideRef.onDisconnect();
            rideSubscription!.cancel();
            rideSubscription = null;
            resetApp();
          }
        }
      }
    });
  }

  showTripSheet() {
    requestingSheetHeight.value = 0;
    tripSheetHeight.value = (Platform.isAndroid) ? 275 : 300;
    mapBottomPadding.value = (Platform.isAndroid) ? 280 : 270;
  }

  void removeGeofireMarkers() {
    markers.removeWhere((m) => m.markerId.value.contains('driver'));
  }

  void updateToPickup(LatLng driverLocation) async {
    if (!isRequestingLocationDetails.value) {
      isRequestingLocationDetails.value = true;

      var positionLatLng =
          LatLng(currentPosition!.latitude, currentPosition!.longitude);

      var thisDetails = await HelperMethods.getDirectionDetails(
          driverLocation, positionLatLng);

      if (thisDetails == null) {
        return;
      }

      tripStatusDisplay = 'Driver is Arriving - ${thisDetails.durationText}';

      isRequestingLocationDetails.value = false;
    }
  }

  void updateToDestination(LatLng driverLocation) async {
    if (!isRequestingLocationDetails.value) {
      isRequestingLocationDetails.value = true;

      var destination =
          Provider.of<AppData>(Get.context!, listen: false).destinationAddress;

      var destinationLatLng =
          LatLng(destination!.latitude!, destination.longitude!);

      var thisDetails = await HelperMethods.getDirectionDetails(
          driverLocation, destinationLatLng);

      if (thisDetails == null) {
        return;
      }

      tripStatusDisplay =
          'Driving to Destination - ${thisDetails.durationText}';

      isRequestingLocationDetails.value = false;
    }
  }

  void cancelRequest() {
    DatabaseReference rideRef =
        FirebaseDatabase.instance.ref().child('rideRequest');
    rideRef.remove();
    appState.value = 'NORMAL';
  }

  resetApp() {
    locationOnMap.value = false;
    polylineCoordinates.clear();
    polylines.clear();
    markers.clear();
    circles.clear();
    rideDetailsSheetHeight.value = 0;
    requestingSheetHeight.value = 0;
    tripSheetHeight.value = 0;
    searchSheetHeight.value = 310;
    mapBottomPadding.value = (Platform.isAndroid) ? 280 : 270;
    drawerCanOpen.value = true;
    status = '';
    driverFullName = '';
    driverPhoneNumber = '';
    driverCarDetails = '';
    tripStatusDisplay = 'Driver is Arriving';

    //setupPositionLocator(context);
  }

  void noDriverFound() {
    showDialog(
        context: Get.context!,
        barrierDismissible: false,
        builder: (BuildContext context) => NoDriverDialog());
  }

  void findDriver() {
    //TODO
    if (availableDrivers.isEmpty) {
      cancelRequest();
      //resetApp();
      noDriverFound();
      return;
    }

    var driver = availableDrivers[0];

    notifyDriver(driver);

    availableDrivers.removeAt(0);
  }

  void notifyDriver(NearbyDriver driver) {
    DatabaseReference rideRef =
        FirebaseDatabase.instance.ref().child('rideRequest').push();
    DatabaseReference driverTripRef =
        FirebaseDatabase.instance.ref().child('drivers/${driver.key}/newtrip');
    driverTripRef.set(rideRef.key);

    // Get and notify driver using token
    DatabaseReference tokenRef =
        FirebaseDatabase.instance.ref().child('drivers/${driver.key}/token');

    tokenRef.once().then((snapshot) {
      if (snapshot.snapshot.value != null) {
        String token = snapshot.snapshot.value.toString();

        // send notification to selected driver
        HelperMethods.sendNotification(token, Get.context, rideRef.key!);
      } else {
        return;
      }

      const oneSecTick = Duration(seconds: 1);

      // ignore: unused_local_variable
      var timer = Timer.periodic(oneSecTick, (timer) {
        // stop timer when ride request is cancelled;
        if (appState.value != 'REQUESTING') {
          driverTripRef.set('cancelled');
          driverTripRef.onDisconnect();
          timer.cancel();
          driverRequestTimeout = 30;
        }

        driverRequestTimeout--;

        // a value event listener for driver accepting trip request
        driverTripRef.onValue.listen((event) {
          // confirms that driver has clicked accepted for the new trip request
          if (event.snapshot.value.toString() == 'accepted') {
            driverTripRef.onDisconnect();
            timer.cancel();
            driverRequestTimeout = 30;
          }
        });

        if (driverRequestTimeout == 0) {
          //informs driver that ride has timed out
          driverTripRef.set('timeout');
          driverTripRef.onDisconnect();
          driverRequestTimeout = 30;
          timer.cancel();

          //select the next closest driver
          findDriver();
        }
      });
    });
  }

  Future getCenter() async {
    final GoogleMapController mapController = await googleMapController.future;
    LatLng centerLatLng;
    if (pinStatus.value == 'direction location') {
      LatLngBounds visibleRegion = await mapController.getVisibleRegion();
      LatLng centerLatLng = LatLng(
        (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) /
            2,
        (visibleRegion.northeast.longitude +
                visibleRegion.southwest.longitude) /
            2,
      );
      return centerLatLng;
    } else if (pinStatus.value == 'pickup location') {
      LatLngBounds visibleRegion = await mapController.getVisibleRegion();
      centerLatLng = LatLng(
        (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) /
            2,
        (visibleRegion.northeast.longitude +
                visibleRegion.southwest.longitude) /
            2,
      );

      return centerLatLng;
    }
  }

  void createMarker() {
    if (nearbyIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(Get.context!, size: const Size(2, 2));
      BitmapDescriptor.fromAssetImage(
              imageConfiguration,
              (Platform.isIOS)
                  ? 'images/car_ios.png'
                  : 'images/car_android.png')
          .then((icon) {
        nearbyIcon = icon;
      });
    }
  }
}
