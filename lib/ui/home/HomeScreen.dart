import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartdriver/constants.dart';
import 'package:emartdriver/main.dart';
import 'package:emartdriver/model/ConversationModel.dart';
import 'package:emartdriver/model/CurrencyModel.dart';
import 'package:emartdriver/model/HomeConversationModel.dart';
import 'package:emartdriver/model/OrderModel.dart';
import 'package:emartdriver/model/User.dart';
import 'package:emartdriver/services/FirebaseHelper.dart';
import 'package:emartdriver/services/helper.dart';
import 'package:emartdriver/ui/chat/ChatScreen.dart';
import 'package:emartdriver/ui/home/pick_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;

class HomeScreen extends StatefulWidget {
  final VoidCallback refresh;

  const HomeScreen({Key? key, required this.refresh}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
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
            "assets/images/food_delivery.png")
        .then((value) {
      taxiIcon = value;
    });
  }

  updateDriverOrder() async {
    Timestamp startTimestamp = Timestamp.now();
    DateTime currentDate = startTimestamp.toDate();
    currentDate = currentDate.subtract(Duration(hours: 3));
    startTimestamp = Timestamp.fromDate(currentDate);

    List<OrderModel> orders = [];

    print('-->startTime${startTimestamp.toDate()}');
    await FirebaseFirestore.instance
        .collection(ORDERS)
        .where('status', whereIn: [ORDER_STATUS_ACCEPTED, ORDER_STATUS_DRIVER_REJECTED])
        .where('createdAt', isGreaterThan: startTimestamp)
        .get()
        .then((value) async {
          print('---->${value.docs.length}');
          await Future.forEach(value.docs, (QueryDocumentSnapshot<Map<String, dynamic>> element) {
            try {
              orders.add(OrderModel.fromJson(element.data()));
            } catch (e, s) {
              print('watchOrdersStatus parse error ${element.id}$e $s');
            }
          });
        });

    orders.forEach((element) {
      OrderModel orderModel = element;
      print('---->${orderModel.id}');
      orderModel.trigger_delevery = Timestamp.now();
      FirebaseFirestore.instance.collection(ORDERS).doc(element.id).set(orderModel.toJson(), SetOptions(merge: true)).then((order) {
        print('Done.');
      });
    });
  }

  @override
  void initState() {
    getDriver();
    setIcons();
    updateDriverOrder();
    super.initState();
  }

  late Stream<OrderModel?> ordersFuture;
  OrderModel? currentOrder;

  late Stream<User> driverStream;
  User? _driverModel = User();

  getCurrentOrder() async {
    ordersFuture = FireStoreUtils().getOrderByID(MyAppState.currentUser!.inProgressOrderID.toString());
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
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) async {
        if (driverOrderAcceptRejectDuration == 0) {
          timer.cancel();
          if (_driverModel.ordercabRequestData != null) {
            await rejectOrder(_driverModel);
            Navigator.pop(context);
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

      setState(() {});
      getDirections();
      if (_driverModel!.isActive) {
        if (_driverModel!.orderRequestData != null) {
          showDriverBottomSheet(_driverModel!);
          startTimer(_driverModel!);
        }
      }
      if (_driverModel!.inProgressOrderID != null) {
        getCurrentOrder();
      }
    });
  }

  @override
  void dispose() {
    _mapController!.dispose();
    FireStoreUtils().driverStreamController.close();
    FireStoreUtils().driverStreamSub.cancel();
    FireStoreUtils().ordersStreamController.close();
    FireStoreUtils().ordersStreamSub.cancel();
    if (_timer != null) {
      _timer!.cancel();
    }
    super.dispose();
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
              child: showEmptyState('You are offline'.tr(),
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
                                text:
                                    "collects location data of store and other places nearby to identify pickup and delivery locations even when the app is closed or not in use."
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

  showDriverBottomSheet(User user) async {
    double distanceInMeters = Geolocator.distanceBetween(user.orderRequestData!.vendor.latitude, user.orderRequestData!.vendor.longitude,
        user.orderRequestData!.author.shippingAddress.location.latitude, user.orderRequestData!.author.shippingAddress.location.longitude);
    double kilometer = distanceInMeters / 1000;
    if (canShowSheet) {
      canShowSheet = false;
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
                          'New Order!'.tr(),
                          style: TextStyle(color: Color(0xffFFFFFF), fontFamily: "Poppinssb", letterSpacing: 0.5),
                        ),
                      ),
                      SizedBox(height: 10),
                      IntrinsicHeight(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Container(
                            //   width: MediaQuery.of(context).size.width / 2.5,
                            //   height: MediaQuery.of(context).size.height / 9.2,
                            //   child: Column(
                            //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            //     children: [
                            //       Text(
                            //         "Expected Earning",
                            //         style: TextStyle(
                            //           color: Color(0xffADADAD),
                            //           fontFamily: "Poppinsr",
                            //           letterSpacing: 0.5,
                            //         ),
                            //       ),
                            //       Text(
                            //         symbol+ "${25.00}",
                            //         style: TextStyle(
                            //             color: Color(0xffFFFFFF),
                            //             fontFamily: "Poppinsm",
                            //             letterSpacing: 0.5),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                            // VerticalDivider(color: Color(0xff4E4F53)),
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
                                    "${kilometer.toStringAsFixed(decimal)} km",
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
                                      "${user.orderRequestData!.vendor.location} ",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Color(0xff333333), fontFamily: "Poppinsr", letterSpacing: 0.5),
                                    ),
                                  ),
                                  SizedBox(height: 22),
                                  SizedBox(
                                    width: 270,
                                    child: Text(
                                      "${user.orderRequestData!.address.line1} "
                                      "${user.orderRequestData!.address.line2} "
                                      "${user.orderRequestData!.address.city}",
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
                      // Text('${currentOrder!.author.shippingAddress.line1} '
                      //     '${currentOrder!.author.shippingAddress.line2} '
                      //     '${currentOrder!.author.shippingAddress.city}'),
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
                                'Reject',
                                style: TextStyle(color: Color(0xffFFFFFF), fontFamily: "Poppinsm", letterSpacing: 0.5),
                              ),
                              onPressed: () async {
                                Navigator.pop(context);
                                showProgress(context, 'Rejecting order...'.tr(), false);
                                try {
                                  audioPlayer.stop();
                                  if (_timer != null) {
                                    _timer!.cancel();
                                  }
                                  await rejectOrder(user);
                                  hideProgress();
                                  setState(() {});
                                } catch (e) {
                                  hideProgress();
                                  print('HomeScreenState.showDriverBottomSheet $e');
                                }
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
                                  Navigator.pop(context);
                                  showProgress(context, 'Accepting order...'.tr(), false);
                                  try {
                                    audioPlayer.stop();
                                    if (_timer != null) {
                                      _timer!.cancel();
                                    }
                                    await acceptOrder(user);
                                    updateProgress('Finding the best route...'.tr());
                                    hideProgress();

                                    setState(() {});
                                  } catch (e) {
                                    hideProgress();
                                    print('HomeScreenState.showDriverBottomSheet $e');
                                  }
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

  Widget buildOrderActionsCard() {
    late String title;
    String? buttonText;
    if (currentOrder!.status == ORDER_STATUS_SHIPPED || currentOrder!.status == ORDER_STATUS_DRIVER_ACCEPTED) {
      title = '${currentOrder!.vendor.title}';
      buttonText = 'REACHED STORE FOR PICKUP'.tr();
    } else if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT) {
      title = 'Deliver to {}'.tr(args: ['${currentOrder!.author.firstName}']);
      // buttonText = 'Complete Pick Up'.tr();
      buttonText = 'REACHED CUSTOMER DOOR STEP'.tr();
    }

    return Container(
      margin: EdgeInsets.only(left: 8, right: 8),
      padding: EdgeInsets.symmetric(vertical: 15),
      height: MediaQuery.of(context).size.height / 3.2,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(18)),
        color: isDarkMode(context) ? Color(0xff000000) : Color(0xffFFFFFF),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentOrder!.status == ORDER_STATUS_SHIPPED || currentOrder!.status == ORDER_STATUS_DRIVER_ACCEPTED)
              ListTile(
                title: Text(
                  title,
                  style: TextStyle(color: isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff000000), fontFamily: "Poppinsm", letterSpacing: 0.5),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '${currentOrder!.vendor.location}',
                    maxLines: 2,
                    style: TextStyle(color: isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff000000), fontFamily: "Poppinsr", letterSpacing: 0.5),
                  ),
                ),
                trailing: TextButton.icon(
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
                      UrlLauncher.launch("tel://${currentOrder!.vendor.phonenumber}");
                    },
                    icon: Image.asset(
                      'assets/images/call3x.png',
                      height: 14,
                      width: 14,
                    ),
                    label: Text(
                      "CALL",
                      style: TextStyle(color: Color(0xff8e24aa), fontFamily: "Poppinsm", letterSpacing: 0.5),
                    )),
              ),
            if (currentOrder!.status == ORDER_STATUS_SHIPPED || currentOrder!.status == ORDER_STATUS_DRIVER_ACCEPTED)
              ListTile(
                tileColor: Color(0xffF1F4F8),
                contentPadding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                title: Row(
                  children: [
                    Text(
                      'ORDER ID '.tr(),
                      style: TextStyle(color: isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff555555), fontFamily: "Poppinsr", letterSpacing: 0.5),
                    ),
                    SizedBox(
                      width: 110,
                      child: Text(
                        '${currentOrder!.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff000000), fontFamily: "Poppinsr", letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '${currentOrder!.author.shippingAddress.name}',
                    style: TextStyle(color: isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff333333), fontFamily: "Poppinsm", letterSpacing: 0.5),
                  ),
                ),
              ),

            if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT)
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
                        'ORDER ID '.tr(),
                        style: TextStyle(color: Color(0xff555555), fontFamily: "Poppinsr", letterSpacing: 0.5),
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
                          style: TextStyle(color: isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff000000), fontFamily: "Poppinsr", letterSpacing: 0.5),
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

            if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT)
              ListTile(
                leading: Image.asset(
                  'assets/images/delivery_location3x.png',
                  height: 42,
                  width: 42,
                  color: Colors.purple,
                ),
                title: Text(
                  'DELIVER'.tr(),
                  style: TextStyle(color: Color(0xff9091A4), fontFamily: "Poppinsr", letterSpacing: 0.5),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '${currentOrder!.author.shippingAddress.line1},${currentOrder!.author.shippingAddress.line2},${currentOrder!.author.shippingAddress.city},${currentOrder!.author.shippingAddress.country}',
                    maxLines: 2,
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
                          "Message",
                          style: TextStyle(color: Color(0xff8e24aa), fontFamily: "Poppinsm", letterSpacing: 0.5),
                        )),
                  ],
                ),
              ),

            if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT) SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
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
                    if (currentOrder!.status == ORDER_STATUS_SHIPPED || currentOrder!.status == ORDER_STATUS_DRIVER_ACCEPTED)
                      completePickUp();
                    //////////////////////////////////////////////////////////////
                    /////picked order
                    else if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT)
                      //////////////////////////////////////////////////////////////
                      /////make order deliver
                      push(
                        context,
                        Scaffold(
                          appBar: AppBar(
                            leading: IconButton(
                              icon: Icon(Icons.chevron_left),
                              onPressed: () => Navigator.pop(context),
                            ),
                            titleSpacing: -8,
                            title: Text(
                              "Deliver".tr() + ": ${currentOrder!.id}",
                              style: TextStyle(color: isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff000000), fontFamily: "Poppinsr", letterSpacing: 0.5),
                            ),
                            centerTitle: false,
                          ),
                          body: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(color: Colors.grey.shade100, width: 0.1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.shade200,
                                          blurRadius: 2.0,
                                          spreadRadius: 0.4,
                                          offset: Offset(0.2, 0.2),
                                        ),
                                      ],
                                      color: Colors.white),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'DELIVER'.tr().toUpperCase(),
                                            style: TextStyle(color: Color(0xff9091A4), fontFamily: "Poppinsr", letterSpacing: 0.5),
                                          ),
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
                                                "CALL".tr().toUpperCase(),
                                                style: TextStyle(color: Color(0xff8e24aa), fontFamily: "Poppinsm", letterSpacing: 0.5),
                                              )),
                                        ],
                                      ),
                                      Text(
                                        '${currentOrder!.author.shippingAddress.name}',
                                        style: TextStyle(color: Color(0xff333333), fontFamily: "Poppinsm", letterSpacing: 0.5),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          '${currentOrder!.author.shippingAddress.line1},'
                                          '${currentOrder!.author.shippingAddress.line2},'
                                          '${currentOrder!.author.shippingAddress.city}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Color(0xff9091A4), fontFamily: "Poppinsr", letterSpacing: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 28),
                                Text(
                                  "ITEMS".tr().toUpperCase(),
                                  style: TextStyle(color: Color(0xff9091A4), fontFamily: "Poppinsm", letterSpacing: 0.5),
                                ),
                                SizedBox(height: 24),
                                ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: currentOrder!.products.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                          padding: EdgeInsets.only(bottom: 10),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: CachedNetworkImage(
                                                    height: 55,
                                                    // width: 50,
                                                    imageUrl: '${currentOrder!.products[index].photo}',
                                                    imageBuilder: (context, imageProvider) => Container(
                                                          decoration: BoxDecoration(
                                                              borderRadius: BorderRadius.circular(8),
                                                              image: DecorationImage(
                                                                image: imageProvider,
                                                                fit: BoxFit.cover,
                                                              )),
                                                        )),
                                              ),
                                              Expanded(
                                                flex: 10,
                                                child: Padding(
                                                  padding: const EdgeInsets.only(left: 14.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        '${currentOrder!.products[index].name}',
                                                        style: TextStyle(
                                                            fontFamily: 'Poppinsr',
                                                            letterSpacing: 0.5,
                                                            color: isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff333333)),
                                                      ),
                                                      SizedBox(height: 5),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.close,
                                                            size: 15,
                                                            color: Colors.purple,
                                                          ),
                                                          Text('${currentOrder!.products[index].quantity}',
                                                              style: TextStyle(
                                                                fontFamily: 'Poppinsm',
                                                                letterSpacing: 0.5,
                                                                color: Colors.purple,
                                                              )),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            ],
                                          ));
                                      // Card(
                                      //   child: Text(widget.currentOrder!.products[index].name),
                                      // );
                                    }),
                                SizedBox(height: 28),
                                Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Color(0xffC2C4CE)),
                                      // boxShadow: [
                                      //   BoxShadow(
                                      //       color: Colors.grey.shade200,
                                      //       blurRadius: 8.0,
                                      //       spreadRadius: 1.2,
                                      //       offset: Offset(0.2, 0.2)),
                                      // ],
                                      color: Colors.white),
                                  child: ListTile(
                                    minLeadingWidth: 20,
                                    leading: Image.asset(
                                      'assets/images/mark_selected3x.png',
                                      height: 24,
                                      width: 24,
                                    ),
                                    title: Text(
                                      "Given".tr() + " ${currentOrder!.products.length} " + "item to customer".tr(),
                                      style: TextStyle(color: Color(0xff8e24aa), fontFamily: 'Poppinsm', letterSpacing: 0.5),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 26),
                              ],
                            ),
                          ),
                          bottomNavigationBar: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 26),
                            child: SizedBox(
                              height: 45,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                  backgroundColor: Color(0xff8e24aa),
                                ),
                                child: Text(
                                  "MARK ORDER DELIVER".tr(),
                                  style: TextStyle(
                                    letterSpacing: 0.5,
                                    fontFamily: 'Poppinsm',
                                  ),
                                ),
                                onPressed: () => completeOrder(),
                              ),
                            ),
                          ),
                        ),
                      );

                    // completeOrder();
                  },
                  child: Text(
                    buttonText ?? "",
                    style: TextStyle(color: Color(0xffFFFFFF), fontFamily: "Poppinsm", letterSpacing: 0.5),
                  ),
                ),
              ),
            ),

            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  acceptOrder(User user) async {
    print("user data ");
    OrderModel orderModel = user.orderRequestData!;
    orderModel.status = ORDER_STATUS_DRIVER_ACCEPTED;
    orderModel.driverID = user.userID;

    Position? locationData = await getCurrentLocation();
    user.location = UserLocation(latitude: locationData.latitude, longitude: locationData.longitude);
    user.geoFireData = GeoFireData(
        geohash: Geoflutterfire().point(latitude: locationData.latitude, longitude: locationData.longitude).hash,
        geoPoint: GeoPoint(locationData.latitude, locationData.longitude));
    orderModel.driver = user;
    await FireStoreUtils.updateOrder(orderModel);

    user.orderRequestData = null;
    user.inProgressOrderID = orderModel.id;

    MyAppState.currentUser = user;
    await FireStoreUtils.updateCurrentUser(user);

    await FireStoreUtils.sendFcmMessage("Delivery Agent Assigned.".tr(), user.firstName + " " + user.lastName + " will deliver Your Order.",
        orderModel.author.fcmToken, orderModel.vendor.fcmToken);
  }

  completePickUp() async {
    print('HomeScreenState.completePickUp');
    showProgress(context, 'Updating order...', false);
    currentOrder!.status = ORDER_STATUS_IN_TRANSIT;
    await FireStoreUtils.updateOrder(currentOrder!);

    hideProgress();
    setState(() {});
    push(
      context,
      PickOrder(currentOrder: currentOrder),
    );
  }

  completeOrder() async {
    showProgress(context, 'Completing Delivery...'.tr(), false);
    currentOrder!.status = ORDER_STATUS_COMPLETED;
    updateWallateAmount(currentOrder!);
    await FireStoreUtils.updateOrder(currentOrder!);
    Position? locationData = await getCurrentLocation();
    MyAppState.currentUser!.location = UserLocation(latitude: locationData.latitude, longitude: locationData.longitude);
    MyAppState.currentUser!.geoFireData = GeoFireData(
        geohash: Geoflutterfire().point(latitude: locationData.latitude, longitude: locationData.longitude).hash,
        geoPoint: GeoPoint(locationData.latitude, locationData.longitude));
    await FireStoreUtils.sendFcmMessage("Order Complete".tr(), "Our Delivery agent delivered order.".tr(), currentOrder!.author.fcmToken, null);
    MyAppState.currentUser!.inProgressOrderID = null;
    await FireStoreUtils.updateCurrentUser(MyAppState.currentUser!);
    hideProgress();
    _markers.clear();
    polyLines.clear();
    _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(locationData.latitude, locationData.longitude), zoom: 15),
      ),
    );

    setState(() {});
    Navigator.pop(context);
  }

  rejectOrder(User user) async {
    OrderModel orderModel = user.orderRequestData!;
    orderModel.rejectedByDrivers.add(user.userID);
    orderModel.status = ORDER_STATUS_DRIVER_REJECTED;
    await FireStoreUtils.updateOrder(orderModel);
    user.orderRequestData = null;
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
          PointLatLng(currentOrder!.vendor.latitude, currentOrder!.vendor.longitude),
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

        _markers.remove("Destination");
        _markers['Destination'] = Marker(
          markerId: const MarkerId('Destination'),
          infoWindow: const InfoWindow(title: "Destination"),
          position: LatLng(currentOrder!.vendor.latitude, currentOrder!.vendor.longitude),
          icon: destinationIcon!,
        );
        addPolyLine(polylineCoordinates);
      } else if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT) {
        List<LatLng> polylineCoordinates = [];

        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          GOOGLE_API_KEY,
          PointLatLng(_driverModel!.location.latitude, _driverModel!.location.longitude),
          PointLatLng(currentOrder!.author.shippingAddress.location.latitude, currentOrder!.author.shippingAddress.location.longitude),
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
            rotation: double.parse(_driverModel!.rotation.toString()),
            icon: taxiIcon!,
          );
        });

        _markers.remove("Destination");
        _markers['Destination'] = Marker(
          markerId: const MarkerId('Destination'),
          infoWindow: const InfoWindow(title: "Destination"),
          position: LatLng(currentOrder!.author.shippingAddress.location.latitude, currentOrder!.author.shippingAddress.location.longitude),
          icon: destinationIcon!,
        );
        addPolyLine(polylineCoordinates);
      }
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
                contentType: AndroidContentType.music,
                isSpeakerphoneOn: true,
                stayAwake: true,
                usageType: AndroidUsageType.alarm,
                audioFocus: AndroidAudioFocus.gainTransient),
            iOS: AudioContextIOS(defaultToSpeaker: true, category: AVAudioSessionCategory.playback, options: [])));
  }
}
// class HomeScreenState extends State<HomeScreen> {
//   // late double distanceInMeters = 0.0;
//   // late double kilometer = 0.0;
//   // var distance = Distance();
//
//   // // km = 423
//   // final km = distance.as(LengthUnit.Kilometer, LatLng(52.518611, 13.408056),
//   //     LatLng(51.519475, 7.46694444));
//
//   final fireStoreUtils = FireStoreUtils();
//   late Stream<DocumentSnapshot<Map<String, dynamic>>> userStream;
//
//   GoogleMapController? _mapController;
//   bool canShowSheet = true;
//   OrderModel? currentOrder;
//
//   PolylinePoints polylinePoints = PolylinePoints();
//
//   List<Polyline> polylines = [];
//
//   List<LatLng> polylineCoordinates = [];
//   List<Marker> mapMarkers = [];
//   late BitmapDescriptor driverIcon;
//   late BitmapDescriptor storeIcon;
//   late BitmapDescriptor customerIcon;
//   bool hasOrder = MyAppState.currentUser!.inProgressOrderID != null;
//
//   void setSourceIcon() async {
//     driverIcon = await BitmapDescriptor.fromAssetImage(
//         ImageConfiguration(size: Size(46, 46)),
//         'assets/images/location_black3x.png');
//     storeIcon = await BitmapDescriptor.fromAssetImage(
//         ImageConfiguration(size: Size(46, 46)),
//         'assets/images/location_orange3x.png');
//     customerIcon = await BitmapDescriptor.fromAssetImage(
//         ImageConfiguration(size: Size(46, 46)),
//         'assets/images/location_orange3x.png');
//   }
//
//   @override
//   void initState() {
//     setSourceIcon();
//     if (hasOrder) {
//       getCurrentOrder();
//     }
//     userStream = fireStoreUtils.watchUserObject(MyAppState.currentUser!.userID);
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     isDarkMode(context)
//         ? _mapController?.setMapStyle('[{"featureType": "all","'
//             'elementType": "'
//             'geo'
//             'met'
//             'ry","stylers": [{"color": "#242f3e"}]},{"featureType": "all","elementType": "labels.text.stroke","stylers": [{"lightness": -80}]},{"featureType": "administrative","elementType": "labels.text.fill","stylers": [{"color": "#746855"}]},{"featureType": "administrative.locality","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi.park","elementType": "geometry","stylers": [{"color": "#263c3f"}]},{"featureType": "poi.park","elementType": "labels.text.fill","stylers": [{"color": "#6b9a76"}]},{"featureType": "road","elementType": "geometry.fill","stylers": [{"color": "#2b3544"}]},{"featureType": "road","elementType": "labels.text.fill","stylers": [{"color": "#9ca5b3"}]},{"featureType": "road.arterial","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.arterial","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "road.highway","elementType": "geometry.fill","stylers": [{"color": "#746855"}]},{"featureType": "road.highway","elementType": "geometry.stroke","stylers": [{"color": "#1f2835"}]},{"featureType": "road.highway","elementType": "labels.text.fill","stylers": [{"color": "#f3d19c"}]},{"featureType": "road.local","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.local","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "transit","elementType": "geometry","stylers": [{"color": "#2f3948"}]},{"featureType": "transit.station","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "water","elementType": "geometry","stylers": [{"color": "#17263c"}]},{"featureType": "water","elementType": "labels.text.fill","stylers": [{"color": "#515c6d"}]},{"featureType": "water","elementType": "labels.text.stroke","stylers": [{"lightness": -20}]}]')
//         : _mapController?.setMapStyle(null);
//
//     return Scaffold(
//       body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
//         stream: userStream,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Container(
//               child: Center(
//                 child: CircularProgressIndicator.adaptive(
//                   valueColor: AlwaysStoppedAnimation(Colors.purple),
//                 ),
//               ),
//             );
//           } else if (snapshot.hasData) {
//             User? user;
//
//             try {
//               user = User.fromJson(snapshot.data?.data() ?? {});
//             } catch (e) {
//               print('HomeScreenState.build parse error  $e}');
//             }
//             if (user == null) {
//               return Center(
//                 child: showEmptyState('Unexpected Error'.tr(),
//                     'Failed to retrieve user data.'.tr()),
//               );
//             } else {
//               MyAppState.currentUser = user;
//               Future.delayed(Duration(seconds: 1), () => widget.refresh.call());
//
//               if (user.isActive) {
//                 if (user.orderRequestData != null) {
//                   Future.delayed(Duration(seconds: 1), () async {
//                     showDriverBottomSheet(user!);
//                   });
//                 }
//                 if (user.inProgressOrderID != null) {}
//                 return Stack(
//                   alignment: Alignment.bottomCenter,
//                   children: [
//                     GoogleMap(
//                       onMapCreated: _onMapCreated,
//                       myLocationEnabled: true,
//                       myLocationButtonEnabled: true,
//                       mapType: MapType.normal,
//                       zoomControlsEnabled: false,
//                       polylines: Set<Polyline>.of(polylines),
//                       markers: Set<Marker>.of(mapMarkers),
//                       initialCameraPosition: CameraPosition(
//                         zoom: 15,
//                         target: LatLng(
//                             user.location.latitude, user.location.longitude),
//                       ),
//                     ),
//                     if (user.inProgressOrderID != null && currentOrder != null)
//                       buildOrderActionsCard(user)
//                   ],
//                 );
//               } else {
//                 return Center(
//                   child: showEmptyState(
//                       'You are offline'.tr(),
//                       'Go online in order to start getting delivery requests from customers and vendors.'
//                           .tr(),
//                       isDarkMode: isDarkMode(context),
//                       buttonTitle: 'Go Online'.tr(),
//                       action: () => showDialog(
//                             context: context,
//                             builder: (ctx) => AlertDialog(
//                               // title: Text("Alert Dialog Box"),
//                               content: Text.rich(TextSpan(children: [
//                                 TextSpan(
//                                     text: "eMart Driver App ".tr(),
//                                     style:
//                                         TextStyle(fontWeight: FontWeight.bold)),
//                                 TextSpan(
//                                     text:
//                                         "collects location data of store and other places nearby to identify pickup and delivery locations even when the app is closed or not in use.".tr(
//
//                                         ))
//                               ])),
//                               actions: <Widget>[
//                                 TextButton(
//                                   onPressed: () {
//                                     Navigator.of(ctx).pop();
//                                   },
//                                   child: Text("Deny".tr()),
//                                 ),
//                                 TextButton(
//                                   onPressed: () {
//                                     Navigator.of(ctx).pop();
//                                     goOnline(user!);
//                                   },
//                                   child: Text("Accept".tr()),
//                                 ),
//                               ],
//                             ),
//                           )
//                       // goOnline(user!),
//                       ),
//                 );
//               }
//             }
//           } else {
//             return showEmptyState(
//                 'Unexpected Error'.tr(), 'Connection to server failed.'.tr());
//           }
//         },
//       ),
//     );
//   }
//
//   void _onMapCreated(GoogleMapController controller) {
//     _mapController = controller;
//
//     if (isDarkMode(context))
//       _mapController?.setMapStyle('[{"featureType": "all","'
//           'elementType": "'
//           'geo'
//           'met'
//           'ry","stylers": [{"color": "#242f3e"}]},{"featureType": "all","elementType": "labels.text.stroke","stylers": [{"lightness": -80}]},{"featureType": "administrative","elementType": "labels.text.fill","stylers": [{"color": "#746855"}]},{"featureType": "administrative.locality","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi.park","elementType": "geometry","stylers": [{"color": "#263c3f"}]},{"featureType": "poi.park","elementType": "labels.text.fill","stylers": [{"color": "#6b9a76"}]},{"featureType": "road","elementType": "geometry.fill","stylers": [{"color": "#2b3544"}]},{"featureType": "road","elementType": "labels.text.fill","stylers": [{"color": "#9ca5b3"}]},{"featureType": "road.arterial","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.arterial","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "road.highway","elementType": "geometry.fill","stylers": [{"color": "#746855"}]},{"featureType": "road.highway","elementType": "geometry.stroke","stylers": [{"color": "#1f2835"}]},{"featureType": "road.highway","elementType": "labels.text.fill","stylers": [{"color": "#f3d19c"}]},{"featureType": "road.local","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.local","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "transit","elementType": "geometry","stylers": [{"color": "#2f3948"}]},{"featureType": "transit.station","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "water","elementType": "geometry","stylers": [{"color": "#17263c"}]},{"featureType": "water","elementType": "labels.text.fill","stylers": [{"color": "#515c6d"}]},{"featureType": "water","elementType": "labels.text.stroke","stylers": [{"lightness": -20}]}]');
//   }
//
//   showDriverBottomSheet(User user) async {
//     double distanceInMeters = Geolocator.distanceBetween(
//         user.orderRequestData!.vendor.latitude,
//         user.orderRequestData!.vendor.longitude,
//         user.orderRequestData!.author.shippingAddress.location.latitude,
//         user.orderRequestData!.author.shippingAddress.location.longitude);
//     double kilometer = distanceInMeters / 1000;
//     if (canShowSheet) {
//       canShowSheet = false;
//       await showModalBottomSheet(
//         isDismissible: false,
//         enableDrag: false,
//         backgroundColor: Colors.transparent,
//         barrierColor: Colors.transparent,
//         context: context,
//         builder: (context) {
//           return WillPopScope(
//             // ignore: missing_return
//             onWillPop: () async => false,
//             child: Padding(
//               padding: EdgeInsets.all(15),
//               child: Container(
//                 height: MediaQuery.of(context).size.height / 2.6,
//                 padding: EdgeInsets.symmetric(vertical: 16, horizontal: 10),
//                 decoration: BoxDecoration(
//                   color: Color(0xff212121),
//                   borderRadius: BorderRadius.all(Radius.circular(15)),
//                 ),
//                 child: SingleChildScrollView(
//                   child: Column(
//                     // crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       Center(
//                         child: Text(
//                           'New Order!'.tr(),
//                           style: TextStyle(
//                               color: Color(0xffFFFFFF),
//                               fontFamily: "Poppinssb",
//                               letterSpacing: 0.5),
//                         ),
//                       ),
//                       SizedBox(height: 10),
//                       IntrinsicHeight(
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             // Container(
//                             //   width: MediaQuery.of(context).size.width / 2.5,
//                             //   height: MediaQuery.of(context).size.height / 9.2,
//                             //   child: Column(
//                             //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                             //     children: [
//                             //       Text(
//                             //         "Expected Earning",
//                             //         style: TextStyle(
//                             //           color: Color(0xffADADAD),
//                             //           fontFamily: "Poppinsr",
//                             //           letterSpacing: 0.5,
//                             //         ),
//                             //       ),
//                             //       Text(
//                             //         symbol+ "${25.00}",
//                             //         style: TextStyle(
//                             //             color: Color(0xffFFFFFF),
//                             //             fontFamily: "Poppinsm",
//                             //             letterSpacing: 0.5),
//                             //       ),
//                             //     ],
//                             //   ),
//                             // ),
//                             // VerticalDivider(color: Color(0xff4E4F53)),
//                             Container(
//                               width: MediaQuery.of(context).size.width / 2.5,
//                               height: MediaQuery.of(context).size.height / 9.2,
//                               child: Column(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceEvenly,
//                                 children: [
//                                   Text(
//                                     "Trip Distance".tr(),
//                                     style: TextStyle(
//                                         color: Color(0xffADADAD),
//                                         fontFamily: "Poppinsr",
//                                         letterSpacing: 0.5),
//                                   ),
//                                   Text(
//                                     // '0',
//                                     "${kilometer.toStringAsFixed(decimal)} km",
//                                     style: TextStyle(
//                                         color: Color(0xffFFFFFF),
//                                         fontFamily: "Poppinsm",
//                                         letterSpacing: 0.5),
//                                   ),
//                                 ],
//                               ),
//                             )
//                           ],
//                         ),
//                       ),
//                       SizedBox(height: 5),
//                       Card(
//                         color: Color(0xffFFFFFF),
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(
//                               vertical: 14.0, horizontal: 10),
//                           child: Row(
//                             children: [
//                               Image.asset(
//                                 'assets/images/location3x.png',
//                                 height: 55,
//                               ),
//                               SizedBox(width: 10),
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   SizedBox(
//                                     width: 270,
//                                     child: Text(
//                                       "${user.orderRequestData!.vendor.location} ",
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                       style: TextStyle(
//                                           color: Color(0xff333333),
//                                           fontFamily: "Poppinsr",
//                                           letterSpacing: 0.5),
//                                     ),
//                                   ),
//                                   SizedBox(height: 22),
//                                   SizedBox(
//                                     width: 270,
//                                     child: Text(
//                                       "${user.orderRequestData!.address.line1} "
//                                       "${user.orderRequestData!.address.line2} "
//                                       "${user.orderRequestData!.address.city}",
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                       style: TextStyle(
//                                           color: Color(0xff333333),
//                                           fontFamily: "Poppinsr",
//                                           letterSpacing: 0.5),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 10),
//                       // Text('${currentOrder!.author.shippingAddress.line1} '
//                       //     '${currentOrder!.author.shippingAddress.line2} '
//                       //     '${currentOrder!.author.shippingAddress.city}'),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceAround,
//                         children: [
//                           SizedBox(
//                             height: MediaQuery.of(context).size.height / 20,
//                             width: MediaQuery.of(context).size.width / 2.5,
//                             child: ElevatedButton(
//                               style: ElevatedButton.styleFrom(
//                                 padding: const EdgeInsets.symmetric(
//                                     vertical: 6, horizontal: 12),
//                                 primary: Color(0xff434242),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.all(
//                                     Radius.circular(5),
//                                   ),
//                                 ),
//                               ),
//                               child: Text(
//                                 'REJECT',
//                                 style: TextStyle(
//                                     color: Color(0xffFFFFFF),
//                                     fontFamily: "Poppinsm",
//                                     letterSpacing: 0.5),
//                               ),
//                               onPressed: () async {
//                                 Navigator.pop(context);
//                                 showProgress(
//                                     context, 'Rejecting order...'.tr(), false);
//                                 try {
//                                   await rejectOrder(user);
//                                   hideProgress();
//                                 } catch (e) {
//                                   hideProgress();
//                                   print(
//                                       'HomeScreenState.showDriverBottomSheet $e');
//                                 }
//                               },
//                             ),
//                           ),
//                           SizedBox(
//                             height: MediaQuery.of(context).size.height / 20,
//                             width: MediaQuery.of(context).size.width / 2.5,
//                             child: ElevatedButton(
//                                 style: ElevatedButton.styleFrom(
//                                   padding: const EdgeInsets.symmetric(
//                                       vertical: 6, horizontal: 12),
//                                   primary: Colors.purple,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.all(
//                                       Radius.circular(5),
//                                     ),
//                                   ),
//                                 ),
//                                 child: Text(
//                                   'Accept'.tr(),
//                                   style: TextStyle(
//                                       color: Color(0xffFFFFFF),
//                                       fontFamily: "Poppinsm",
//                                       letterSpacing: 0.5),
//                                 ),
//                                 onPressed: () async {
//                                   Navigator.pop(context);
//                                   showProgress(context,
//                                       'Accepting order...'.tr(), false);
//                                   try {
//                                     await acceptOrder(user);
//                                     updateProgress(
//                                         'Finding the best route...'.tr());
//                                     await addPolyLinesAndMarkersToMap(user);
//                                     hideProgress();
//                                     setState(() {});
//                                   } catch (e) {
//                                     hideProgress();
//                                     print(
//                                         'HomeScreenState.showDriverBottomSheet $e');
//                                   }
//                                 }),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//       canShowSheet = true;
//     }
//   }
//
//   acceptOrder(User user) async {
//     print("user data ");
//     log("user data 47 "+user.toString());
//     OrderModel orderModel = user.orderRequestData!;
//     orderModel.status = ORDER_STATUS_DRIVER_ACCEPTED;
//     orderModel.driverID = user.userID;
//
//     Position? locationData = await getCurrentLocation();
//     if (locationData != null) {
//       user.location = UserLocation(
//           latitude: locationData.latitude, longitude: locationData.longitude);
//       user.geoFireData = GeoFireData(
//           geohash: Geoflutterfire().point(latitude: locationData.latitude, longitude: locationData.longitude).hash,
//           geoPoint: GeoPoint(locationData.latitude, locationData.longitude));
//     }
//     orderModel.driver = user;
//     await FireStoreUtils.updateOrder(orderModel);
//     currentOrder = orderModel;
//
//     user.orderRequestData = null;
//     user.inProgressOrderID = orderModel.id;
//
//     MyAppState.currentUser = user;
//     await FireStoreUtils.updateCurrentUser(user);
//
//     await FireStoreUtils.sendFcmMessage("Delivery Agent Assigned.".tr(), user.firstName+" "+user.lastName+" will deliver Your Order.", orderModel.author.fcmToken, orderModel.vendor.fcmToken);
//   }
//
//   rejectOrder(User user) async {
//     OrderModel orderModel = user.orderRequestData!;
//     orderModel.rejectedByDrivers.add(user.userID);
//     orderModel.status = ORDER_STATUS_DRIVER_REJECTED;
//     await FireStoreUtils.updateOrder(orderModel);
//     user.orderRequestData = null;
//     MyAppState.currentUser = user;
//     await FireStoreUtils.updateCurrentUser(user);
//   }
//
//   addPolyLinesAndMarkersToMap(User user) async {
//     PolylineResult? result;
//     if (currentOrder!.status == ORDER_STATUS_SHIPPED ||
//         currentOrder!.status == ORDER_STATUS_DRIVER_ACCEPTED) {
//       result = await polylinePoints.getRouteBetweenCoordinates(
//         GOOGLE_API_KEY,
//         PointLatLng(user.location.latitude, user.location.longitude),
//         PointLatLng(
//             currentOrder!.vendor.latitude, currentOrder!.vendor.longitude),
//       );
//     } else if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT) {
//       result = await polylinePoints.getRouteBetweenCoordinates(GOOGLE_API_KEY,
//         PointLatLng(
//             currentOrder!.vendor.latitude, currentOrder!.vendor.longitude),
//         PointLatLng(currentOrder!.author.shippingAddress.location.latitude,
//             currentOrder!.author.shippingAddress.location.longitude),
//       );
//     }
//     print("poly resulkt ${currentOrder!.vendor.longitude}  aur  ${currentOrder!.author.shippingAddress.location.longitude}");
//
//     if (result!=null && result.status == 'OK') {
//       polylineCoordinates.clear();
//       for (PointLatLng point in result.points) {
//         polylineCoordinates.add(LatLng(point.latitude, point.longitude));
//       }
//     }
//
//     mapMarkers.clear();
//     polylines.clear();
//     if (currentOrder!.status == ORDER_STATUS_SHIPPED ||
//         currentOrder!.status == ORDER_STATUS_DRIVER_ACCEPTED) {
//       mapMarkers.add(
//         Marker(
//             markerId: MarkerId('driverMarker'),
//             position: polylineCoordinates.first,
//             icon: driverIcon),
//       );
//       mapMarkers.add(
//         Marker(
//             markerId: MarkerId('storeMarker'),
//             position: polylineCoordinates.last,
//             infoWindow: InfoWindow(title: '${currentOrder!.vendor.title}'),
//             icon: storeIcon),
//       );
//     } else if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT) {
//       mapMarkers.add(
//         Marker(
//             markerId: MarkerId('storeMarker'),
//             position: polylineCoordinates.first,
//             infoWindow: InfoWindow(title: '${currentOrder!.vendor.title}'),
//             icon: storeIcon),
//       );
//       mapMarkers.add(
//         Marker(
//             markerId: MarkerId('customerMarker'),
//             position: polylineCoordinates.last,
//             infoWindow: InfoWindow(title: '${currentOrder!.author.firstName}'),
//             icon: customerIcon),
//       );
//     }
//     print(currentOrder!.id);
//     polylines.add(
//       Polyline(
//         polylineId: PolylineId(
//             'polyline_id_${currentOrder!.driver!.userID}_to_${currentOrder!.vendor.title}'),
//         color: isDarkMode(context) ? Colors.white : Colors.black,
//         width: 5,
//         points: polylineCoordinates,
//       ),
//     );
//     updateCameraLocation(
//         polylineCoordinates.first, polylineCoordinates.last, _mapController);
//   }
//
//   Future<void> updateCameraLocation(
//     LatLng source,
//     LatLng destination,
//     GoogleMapController? mapController,
//   ) async {
//     if (mapController == null) return;
//
//     LatLngBounds bounds;
//
//     if (source.latitude > destination.latitude &&
//         source.longitude > destination.longitude) {
//       bounds = LatLngBounds(southwest: destination, northeast: source);
//     } else if (source.longitude > destination.longitude) {
//       bounds = LatLngBounds(
//           southwest: LatLng(source.latitude, destination.longitude),
//           northeast: LatLng(destination.latitude, source.longitude));
//     } else if (source.latitude > destination.latitude) {
//       bounds = LatLngBounds(
//           southwest: LatLng(destination.latitude, source.longitude),
//           northeast: LatLng(source.latitude, destination.longitude));
//     } else {
//       bounds = LatLngBounds(southwest: source, northeast: destination);
//     }
//
//     CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 100);
//
//     return checkCameraLocation(cameraUpdate, mapController);
//   }
//
//   Future<void> checkCameraLocation(
//       CameraUpdate cameraUpdate, GoogleMapController mapController) async {
//     mapController.animateCamera(cameraUpdate);
//     LatLngBounds l1 = await mapController.getVisibleRegion();
//     LatLngBounds l2 = await mapController.getVisibleRegion();
//
//     if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
//       return checkCameraLocation(cameraUpdate, mapController);
//     }
//   }
//
//   getCurrentOrder() async {
//     currentOrder = await fireStoreUtils
//         .getOrderByID(MyAppState.currentUser!.inProgressOrderID ?? '');
//     if (currentOrder != null) {
//       await addPolyLinesAndMarkersToMap(MyAppState.currentUser!);
//       setState(() {});
//     }
//   }
//
//   Widget buildOrderActionsCard(User user) {
//     late String title;
//     String? buttonText;
//     if (currentOrder!.status == ORDER_STATUS_SHIPPED ||
//         currentOrder!.status == ORDER_STATUS_DRIVER_ACCEPTED) {
//       title = '${currentOrder!.vendor.title}';
//       buttonText = 'REACHED STORE FOR PICKUP'.tr();
//     } else if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT) {
//       title = 'Deliver to {}'.tr(args: ['${currentOrder!.author.firstName}']);
//       // buttonText = 'Complete Pick Up'.tr();
//       buttonText = 'REACHED CUSTOMER DOOR STEP'.tr();
//     }
//
//     return Container(
//       margin: EdgeInsets.only(left: 8, right: 8),
//       padding: EdgeInsets.symmetric(vertical: 15),
//       height: MediaQuery.of(context).size.height / 3.2,
//       width: MediaQuery.of(context).size.width,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(8), topRight: Radius.circular(18)),
//         color: isDarkMode(context) ? Color(0xff000000) : Color(0xffFFFFFF),
//       ),
//       child: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (currentOrder!.status == ORDER_STATUS_SHIPPED ||
//                 currentOrder!.status == ORDER_STATUS_DRIVER_ACCEPTED)
//               ListTile(
//                 title: Text(
//                   title,
//                   style: TextStyle(
//                       color: isDarkMode(context)
//                           ? Color(0xffFFFFFF)
//                           : Color(0xff000000),
//                       fontFamily: "Poppinsm",
//                       letterSpacing: 0.5),
//                 ),
//                 subtitle: Padding(
//                   padding: const EdgeInsets.only(top: 4.0),
//                   child: Text(
//                     '${currentOrder!.vendor.location}',
//                     maxLines: 2,
//                     style: TextStyle(
//                         color: isDarkMode(context)
//                             ? Color(0xffFFFFFF)
//                             : Color(0xff000000),
//                         fontFamily: "Poppinsr",
//                         letterSpacing: 0.5),
//                   ),
//                 ),
//                 trailing: TextButton.icon(
//                     style: TextButton.styleFrom(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(6.0),
//                         side: BorderSide(color: Color(0xff3DAE7D)),
//                       ),
//                       padding: EdgeInsets.zero,
//                       minimumSize: Size(85, 30),
//                       alignment: Alignment.center,
//                       backgroundColor: Color(0xffFFFFFF),
//                     ),
//                     onPressed: () {
//                       UrlLauncher.launch(
//                           "tel://${currentOrder!.vendor.phonenumber}");
//                     },
//                     icon: Image.asset(
//                       'assets/images/call3x.png',
//                       height: 14,
//                       width: 14,
//                     ),
//                     label: Text(
//                       "CALL",
//                       style: TextStyle(
//                           color: Color(0xff3DAE7D),
//                           fontFamily: "Poppinsm",
//                           letterSpacing: 0.5),
//                     )),
//               ),
//             if (currentOrder!.status == ORDER_STATUS_SHIPPED ||
//                 currentOrder!.status == ORDER_STATUS_DRIVER_ACCEPTED)
//               ListTile(
//                 tileColor: Color(0xffF1F4F8),
//                 contentPadding:
//                     EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                 title: Row(
//                   children: [
//                     Text(
//                       'ORDER ID '.tr(),
//                       style: TextStyle(
//                           color: isDarkMode(context)
//                               ? Color(0xffFFFFFF)
//                               : Color(0xff555555),
//                           fontFamily: "Poppinsr",
//                           letterSpacing: 0.5),
//                     ),
//                     SizedBox(
//                       width: 110,
//                       child: Text(
//                         '${currentOrder!.id}',
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                             color: isDarkMode(context)
//                                 ? Color(0xffFFFFFF)
//                                 : Color(0xff000000),
//                             fontFamily: "Poppinsr",
//                             letterSpacing: 0.5),
//                       ),
//                     ),
//                   ],
//                 ),
//                 subtitle: Padding(
//                   padding: const EdgeInsets.only(top: 4.0),
//                   child: Text(
//                     '${currentOrder!.author.shippingAddress.name}',
//                     style: TextStyle(
//                         color: isDarkMode(context)
//                             ? Color(0xffFFFFFF)
//                             : Color(0xff333333),
//                         fontFamily: "Poppinsm",
//                         letterSpacing: 0.5),
//                   ),
//                 ),
//               ),
//
//             if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT)
//               ListTile(
//                 leading: Image.asset(
//                   'assets/images/user3x.png',
//                   height: 42,
//                   width: 42,
//                   color: Colors.purple,
//                 ),
//                 title: Text(
//                   '${currentOrder!.author.shippingAddress.name}',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                       color: isDarkMode(context)
//                           ? Color(0xffFFFFFF)
//                           : Color(0xff000000),
//                       fontFamily: "Poppinsm",
//                       letterSpacing: 0.5),
//                 ),
//                 subtitle: Row(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.only(top: 4.0),
//                       child: Text(
//                         'ORDER ID '.tr(),
//                         style: TextStyle(
//                             color: Color(0xff555555),
//                             fontFamily: "Poppinsr",
//                             letterSpacing: 0.5),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.only(top: 4.0),
//                       child: SizedBox(
//                         width: MediaQuery.of(context).size.width / 4,
//                         child: Text(
//                           '${currentOrder!.id} ',
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                               color: isDarkMode(context)
//                                   ? Color(0xffFFFFFF)
//                                   : Color(0xff000000),
//                               fontFamily: "Poppinsr",
//                               letterSpacing: 0.5),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 trailing: Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   children: [
//                     TextButton.icon(
//                         style: TextButton.styleFrom(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(6.0),
//                             side: BorderSide(color: Color(0xff3DAE7D)),
//                           ),
//                           padding: EdgeInsets.zero,
//                           minimumSize: Size(85, 30),
//                           alignment: Alignment.center,
//                           backgroundColor: Color(0xffFFFFFF),
//                         ),
//                         onPressed: () {
//                           UrlLauncher.launch(
//                               "tel://${currentOrder!.author.phoneNumber}");
//                         },
//                         icon: Image.asset(
//                           'assets/images/call3x.png',
//                           height: 14,
//                           width: 14,
//                         ),
//                         label: Text(
//                           "CALL".tr(),
//                           style: TextStyle(
//                               color: Color(0xff3DAE7D),
//                               fontFamily: "Poppinsm",
//                               letterSpacing: 0.5),
//                         )),
//                   ],
//                 ),
//               ),
//
//             if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT)
//               ListTile(
//                 leading: Image.asset(
//                   'assets/images/delivery_location3x.png',
//                   height: 42,
//                   width: 42,
//                   color: Colors.purple,
//                 ),
//                 title: Text(
//                   'DELIVER'.tr(),
//                   style: TextStyle(
//                       color: Color(0xff9091A4),
//                       fontFamily: "Poppinsr",
//                       letterSpacing: 0.5),
//                 ),
//                 subtitle: Padding(
//                   padding: const EdgeInsets.only(top: 4.0),
//                   child: Text(
//                     '${currentOrder!.author.shippingAddress.line1},${currentOrder!.author.shippingAddress.line2},${currentOrder!.author.shippingAddress.city},${currentOrder!.author.shippingAddress.country}',
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                         color: isDarkMode(context)
//                             ? Color(0xffFFFFFF)
//                             : Color(0xff333333),
//                         fontFamily: "Poppinsr",
//                         letterSpacing: 0.5),
//                   ),
//                 ),
//                 trailing: Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   children: [
//                     TextButton.icon(
//                         style: TextButton.styleFrom(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(6.0),
//                             side: BorderSide(color: Color(0xff3DAE7D)),
//                           ),
//                           padding: EdgeInsets.zero,
//                           minimumSize: Size(100, 30),
//                           alignment: Alignment.center,
//                           backgroundColor: Color(0xffFFFFFF),
//                         ),
//                         onPressed: () => openChatWithCustomer(),
//                         icon: Icon(
//                           Icons.message,
//                           size: 16,
//                           color: Color(0xff3DAE7D),
//                         ),
//                         // Image.asset(
//                         //   'assets/images/call3x.png',
//                         //   height: 14,
//                         //   width: 14,
//                         // ),
//                         label: Text(
//                           "Message",
//                           style: TextStyle(
//                               color: Color(0xff3DAE7D),
//                               fontFamily: "Poppinsm",
//                               letterSpacing: 0.5),
//                         )),
//                   ],
//                 ),
//               ),
//
//             if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT)
//               SizedBox(height: 25),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 14),
//               child: SizedBox(
//                 height: 40,
//                 width: MediaQuery.of(context).size.width,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.all(
//                         Radius.circular(4),
//                       ),
//                     ),
//                     primary: Colors.purple,
//                   ),
//                   onPressed: () async {
//                     if (currentOrder!.status == ORDER_STATUS_SHIPPED ||
//                         currentOrder!.status == ORDER_STATUS_DRIVER_ACCEPTED)
//                       completePickUp();
//                     //////////////////////////////////////////////////////////////
//                     /////picked order
//                     else if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT)
//                       //////////////////////////////////////////////////////////////
//                       /////make order deliver
//                       push(
//                         context,
//                         Scaffold(
//                           appBar: AppBar(
//                             leading: IconButton(
//                               icon: Icon(Icons.chevron_left),
//                               onPressed: () => Navigator.pop(context),
//                             ),
//                             titleSpacing: -8,
//                             title: Text(
//                               "Deliver".tr()+": ${currentOrder!.id}",
//                               style: TextStyle(
//                                   color: isDarkMode(context)
//                                       ? Color(0xffFFFFFF)
//                                       : Color(0xff000000),
//                                   fontFamily: "Poppinsr",
//                                   letterSpacing: 0.5),
//                             ),
//                             centerTitle: false,
//                           ),
//                           body: Padding(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 25.0, vertical: 20),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(
//                                       horizontal: 25.0, vertical: 20),
//                                   decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(2),
//                                       border: Border.all(
//                                           color: Colors.grey.shade100,
//                                           width: 0.1),
//                                       boxShadow: [
//                                         BoxShadow(
//                                           color: Colors.grey.shade200,
//                                           blurRadius: 2.0,
//                                           spreadRadius: 0.4,
//                                           offset: Offset(0.2, 0.2),
//                                         ),
//                                       ],
//                                       color: Colors.white),
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           Text(
//                                             'DELIVER'.tr().toUpperCase(),
//                                             style: TextStyle(
//                                                 color: Color(0xff9091A4),
//                                                 fontFamily: "Poppinsr",
//                                                 letterSpacing: 0.5),
//                                           ),
//                                           TextButton.icon(
//                                               style: TextButton.styleFrom(
//                                                 shape: RoundedRectangleBorder(
//                                                   borderRadius:
//                                                       BorderRadius.circular(
//                                                           6.0),
//                                                   side: BorderSide(
//                                                       color: Color(0xff3DAE7D)),
//                                                 ),
//                                                 padding: EdgeInsets.zero,
//                                                 minimumSize: Size(85, 30),
//                                                 alignment: Alignment.center,
//                                                 backgroundColor:
//                                                     Color(0xffFFFFFF),
//                                               ),
//                                               onPressed: () {
//                                                 UrlLauncher.launch(
//                                                     "tel://${currentOrder!.author.phoneNumber}");
//                                               },
//                                               icon: Image.asset(
//                                                 'assets/images/call3x.png',
//                                                 height: 14,
//                                                 width: 14,
//                                               ),
//                                               label: Text(
//                                                 "CALL".tr().toUpperCase(),
//                                                 style: TextStyle(
//                                                     color: Color(0xff3DAE7D),
//                                                     fontFamily: "Poppinsm",
//                                                     letterSpacing: 0.5),
//                                               )),
//                                         ],
//                                       ),
//                                       Text(
//                                         '${currentOrder!.author.shippingAddress.name}',
//                                         style: TextStyle(
//                                             color: Color(0xff333333),
//                                             fontFamily: "Poppinsm",
//                                             letterSpacing: 0.5),
//                                       ),
//                                       Padding(
//                                         padding:
//                                             const EdgeInsets.only(top: 4.0),
//                                         child: Text(
//                                           '${currentOrder!.author.shippingAddress.line1},'
//                                           '${currentOrder!.author.shippingAddress.line2},'
//                                           '${currentOrder!.author.shippingAddress.city}',
//                                           maxLines: 2,
//                                           overflow: TextOverflow.ellipsis,
//                                           style: TextStyle(
//                                               color: Color(0xff9091A4),
//                                               fontFamily: "Poppinsr",
//                                               letterSpacing: 0.5),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 SizedBox(height: 28),
//                                 Text(
//                                   "ITEMS".tr().toUpperCase(),
//                                   style: TextStyle(
//                                       color: Color(0xff9091A4),
//                                       fontFamily: "Poppinsm",
//                                       letterSpacing: 0.5),
//                                 ),
//                                 SizedBox(height: 24),
//                                 ListView.builder(
//                                     shrinkWrap: true,
//                                     itemCount: currentOrder!.products.length,
//                                     itemBuilder: (context, index) {
//                                       return Container(padding: EdgeInsets.only(bottom: 10),
//                                         child:
//                                       Row(
//                                         children: [
//                                           Expanded(
//                                             flex: 2,
//                                             child: CachedNetworkImage(
//                                                 height: 55,
//                                                 // width: 50,
//                                                 imageUrl:
//                                                     '${currentOrder!.products[index].photo}',
//                                                 imageBuilder: (context,
//                                                         imageProvider) =>
//                                                     Container(
//                                                       decoration: BoxDecoration(
//                                                           borderRadius:
//                                                               BorderRadius
//                                                                   .circular(8),
//                                                           image:
//                                                               DecorationImage(
//                                                             image:
//                                                                 imageProvider,
//                                                             fit: BoxFit.cover,
//                                                           )),
//                                                     )),
//                                           ),
//                                           Expanded(
//                                             flex: 10,
//                                             child: Padding(
//                                               padding: const EdgeInsets.only(
//                                                   left: 14.0),
//                                               child: Column(
//                                                 crossAxisAlignment:
//                                                     CrossAxisAlignment.start,
//                                                 mainAxisAlignment:
//                                                     MainAxisAlignment
//                                                         .spaceBetween,
//                                                 children: [
//                                                   Text(
//                                                     '${currentOrder!.products[index].name}',
//                                                     style: TextStyle(
//                                                         fontFamily: 'Poppinsr',
//                                                         letterSpacing: 0.5,
//                                                         color: isDarkMode(
//                                                                 context)
//                                                             ? Color(0xffFFFFFF)
//                                                             : Color(
//                                                                 0xff333333)),
//                                                   ),
//                                                   SizedBox(height: 5),
//                                                   Row(
//                                                     children: [
//                                                       Icon(Icons.close,
//                                                           size: 15,
//                                                         color: Colors.purple,),
//                                                       Text(
//                                                           '${currentOrder!.products[index].quantity}',
//                                                           style: TextStyle(
//                                                             fontFamily:
//                                                                 'Poppinsm',
//                                                             letterSpacing: 0.5,
//                                                             color: Colors.purple,
//                                                           )),
//                                                     ],
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                           )
//                                         ],
//                                       ));
//                                       // Card(
//                                       //   child: Text(widget.currentOrder!.products[index].name),
//                                       // );
//                                     }),
//                                 SizedBox(height: 28),
//                                 Container(
//                                   decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(4),
//                                       border:
//                                           Border.all(color: Color(0xffC2C4CE)),
//                                       // boxShadow: [
//                                       //   BoxShadow(
//                                       //       color: Colors.grey.shade200,
//                                       //       blurRadius: 8.0,
//                                       //       spreadRadius: 1.2,
//                                       //       offset: Offset(0.2, 0.2)),
//                                       // ],
//                                       color: Colors.white),
//                                   child: ListTile(
//                                     minLeadingWidth: 20,
//                                     leading: Image.asset(
//                                       'assets/images/mark_selected3x.png',
//                                       height: 24,
//                                       width: 24,
//                                     ),
//                                     title: Text(
//                                       "Given".tr()+" ${currentOrder!.products.length} "+"item to customer".tr(),
//                                       style: TextStyle(
//                                           color: Color(0xff3DAE7D),
//                                           fontFamily: 'Poppinsm',
//                                           letterSpacing: 0.5),
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(height: 26),
//                               ],
//                             ),
//                           ),
//                           bottomNavigationBar: Padding(
//                             padding: const EdgeInsets.symmetric(
//                                 vertical: 14.0, horizontal: 26),
//                             child: SizedBox(
//                               height: 45,
//                               child: ElevatedButton(
//                                 style: ElevatedButton.styleFrom(
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.all(
//                                       Radius.circular(8),
//                                     ),
//                                   ),
//                                   primary: Color(0xff3DAE7D),
//                                 ),
//                                 child: Text(
//                                   "MARK ORDER DELIVER".tr(),
//                                   style: TextStyle(
//                                     letterSpacing: 0.5,
//                                     fontFamily: 'Poppinsm',
//                                   ),
//                                 ),
//                                 onPressed: () => completeOrder(),
//                               ),
//                             ),
//                           ),
//                         ),
//                       );
//
//                     // completeOrder();
//                   },
//                   child: Text(
//                     buttonText??"",
//                     style: TextStyle(
//                         color: Color(0xffFFFFFF),
//                         fontFamily: "Poppinsm",
//                         letterSpacing: 0.5),
//                   ),
//                 ),
//               ),
//             ),
//
//             //   ],
//             // ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   completePickUp() async {
//     print('HomeScreenState.completePickUp');
//     showProgress(context, 'Updating order...', false);
//     currentOrder!.status = ORDER_STATUS_IN_TRANSIT;
//     await FireStoreUtils.updateOrder(currentOrder!);
//
//     await addPolyLinesAndMarkersToMap(MyAppState.currentUser!);
//     hideProgress();
//     setState(() {});
//     push(
//       context,
//       PickOrder(currentOrder: currentOrder),
//     );
//   }
//
//   completeOrder() async {
//     showProgress(context, 'Completing Delivery...'.tr(), false);
//     currentOrder!.status = ORDER_STATUS_COMPLETED;
//     updateWallateAmount(currentOrder!);
//     await FireStoreUtils.updateOrder(currentOrder!);
//     Position? locationData = await getCurrentLocation();
//     if (locationData != null) {
//       MyAppState.currentUser!.location = UserLocation(
//           latitude: locationData.latitude, longitude: locationData.longitude);
//       MyAppState.currentUser!.geoFireData = GeoFireData(
//           geohash: Geoflutterfire().point(latitude: locationData.latitude, longitude: locationData.longitude).hash,
//           geoPoint: GeoPoint(locationData.latitude, locationData.longitude));
//     }
//     await FireStoreUtils.sendFcmMessage("Order Complete".tr(), "Our Delivery agent delivered order.".tr(), currentOrder!.author.fcmToken, null);
//     MyAppState.currentUser!.inProgressOrderID = null;
//     currentOrder = null;
//     await FireStoreUtils.updateCurrentUser(MyAppState.currentUser!);
//     hideProgress();
//     mapMarkers.clear();
//     polylines.clear();
//     _mapController?.moveCamera(
//       CameraUpdate.newCameraPosition(
//         CameraPosition(
//             target: LatLng(
//                 locationData.latitude , locationData.longitude ),
//             zoom: 15),
//       ),
//     );
//
//     setState(() {});
//     Navigator.pop(context);
//   }
//
//   openChatWithCustomer() async {
//     late String channelID;
//     if (currentOrder!.driver!.userID.compareTo(currentOrder!.author.userID) <
//         0) {
//       channelID = currentOrder!.driver!.userID + currentOrder!.author.userID;
//     } else {
//       channelID = currentOrder!.author.userID + currentOrder!.driver!.userID;
//     }
//
//     ConversationModel? conversationModel =
//         await fireStoreUtils.getChannelByIdOrNull(channelID);
//     push(
//       context,
//       ChatScreen(
//         homeConversationModel: HomeConversationModel(
//             members: [currentOrder!.author],
//             conversationModel: conversationModel),
//       ),
//     );
//   }
//
//   goOnline(User user) async {
//     await showProgress(context, 'Going online...'.tr(), false);
//     Position locationData = await getCurrentLocation();
//     print('HomeScreenState.goOnline');
//     user.isActive = true;
//     if (locationData != null) {
//       user.location = UserLocation(latitude: locationData.latitude, longitude: locationData.longitude);
//       user.geoFireData = GeoFireData(
//           geohash: Geoflutterfire().point(latitude: locationData.latitude, longitude: locationData.longitude).hash,
//           geoPoint: GeoPoint(locationData.latitude, locationData.longitude));
//     }
//     MyAppState.currentUser = user;
//     await FireStoreUtils.updateCurrentUser(user);
//     await hideProgress();
//   }
//
//   // getcurcy() {
//   //   return FutureBuilder<List<CurrencyModel>>(
//   //       future: futureCurrency,
//   //       initialData: [],
//   //       builder: (context, snapshot) {
//   //         if (snapshot.hasData) {
//   //           var data = snapshot.data;
//
//   //           Container(
//   //               height: 0,
//   //               child: ListView.builder(
//   //                   shrinkWrap: true,
//   //                   itemCount: data!.length,
//   //                   itemBuilder: (BuildContext context, int index) {
//   //                     return curcy(data[index]);
//   //                   }));
//   //         }
//   //         return Center(
//   //           child: CircularProgressIndicator.adaptive(
//   //             valueColor: AlwaysStoppedAnimation(Colors.purple),
//   //           ),
//   //         );
//   //       });
//   // }
//
//   curcy(CurrencyModel currency) {
//     if (currency.isactive == true) {
//       symbol = currency.symbol;
//       isRight = currency.symbolatright;
//       decimal = currency.decimal;
//       return Center();
//     }
//     return Center();
//   }
// }
