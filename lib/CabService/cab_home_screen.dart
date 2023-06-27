import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartdriver/CabService/verify_otp_screen.dart';
import 'package:emartdriver/constants.dart';
import 'package:emartdriver/main.dart';
import 'package:emartdriver/model/CabOrderModel.dart';
import 'package:emartdriver/model/ConversationModel.dart';
import 'package:emartdriver/model/HomeConversationModel.dart';
import 'package:emartdriver/model/User.dart';
import 'package:emartdriver/services/FirebaseHelper.dart';
import 'package:emartdriver/services/helper.dart';
import 'package:emartdriver/ui/chat/ChatScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;

class CabHomeScreen extends StatefulWidget {
  final VoidCallback refresh;

  const CabHomeScreen({Key? key, required this.refresh}) : super(key: key);

  @override
  State<CabHomeScreen> createState() => _CabHomeScreenState();
}

class _CabHomeScreenState extends State<CabHomeScreen> with SingleTickerProviderStateMixin {
  final fireStoreUtils = FireStoreUtils();

  GoogleMapController? _mapController;
  bool canShowSheet = true;

  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? taxiIcon;

  Map<PolylineId, Polyline> polyLines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  final Map<String, Marker> _markers = {};

  setIcons() async {
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(
              size: Size(10, 10),
            ),
            "assets/images/pickup.png")
        .then((value) {
      departureIcon = value;
    });

    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(
              size: Size(10, 10),
            ),
            "assets/images/dropoff.png")
        .then((value) {
      destinationIcon = value;
    });

    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(
              size: Size(10, 10),
            ),
            "assets/images/ic_taxi.png")
        .then((value) {
      taxiIcon = value;
    });
  }

  updateDriverOrder() async {
    Timestamp startTimestamp = Timestamp.now();
    DateTime currentDate = startTimestamp.toDate();
    currentDate = currentDate.subtract(Duration(hours: 3));
    startTimestamp = Timestamp.fromDate(currentDate);

    List<CabOrderModel> orders = [];

    print('-->startTime${startTimestamp.toDate()}');
    await FirebaseFirestore.instance
        .collection(RIDESORDER)
        .where('status', whereIn: [ORDER_STATUS_PLACED, ORDER_STATUS_DRIVER_REJECTED])
        .where('createdAt', isGreaterThan: startTimestamp)
        .get()
        .then((value) async {
          print('---->${value.docs.length}');
          await Future.forEach(value.docs, (QueryDocumentSnapshot<Map<String, dynamic>> element) {
            try {
              orders.add(CabOrderModel.fromJson(element.data()));
            } catch (e, s) {
              print('watchOrdersStatus parse error ${element.id}$e $s');
            }
          });
        });

    orders.forEach((element) {
      CabOrderModel orderModel = element;
      print('---->${orderModel.id}');
      orderModel.trigger_delevery = Timestamp.now();
      FirebaseFirestore.instance.collection(RIDESORDER).doc(element.id).set(orderModel.toJson(), SetOptions(merge: true)).then((order) {
        print('Done.');
      });
    });
  }

  AnimationController? _animationController;

  @override
  void initState() {
    getDriver();
    setIcons();
    updateDriverOrder();

    print('---->$enableOTPTripStart');
    print('---->$driverOrderAcceptRejectDuration');

    _animationController = new AnimationController(vsync: this, duration: Duration(milliseconds: 700));
    _animationController!.repeat(reverse: true);
  }

  void dispose() {
    _mapController!.dispose();
    FireStoreUtils().driverStreamController.close();
    FireStoreUtils().driverStreamSub.cancel();

    FireStoreUtils().cabOrdersStreamController.close();
    FireStoreUtils().cabOrdersStreamSub.cancel();
    if (_timer != null) {
      _timer!.cancel();
    }

    super.dispose();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    isDarkMode(context)
        ? _mapController?.setMapStyle('[{"featureType": "all","'
            'elementType": "'
            'geo'
            'met'
            'ry","stylers": [{"color": "#242f3e"}]},{"featureType": "all","elementType": "labels.text.stroke","stylers": [{"lightness": -80}]},{"featureType": "administrative","elementType": "labels.text.fill","stylers": [{"color": "#746855"}]},{"featureType": "administrative.locality","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi.park","elementType": "geometry","stylers": [{"color": "#263c3f"}]},{"featureType": "poi.park","elementType": "labels.text.fill","stylers": [{"color": "#6b9a76"}]},{"featureType": "road","elementType": "geometry.fill","stylers": [{"color": "#2b3544"}]},{"featureType": "road","elementType": "labels.text.fill","stylers": [{"color": "#9ca5b3"}]},{"featureType": "road.arterial","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.arterial","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "road.highway","elementType": "geometry.fill","stylers": [{"color": "#746855"}]},{"featureType": "road.highway","elementType": "geometry.stroke","stylers": [{"color": "#1f2835"}]},{"featureType": "road.highway","elementType": "labels.text.fill","stylers": [{"color": "#f3d19c"}]},{"featureType": "road.local","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.local","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "transit","elementType": "geometry","stylers": [{"color": "#2f3948"}]},{"featureType": "transit.station","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "water","elementType": "geometry","stylers": [{"color": "#17263c"}]},{"featureType": "water","elementType": "labels.text.fill","stylers": [{"color": "#515c6d"}]},{"featureType": "water","elementType": "labels.text.stroke","stylers": [{"lightness": -20}]}]')
        : _mapController?.setMapStyle(null);

    return Scaffold(
      key: _scaffoldKey,
      body: _driverModel!.isActive
          ? Stack(
              alignment: Alignment.bottomCenter,
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapType: MapType.normal,
                  zoomControlsEnabled: false,
                  polylines: Set<Polyline>.of(polyLines.values),
                  markers: _markers.values.toSet(),
                  initialCameraPosition: CameraPosition(
                    zoom: 15,
                    target: LatLng(_driverModel!.location.latitude, _driverModel!.location.longitude),
                  ),
                ),
                if (_driverModel!.inProgressOrderID != null && currentOrder != null) buildOrderActionsCard()
              ],
            )
          : Center(
              child: showEmptyState("You are offline".tr(),
                  description: 'Go online in order to start getting delivery requests from customers and vendors.'.tr(),
                  isDarkMode: isDarkMode(context),
                  buttonTitle: 'Go Online'.tr(),
                  action: () => showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          // title: Text("Alert Dialog Box"),
                          content: Text.rich(TextSpan(children: [
                            TextSpan(text: "eMart Driver App ".tr(), style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(
                                text: "collects location data of store and other places nearby to identify pickup and delivery locations even when the app is closed or not in use."
                                    .tr())
                          ])),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                              },
                              child: Text("Deny".tr()),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                goOnline(_driverModel!);
                              },
                              child: Text("Accept".tr()),
                            ),
                          ],
                        ),
                      )
                  // goOnline(user!),
                  ),
            ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    if (isDarkMode(context))
      _mapController?.setMapStyle('[{"featureType": "all","'
          'elementType": "'
          'geo'
          'met'
          'ry","stylers": [{"color": "#242f3e"}]},{"featureType": "all","elementType": "labels.text.stroke","stylers": [{"lightness": -80}]},{"featureType": "administrative","elementType": "labels.text.fill","stylers": [{"color": "#746855"}]},{"featureType": "administrative.locality","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi.park","elementType": "geometry","stylers": [{"color": "#263c3f"}]},{"featureType": "poi.park","elementType": "labels.text.fill","stylers": [{"color": "#6b9a76"}]},{"featureType": "road","elementType": "geometry.fill","stylers": [{"color": "#2b3544"}]},{"featureType": "road","elementType": "labels.text.fill","stylers": [{"color": "#9ca5b3"}]},{"featureType": "road.arterial","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.arterial","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "road.highway","elementType": "geometry.fill","stylers": [{"color": "#746855"}]},{"featureType": "road.highway","elementType": "geometry.stroke","stylers": [{"color": "#1f2835"}]},{"featureType": "road.highway","elementType": "labels.text.fill","stylers": [{"color": "#f3d19c"}]},{"featureType": "road.local","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.local","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "transit","elementType": "geometry","stylers": [{"color": "#2f3948"}]},{"featureType": "transit.station","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "water","elementType": "geometry","stylers": [{"color": "#17263c"}]},{"featureType": "water","elementType": "labels.text.fill","stylers": [{"color": "#515c6d"}]},{"featureType": "water","elementType": "labels.text.stroke","stylers": [{"lightness": -20}]}]');
  }

  showDriverBottomSheet(User user) async {
    if (canShowSheet) {
      canShowSheet = false;
      currentCabOrderID = user.ordercabRequestData!.id;
      await showModalBottomSheet(
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.transparent,
        context: context,
        builder: (context) {
          playSound();
          return WillPopScope(
            // ignore: missing_return
            onWillPop: () async => false,
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Container(
                height: MediaQuery.of(context).size.height / 2.6,
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                decoration: BoxDecoration(
                  color: Color(0xff212121),
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    // crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text(
                          'New Rides!'.tr(),
                          style: TextStyle(color: Color(0xffFFFFFF), fontFamily: "Poppinssb", letterSpacing: 0.5),
                        ),
                      ),
                      SizedBox(height: 5),
                      IntrinsicHeight(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width / 2.5,
                              height: MediaQuery.of(context).size.height / 9.2,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    "Trip Distance".tr(),
                                    style: TextStyle(color: Color(0xffADADAD), fontFamily: "Poppinsr", letterSpacing: 0.5),
                                  ),
                                  Text(
                                    // '0',
                                    "${user.ordercabRequestData!.distance.toString()} km",
                                    style: TextStyle(color: Color(0xffFFFFFF), fontFamily: "Poppinsm", letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 5),
                      Card(
                        color: Color(0xffFFFFFF),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 10),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/location3x.png',
                                height: 55,
                              ),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 270,
                                    child: Text(
                                      "${user.ordercabRequestData!.sourceLocationName} ",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Color(0xff333333), fontFamily: "Poppinsr", letterSpacing: 0.5),
                                    ),
                                  ),
                                  SizedBox(height: 22),
                                  SizedBox(
                                    width: 270,
                                    child: Text(
                                      "${user.ordercabRequestData!.destinationLocationName} ",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Color(0xff333333), fontFamily: "Poppinsr", letterSpacing: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height / 20,
                            width: MediaQuery.of(context).size.width / 2.5,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                backgroundColor: Colors.purple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                              ),
                              child: Text(
                                'Reject'.tr(),
                                style: TextStyle(color: Color(0xffFFFFFF), fontFamily: "Poppinsm", letterSpacing: 0.5),
                              ),
                              onPressed: () async {
                                audioPlayer.stop();
                                if (_timer != null) {
                                  _timer!.cancel();
                                }

                                await FireStoreUtils.getCabOrderByOrderId(currentCabOrderID).then((value) async {
                                  print("----->${value!.status}");
                                  if (value.status == ORDER_STATUS_REJECTED) {
                                    print("----->11111s}");
                                    Navigator.pop(context);

                                    MyAppState.currentUser!.ordercabRequestData = null;
                                    MyAppState.currentUser!.inProgressOrderID = null;

                                    await FireStoreUtils.updateCurrentUser(MyAppState.currentUser!);
                                    final snack = SnackBar(
                                      content: Text(
                                        "This Ride is already reject by customer.".tr(),
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      duration: Duration(seconds: 2),
                                      backgroundColor: Colors.black,
                                    );
                                    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(snack);
                                    setState(() {});
                                  } else {
                                    Navigator.pop(context);
                                    showProgress(context, "Rejecting Ride...".tr(), false);
                                    try {
                                      await rejectOrder(user);
                                      hideProgress();
                                    } catch (e) {
                                      hideProgress();
                                      print('HomeScreenState.showDriverBottomSheet $e');
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height / 20,
                            width: MediaQuery.of(context).size.width / 2.5,
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                  backgroundColor: Colors.purple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(5),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Accept'.tr(),
                                  style: TextStyle(color: Color(0xffFFFFFF), fontFamily: "Poppinsm", letterSpacing: 0.5),
                                ),
                                onPressed: () async {
                                  audioPlayer.stop();
                                  if (_timer != null) {
                                    _timer!.cancel();
                                  }
                                  await FireStoreUtils.getCabOrderByOrderId(currentCabOrderID).then((value) async {
                                    print("----->${value!.status}");
                                    if (value.status == ORDER_STATUS_REJECTED) {
                                      print("----->11111s}");
                                      Navigator.pop(context);

                                      MyAppState.currentUser!.ordercabRequestData = null;
                                      MyAppState.currentUser!.inProgressOrderID = null;

                                      await FireStoreUtils.updateCurrentUser(MyAppState.currentUser!);
                                      final snack = SnackBar(
                                        content: Text(
                                          "This Ride is reject by customer.".tr(),
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        duration: Duration(seconds: 2),
                                        backgroundColor: Colors.black,
                                      );
                                      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(snack);
                                      setState(() {});
                                    } else {
                                      print("----->222222}");
                                      Navigator.pop(context);
                                      showProgress(context, 'Accepting Ride....'.tr(), false);
                                      try {
                                        await acceptOrder(user);
                                        updateProgress('Finding the best route...'.tr());
                                        hideProgress();
                                        setState(() {});
                                      } catch (e) {
                                        hideProgress();
                                        print('HomeScreenState.showDriverBottomSheet $e');
                                      }
                                    }
                                  });
                                }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
      canShowSheet = true;
    }
  }

  acceptOrder(User user) async {
    print("user data ");
    CabOrderModel orderModel = user.ordercabRequestData!;
    orderModel.status = ORDER_STATUS_DRIVER_ACCEPTED;
    orderModel.driverID = user.userID;
    if (enableOTPTripStart) {
      orderModel.otpCode = (Random().nextInt(900000) + 100000).toString();
    }

    Position? locationData = await getCurrentLocation();
    user.location = UserLocation(latitude: locationData.latitude, longitude: locationData.longitude);
    user.geoFireData = GeoFireData(
        geohash: Geoflutterfire().point(latitude: locationData.latitude, longitude: locationData.longitude).hash,
        geoPoint: GeoPoint(locationData.latitude, locationData.longitude));
    orderModel.driver = user;
    await FireStoreUtils.updateCabOrder(orderModel);

    user.ordercabRequestData = null;
    user.inProgressOrderID = orderModel.id;

    MyAppState.currentUser = user;
    await FireStoreUtils.updateCurrentUser(user);
    await getCurrentOrder();

    await FireStoreUtils.sendFcmMessageSingle(
        "Cab Driver Assigned.".tr(), user.firstName + " " + user.lastName + " will Pickup as soon as possible.".tr(), orderModel.author.fcmToken);
  }

  rejectOrder(User user) async {
    CabOrderModel orderModel = user.ordercabRequestData!;
    orderModel.rejectedByDrivers.add(user.userID);
    orderModel.status = ORDER_STATUS_DRIVER_REJECTED;
    await FireStoreUtils.updateCabOrder(orderModel);
    user.ordercabRequestData = null;
    MyAppState.currentUser = user;
    await FireStoreUtils.updateCurrentUser(user);
  }

  getDirections() async {
    if (currentOrder != null) {
      if (currentOrder!.status == ORDER_STATUS_SHIPPED) {
        List<LatLng> polylineCoordinates = [];

        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          GOOGLE_API_KEY,
          PointLatLng(_driverModel!.location.latitude, _driverModel!.location.longitude),
          PointLatLng(currentOrder!.sourceLocation.latitude, currentOrder!.sourceLocation.longitude),
          travelMode: TravelMode.driving,
        );

        print("----?${result.points}");
        if (result.points.isNotEmpty) {
          for (var point in result.points) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }
        }
        setState(() {
          _markers.remove("Driver");
          _markers['Driver'] = Marker(
              markerId: const MarkerId('Driver'),
              infoWindow: const InfoWindow(title: "Driver"),
              position: LatLng(_driverModel!.location.latitude, _driverModel!.location.longitude),
              icon: taxiIcon!,
              rotation: double.parse(_driverModel!.rotation.toString()));
        });

        _markers.remove("Departure");
        _markers['Departure'] = Marker(
          markerId: const MarkerId('Departure'),
          infoWindow: const InfoWindow(title: "Departure"),
          position: LatLng(currentOrder!.sourceLocation.latitude, currentOrder!.sourceLocation.longitude),
          icon: departureIcon!,
        );

        _markers.remove("Destination");
        _markers['Destination'] = Marker(
          markerId: const MarkerId('Destination'),
          infoWindow: const InfoWindow(title: "Destination"),
          position: LatLng(currentOrder!.destinationLocation.latitude, currentOrder!.destinationLocation.longitude),
          icon: destinationIcon!,
        );
        addPolyLine(polylineCoordinates);
      } else if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT || currentOrder!.status == ORDER_REACHED_DESTINATION) {
        List<LatLng> polylineCoordinates = [];

        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          GOOGLE_API_KEY,
          PointLatLng(_driverModel!.location.latitude, _driverModel!.location.longitude),
          PointLatLng(currentOrder!.destinationLocation.latitude, currentOrder!.destinationLocation.longitude),
          travelMode: TravelMode.driving,
        );

        print("----?${result.points}");
        if (result.points.isNotEmpty) {
          for (var point in result.points) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }
        }
        _markers.remove("Driver");
        _markers['Driver'] = Marker(
          markerId: const MarkerId('Driver'),
          infoWindow: const InfoWindow(title: "Driver"),
          position: LatLng(_driverModel!.location.latitude, _driverModel!.location.longitude),
          rotation: double.parse(_driverModel!.rotation.toString()),
          icon: taxiIcon!,
        );

        _markers.remove("Departure");
        _markers['Departure'] = Marker(
          markerId: const MarkerId('Departure'),
          infoWindow: const InfoWindow(title: "Departure"),
          position: LatLng(currentOrder!.sourceLocation.latitude, currentOrder!.sourceLocation.longitude),
          icon: departureIcon!,
        );
        _markers.remove("Destination");
        _markers['Destination'] = Marker(
          markerId: const MarkerId('Destination'),
          infoWindow: const InfoWindow(title: "Destination"),
          position: LatLng(currentOrder!.destinationLocation.latitude, currentOrder!.destinationLocation.longitude),
          icon: destinationIcon!,
        );
        addPolyLine(polylineCoordinates);
      } else {
        List<LatLng> polylineCoordinates = [];

        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          GOOGLE_API_KEY,
          PointLatLng(currentOrder!.sourceLocation.latitude, currentOrder!.sourceLocation.longitude),
          PointLatLng(currentOrder!.destinationLocation.latitude, currentOrder!.destinationLocation.longitude),
          travelMode: TravelMode.driving,
        );

        if (result.points.isNotEmpty) {
          for (var point in result.points) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }
        }
        _markers.remove("Departure");
        _markers['Departure'] = Marker(
          markerId: const MarkerId('Departure'),
          infoWindow: const InfoWindow(title: "Departure"),
          position: LatLng(currentOrder!.sourceLocation.latitude, currentOrder!.sourceLocation.longitude),
          icon: departureIcon!,
        );
        _markers.remove("Destination");
        _markers['Destination'] = Marker(
          markerId: const MarkerId('Destination'),
          infoWindow: const InfoWindow(title: "Destination"),
          position: LatLng(currentOrder!.destinationLocation.latitude, currentOrder!.destinationLocation.longitude),
          icon: destinationIcon!,
        );
        addPolyLine(polylineCoordinates);
      }
    }
  }

  Future<void> updateCameraLocation(
    LatLng source,
    LatLng destination,
    GoogleMapController? mapController,
  ) async {
    if (mapController == null) return;

    LatLngBounds bounds;

    if (source.latitude > destination.latitude && source.longitude > destination.longitude) {
      bounds = LatLngBounds(southwest: destination, northeast: source);
    } else if (source.longitude > destination.longitude) {
      bounds = LatLngBounds(southwest: LatLng(source.latitude, destination.longitude), northeast: LatLng(destination.latitude, source.longitude));
    } else if (source.latitude > destination.latitude) {
      bounds = LatLngBounds(southwest: LatLng(destination.latitude, source.longitude), northeast: LatLng(source.latitude, destination.longitude));
    } else {
      bounds = LatLngBounds(southwest: source, northeast: destination);
    }

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 100);

    return checkCameraLocation(cameraUpdate, mapController);
  }

  Future<void> checkCameraLocation(CameraUpdate cameraUpdate, GoogleMapController mapController) async {
    mapController.animateCamera(cameraUpdate);
    LatLngBounds l1 = await mapController.getVisibleRegion();
    LatLngBounds l2 = await mapController.getVisibleRegion();

    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      return checkCameraLocation(cameraUpdate, mapController);
    }
  }

  addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.purple,
      points: polylineCoordinates,
      width: 4,
      geodesic: true,
    );
    polyLines[id] = polyline;
    updateCameraLocation(polylineCoordinates.first, polylineCoordinates.last, _mapController);
    setState(() {});
  }

  late Stream<CabOrderModel?> ordersFuture;
  CabOrderModel? currentOrder;

  late Stream<User> driverStream;
  User? _driverModel = User();

  getCurrentOrder() async {
    ordersFuture = FireStoreUtils().getCabOrderByID(MyAppState.currentUser!.inProgressOrderID.toString());
    ordersFuture.listen((event) {
      print("------->${event!.status}");
      setState(() {
        currentOrder = event;
        getDirections();
      });
    });
  }

  Timer? _timer;

  void startTimer(User _driverModel) {
    print("------>");
    print(driverOrderAcceptRejectDuration);
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) async {
        if (driverOrderAcceptRejectDuration == 0) {
          timer.cancel();
          if (_driverModel.ordercabRequestData != null) {
            await rejectOrder(_driverModel);
            Navigator.pop(context);
            audioPlayer.stop();
          }
          setState(() {});
        } else {
          setState(() {
            driverOrderAcceptRejectDuration--;
          });
        }
      },
    );
  }

  getDriver() async {
    driverStream = FireStoreUtils().getDriver(MyAppState.currentUser!.userID);
    driverStream.listen((event) {
      print("--->${event.location.latitude} ${event.location.longitude}");
      _driverModel = event;
      MyAppState.currentUser = _driverModel;

      getDirections();
      if (_driverModel!.isActive) {
        if (_driverModel!.ordercabRequestData != null) {
          showDriverBottomSheet(_driverModel!);
          startTimer(_driverModel!);
        }
      }
      if (_driverModel!.inProgressOrderID != null) {
        getCurrentOrder();
      }
      setState(() {});
    });
  }

  Widget buildOrderActionsCard({pedding = 10, width = 60}) {
    bool isPickedUp = false;
    String? buttonText;
    if (currentOrder!.status == ORDER_STATUS_SHIPPED || currentOrder!.status == ORDER_STATUS_DRIVER_ACCEPTED) {
      buttonText = enableOTPTripStart ? "Verify Code to customer".tr() : "Pickup Customer".tr();
      isPickedUp = true;
    } else if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT) {
      // buttonText = 'Complete Pick Up'.tr();
      buttonText = "Reached To destination".tr();
      isPickedUp = false;
    } else if (currentOrder!.status == ORDER_REACHED_DESTINATION) {
      buttonText = "Complete Ride".tr();
      isPickedUp = false;
    }
    return Container(
      margin: EdgeInsets.only(left: 8, right: 8),
      padding: EdgeInsets.symmetric(vertical: 15),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(18)),
        color: isDarkMode(context) ? Color(0xff000000) : Color(0xffFFFFFF),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentOrder!.status == ORDER_STATUS_SHIPPED || currentOrder!.status == ORDER_STATUS_DRIVER_ACCEPTED)
              Column(
                children: [
                  ListTile(
                    tileColor: Color(0xffF1F4F8),
                    contentPadding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    title: Row(
                      children: [
                        Text(
                          "ORDER ID ".tr(),
                          style: TextStyle(fontSize: 13, color: isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff555555), fontFamily: "Poppinsr", letterSpacing: 0.5),
                        ),
                        Text(
                          '${currentOrder!.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff000000), fontFamily: "Poppinsr", letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${currentOrder!.author.firstName} ${currentOrder!.author.lastName}',
                        style: TextStyle(color: isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff333333), fontFamily: "Poppinsm", letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Image.asset(
                      'assets/images/user3x.png',
                      height: 42,
                      width: 42,
                      color: Colors.purple,
                    ),
                    title: Text(
                      '${currentOrder!.author.shippingAddress.name}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff000000), fontFamily: "Poppinsm", letterSpacing: 0.5),
                    ),
                    subtitle: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'ORDER ID '.tr(),
                            style: TextStyle(color: Color(0xff555555), fontSize: 12, fontFamily: "Poppinsr", letterSpacing: 0.5),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width / 4,
                            child: Text(
                              '${currentOrder!.id} ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff000000), fontFamily: "Poppinsr", letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TextButton.icon(
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                                side: BorderSide(color: Color(0xff8e24aa)),
                              ),
                              padding: EdgeInsets.zero,
                              minimumSize: Size(85, 30),
                              alignment: Alignment.center,
                              backgroundColor: Color(0xffFFFFFF),
                            ),
                            onPressed: () {
                              UrlLauncher.launch("tel://${currentOrder!.author.phoneNumber}");
                            },
                            icon: Image.asset(
                              'assets/images/call3x.png',
                              height: 14,
                              width: 14,
                            ),
                            label: Text(
                              "CALL".tr(),
                              style: TextStyle(color: Color(0xff8e24aa), fontFamily: "Poppinsm", letterSpacing: 0.5),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT)
              Column(
                children: [
                  ListTile(
                    leading: Image.asset(
                      'assets/images/user3x.png',
                      height: 42,
                      width: 42,
                      color: Colors.purple,
                    ),
                    title: Text(
                      '${currentOrder!.author.shippingAddress.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff000000), fontFamily: "Poppinsm", letterSpacing: 0.5),
                    ),
                    subtitle: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            "ORDER ID ".tr(),
                            style: TextStyle(color: Color(0xff555555), fontSize: 12, fontFamily: "Poppinsr", letterSpacing: 0.5),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width / 4,
                            child: Text(
                              '${currentOrder!.id} ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff000000), fontSize: 12, fontFamily: "Poppinsr", letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TextButton.icon(
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                                side: BorderSide(color: Color(0xff8e24aa)),
                              ),
                              padding: EdgeInsets.zero,
                              minimumSize: Size(85, 30),
                              alignment: Alignment.center,
                              backgroundColor: Color(0xffFFFFFF),
                            ),
                            onPressed: () {
                              UrlLauncher.launch("tel://${currentOrder!.author.phoneNumber}");
                            },
                            icon: Image.asset(
                              'assets/images/call3x.png',
                              height: 14,
                              width: 14,
                            ),
                            label: Text(
                              "CALL".tr(),
                              style: TextStyle(color: Color(0xff8e24aa), fontFamily: "Poppinsm", letterSpacing: 0.5),
                            )),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: Image.asset(
                      'assets/images/delivery_location3x.png',
                      height: 42,
                      width: 42,
                      color: Colors.purple,
                    ),
                    title: Text(
                      'Destination'.tr(),
                      style: TextStyle(color: Color(0xff9091A4), fontFamily: "Poppinsr", letterSpacing: 0.5),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${currentOrder!.destinationLocationName}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff333333), fontFamily: "Poppinsr", letterSpacing: 0.5),
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TextButton.icon(
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                                side: BorderSide(color: Color(0xff8e24aa)),
                              ),
                              padding: EdgeInsets.zero,
                              minimumSize: Size(100, 30),
                              alignment: Alignment.center,
                              backgroundColor: Color(0xffFFFFFF),
                            ),
                            onPressed: () => openChatWithCustomer(),
                            icon: Icon(
                              Icons.message,
                              size: 16,
                              color: Color(0xff8e24aa),
                            ),
                            // Image.asset(
                            //   'assets/images/call3x.png',
                            //   height: 14,
                            //   width: 14,
                            // ),
                            label: Text(
                              "Message".tr(),
                              style: TextStyle(color: Color(0xff8e24aa), fontFamily: "Poppinsm", letterSpacing: 0.5),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT || currentOrder!.status == ORDER_REACHED_DESTINATION) SizedBox(height: 25),
            isPickedUp
                ? FadeTransition(
                    opacity: _animationController!,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: AnimatedContainer(
                        duration: Duration(seconds: 2),
                        height: 40,
                        width: MediaQuery.of(context).size.width,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(4),
                              ),
                            ),
                            backgroundColor: Colors.purple,
                          ),
                          onPressed: () async {
                            if (currentOrder!.status == ORDER_STATUS_SHIPPED || currentOrder!.status == ORDER_STATUS_DRIVER_ACCEPTED) {
                              completePickUp();
                            } else if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT) {
                              reachedDestination();
                            } else if (currentOrder!.status == ORDER_REACHED_DESTINATION) {
                              if (currentOrder!.paymentStatus == true) {
                                completeOrder();
                              } else {
                                final snack = SnackBar(
                                  content: Text(
                                    "Customer payment is pending.".tr(),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Colors.black,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(snack);
                              }
                            }
                          },
                          child: Text(
                            buttonText ?? "",
                            style: TextStyle(color: Color(0xffFFFFFF), fontFamily: "Poppinsm", letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: AnimatedContainer(
                      duration: Duration(seconds: 2),
                      height: 40,
                      width: MediaQuery.of(context).size.width,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(4),
                            ),
                          ),
                          backgroundColor: Colors.purple,
                        ),
                        onPressed: () async {
                          if (currentOrder!.status == ORDER_STATUS_SHIPPED || currentOrder!.status == ORDER_STATUS_DRIVER_ACCEPTED) {
                            completePickUp();
                          } else if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT) {
                            reachedDestination();
                          } else if (currentOrder!.status == ORDER_REACHED_DESTINATION) {
                            if (currentOrder!.paymentStatus == true) {
                              completeOrder();
                            } else {
                              final snack = SnackBar(
                                content: Text(
                                  "Customer payment is pending.".tr(),
                                  style: TextStyle(color: Colors.white),
                                ),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.black,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(snack);
                            }
                          }
                        },
                        child: Text(
                          buttonText ?? "",
                          style: TextStyle(color: Color(0xffFFFFFF), fontFamily: "Poppinsm", letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  completePickUp() async {
    if (enableOTPTripStart) {
      final isComplete = await Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => VerifyOtpScreen(
                otp: currentOrder!.otpCode,
              )));
      if (isComplete != null) {
        if (isComplete == true) {
          print('HomeScreenState.completePickUp');
          showProgress(context, "Updating Ride...".tr(), false);
          currentOrder!.status = ORDER_STATUS_IN_TRANSIT;
          await FireStoreUtils.updateCabOrder(currentOrder!);

          hideProgress();
          setState(() {});
        }
      }
    } else {
      print('HomeScreenState.completePickUp');
      showProgress(context, 'Updating Ride...'.tr(), false);
      currentOrder!.status = ORDER_STATUS_IN_TRANSIT;
      await FireStoreUtils.updateCabOrder(currentOrder!);

      hideProgress();
      setState(() {});
    }
  }

  reachedDestination() async {
    showProgress(context, "Ride update...".tr(), false);
    currentOrder!.status = ORDER_REACHED_DESTINATION;
    await FireStoreUtils.updateCabOrder(currentOrder!);
    hideProgress();
    setState(() {});
  }

  completeOrder() async {
    showProgress(context, "Completing Ride...".tr(), false);
    currentOrder!.status = ORDER_STATUS_COMPLETED;
    updateCabWalletAmount(currentOrder!);
    await FireStoreUtils.updateCabOrder(currentOrder!);

    Position? locationData = await getCurrentLocation();
    MyAppState.currentUser!.location = UserLocation(latitude: locationData.latitude, longitude: locationData.longitude);
    MyAppState.currentUser!.geoFireData = GeoFireData(
        geohash: Geoflutterfire().point(latitude: locationData.latitude, longitude: locationData.longitude).hash,
        geoPoint: GeoPoint(locationData.latitude, locationData.longitude));
    await FireStoreUtils.sendFcmMessage("Ride Complete".tr(), "Our ride driver complete ride.".tr(), currentOrder!.author.fcmToken, null);

    MyAppState.currentUser!.inProgressOrderID = null;
    MyAppState.currentUser!.ordercabRequestData = null;

    await FireStoreUtils.updateCurrentUser(MyAppState.currentUser!);
    currentOrder = null;
    hideProgress();
    _markers.clear();
    polyLines.clear();
    _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(locationData.latitude, locationData.longitude), zoom: 15),
      ),
    );
    updateDriverOrder();
    setState(() {});
  }

  openChatWithCustomer() async {
    late String channelID;
    if (currentOrder!.driver!.userID.compareTo(currentOrder!.author.userID) < 0) {
      channelID = currentOrder!.driver!.userID + currentOrder!.author.userID;
    } else {
      channelID = currentOrder!.author.userID + currentOrder!.driver!.userID;
    }

    ConversationModel? conversationModel = await fireStoreUtils.getChannelByIdOrNull(channelID);
    push(
      context,
      ChatScreen(
        homeConversationModel: HomeConversationModel(members: [currentOrder!.author], conversationModel: conversationModel),
      ),
    );
  }

  goOnline(User user) async {
    await showProgress(context, 'Going online...'.tr(), false);
    Position locationData = await getCurrentLocation();
    print('HomeScreenState.goOnline');
    user.isActive = true;
    user.location = UserLocation(latitude: locationData.latitude, longitude: locationData.longitude);
    user.geoFireData = GeoFireData(
        geohash: Geoflutterfire().point(latitude: locationData.latitude, longitude: locationData.longitude).hash,
        geoPoint: GeoPoint(locationData.latitude, locationData.longitude));
    MyAppState.currentUser = user;
    await FireStoreUtils.updateCurrentUser(user);
    updateDriverOrder();
    await hideProgress();
  }

  final audioPlayer = AudioPlayer();
  bool isPlaying = false;

  playSound() async {
    final path = await rootBundle.load("assets/audio/mixkit-happy-bells-notification-937.mp3");
    audioPlayer.setSourceBytes(path.buffer.asUint8List());
    audioPlayer.setReleaseMode(ReleaseMode.loop);
    //audioPlayer.setSourceUrl(url);
    audioPlayer.play(BytesSource(path.buffer.asUint8List()),
        volume: 15,
        ctx: AudioContext(
            android: AudioContextAndroid(
                contentType: AndroidContentType.music, isSpeakerphoneOn: true, stayAwake: true, usageType: AndroidUsageType.alarm, audioFocus: AndroidAudioFocus.gainTransient),
            iOS: AudioContextIOS(defaultToSpeaker: true, category: AVAudioSessionCategory.playback, options: [])));
  }
}
