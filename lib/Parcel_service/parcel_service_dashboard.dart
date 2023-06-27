import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartdriver/Parcel_service/parcel_home_screen.dart';
import 'package:emartdriver/Parcel_service/parcel_order_screen.dart';
import 'package:emartdriver/constants.dart';
import 'package:emartdriver/main.dart';
import 'package:emartdriver/model/CurrencyModel.dart';
import 'package:emartdriver/model/User.dart';
import 'package:emartdriver/services/FirebaseHelper.dart';
import 'package:emartdriver/services/helper.dart';
import 'package:emartdriver/ui/Language/language_choose_screen.dart';
import 'package:emartdriver/ui/auth/AuthScreen.dart';
import 'package:emartdriver/ui/bank_details/bank_details_Screen.dart';
import 'package:emartdriver/ui/container/ContainerScreen.dart';
import 'package:emartdriver/ui/privacy_policy/privacy_policy.dart';
import 'package:emartdriver/ui/profile/ProfileScreen.dart';
import 'package:emartdriver/ui/termsAndCondition/terms_and_codition.dart';
import 'package:emartdriver/ui/wallet/walletScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class ParcelServiceDashBoard extends StatefulWidget {
  final User user;
  const ParcelServiceDashBoard({Key? key, required this.user}) : super(key: key);

  @override
  State<ParcelServiceDashBoard> createState() => _ParcelServiceDashBoardState();
}

class _ParcelServiceDashBoardState extends State<ParcelServiceDashBoard> {
  String _appBarTitle = 'Home'.tr();
  final fireStoreUtils = FireStoreUtils();
  late Widget _currentWidget;
  DrawerSelection _drawerSelection = DrawerSelection.Home;

  bool isLanguageShown = false;

  @override
  void initState() {
    super.initState();
    setCurrency();
    _currentWidget = ParcelHomeScreen(
      refresh: () {
        if (mounted) setState(() {});
      },
    );
    updateCurrentLocation();
    getLanguages();

    /// On iOS, we request notification permissions, Does nothing and returns null on Android
    FireStoreUtils.firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  setCurrency() {
    FireStoreUtils().getCurrency().then((value) => value.forEach((element) {
          if (element.isactive = true) {
            symbol = element.symbol;
            isRight = element.symbolatright;
            decimal = element.decimal;
            currName = element.code;
            currencyData = element;
          }
        }));
  }

  Location location = Location();
  updateCurrentLocation() async {
    print("---->22222");

    LocationData currentLocation;

    PermissionStatus permissionStatus = await location.hasPermission();
    if (permissionStatus == PermissionStatus.granted) {
      print("---->");
      location.enableBackgroundMode(enable: true);
      location.changeSettings(interval: 60000);
      location.onLocationChanged.listen((locationData) {
        currentLocation = locationData;
        UserLocation location = UserLocation(latitude: currentLocation.latitude!.toDouble(), longitude: currentLocation.longitude!.toDouble());
        MyAppState.currentUser!.location = location;
        MyAppState.currentUser!.rotation = currentLocation.heading;
        MyAppState.currentUser!.geoFireData = GeoFireData(
            geohash: Geoflutterfire().point(latitude: locationData.latitude!.toDouble(), longitude: locationData.longitude!.toDouble()).hash,
            geoPoint: GeoPoint(locationData.latitude!.toDouble(), locationData.longitude!.toDouble()));
        FireStoreUtils.updateCurrentUser(MyAppState.currentUser!);
      });
    } else {
      location.requestPermission().then((permissionStatus) {
        if (permissionStatus == PermissionStatus.granted) {
          print("---->");
          location.enableBackgroundMode(enable: true);
          location.changeSettings(interval: 60000);
          location.onLocationChanged.listen((locationData) {
            currentLocation = locationData;
            UserLocation location = UserLocation(latitude: currentLocation.latitude!.toDouble(), longitude: currentLocation.longitude!.toDouble());
            MyAppState.currentUser!.location = location;
            MyAppState.currentUser!.rotation = currentLocation.heading;
            MyAppState.currentUser!.geoFireData = GeoFireData(
                geohash: Geoflutterfire().point(latitude: locationData.latitude!.toDouble(), longitude: locationData.longitude!.toDouble()).hash,
                geoPoint: GeoPoint(locationData.latitude!.toDouble(), locationData.longitude!.toDouble()));
            FireStoreUtils.updateCurrentUser(MyAppState.currentUser!);
          });
        }
      });
    }
  }

  DateTime pre_backpress = DateTime.now();
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final timegap = DateTime.now().difference(pre_backpress);
        final cantExit = timegap >= Duration(seconds: 2);
        pre_backpress = DateTime.now();
        if (cantExit) {
          //show snackbar
          final snack = SnackBar(
            content: Text(
              'Press Back button again to Exit'.tr(),
              style: TextStyle(color: Colors.white),
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.black,
          );
          ScaffoldMessenger.of(context).showSnackBar(snack);
          return false; // false will do nothing when back press
        } else {
          return true; // true will exit the app
        }
      },
      child: ChangeNotifierProvider.value(
        value: MyAppState.currentUser,
        child: Consumer<User>(
          builder: (context, user, _) {
            return Scaffold(
              drawer: Drawer(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          DrawerHeader(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                displayCircleImage(user.profilePictureURL, 75, false),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    user.fullName(),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      user.email,
                                      style: TextStyle(color: Colors.white),
                                    )),
                              ],
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                            ),
                          ),
                          ListTileTheme(
                            style: ListTileStyle.drawer,
                            selectedColor: Colors.purple,
                            child: ListTile(
                              selected: _drawerSelection == DrawerSelection.Home,
                              title: Text('Home').tr(),
                              onTap: () {
                                Navigator.pop(context);
                                setState(() {
                                  _drawerSelection = DrawerSelection.Home;
                                  _appBarTitle = 'Home'.tr();
                                  _currentWidget = ParcelHomeScreen(
                                    refresh: () {
                                      if (mounted) setState(() {});
                                    },
                                  );
                                });
                              },
                              leading: Icon(CupertinoIcons.home),
                            ),
                          ),
                          ListTileTheme(
                            style: ListTileStyle.drawer,
                            selectedColor: Colors.purple,
                            child: ListTile(
                              selected: _drawerSelection == DrawerSelection.Orders,
                              leading: Image.asset(
                                'assets/images/truck.png',
                                color: _drawerSelection == DrawerSelection.Orders
                                    ? Colors.purple
                                    : isDarkMode(context)
                                        ? Colors.grey.shade200
                                        : Colors.grey.shade600,
                                width: 24,
                                height: 24,
                              ),
                              title: Text('Parcel Orders').tr(),
                              onTap: () {
                                Navigator.pop(context);
                                setState(() {
                                  _drawerSelection = DrawerSelection.Orders;
                                  _appBarTitle = 'Parcel Orders'.tr();
                                  _currentWidget = ParcelOrderScreen();
                                });
                              },
                            ),
                          ),
                          ListTileTheme(
                            style: ListTileStyle.drawer,
                            selectedColor: Colors.purple,
                            child: ListTile(
                              selected: _drawerSelection == DrawerSelection.Wallet,
                              leading: Icon(Icons.account_balance_wallet_sharp),
                              title: Text('Wallet').tr(),
                              onTap: () {
                                Navigator.pop(context);
                                setState(() {
                                  _drawerSelection = DrawerSelection.Wallet;
                                  _appBarTitle = 'Earnings'.tr();
                                  _currentWidget = WalletScreen();
                                });
                              },
                            ),
                          ),
                          ListTileTheme(
                            style: ListTileStyle.drawer,
                            selectedColor: Colors.purple,
                            child: ListTile(
                              selected: _drawerSelection == DrawerSelection.BankInfo,
                              leading: Icon(Icons.account_balance),
                              title: Text('Bank Details').tr(),
                              onTap: () {
                                Navigator.pop(context);
                                setState(() {
                                  _drawerSelection = DrawerSelection.BankInfo;
                                  _appBarTitle = 'Bank Info'.tr();
                                  _currentWidget = BankDetailsScreen();
                                });
                              },
                            ),
                          ),
                          ListTileTheme(
                            style: ListTileStyle.drawer,
                            selectedColor: Colors.purple,
                            child: ListTile(
                              selected: _drawerSelection == DrawerSelection.Profile,
                              leading: Icon(CupertinoIcons.person),
                              title: Text('Profile').tr(),
                              onTap: () {
                                Navigator.pop(context);
                                setState(() {
                                  _drawerSelection = DrawerSelection.Profile;
                                  _appBarTitle = 'My Profile'.tr();
                                  _currentWidget = ProfileScreen(
                                    user: MyAppState.currentUser!,
                                  );
                                });
                              },
                            ),
                          ),
                          Visibility(
                            visible: isLanguageShown,
                            child: ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Colors.purple,
                              child: ListTile(
                                selected: _drawerSelection == DrawerSelection.chooseLanguage,
                                leading: Icon(
                                  Icons.language,
                                  color: _drawerSelection == DrawerSelection.chooseLanguage
                                      ? Colors.purple
                                      : isDarkMode(context)
                                          ? Colors.grey.shade200
                                          : Colors.grey.shade600,
                                ),
                                title: const Text('Language').tr(),
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _drawerSelection = DrawerSelection.chooseLanguage;
                                    _appBarTitle = 'Language'.tr();
                                    _currentWidget = LanguageChooseScreen(
                                      isContainer: true,
                                    );
                                  });
                                },
                              ),
                            ),
                          ),
                          ListTileTheme(
                            style: ListTileStyle.drawer,
                            selectedColor: Colors.purple,
                            child: ListTile(
                              selected: _drawerSelection == DrawerSelection.termsCondition,
                              leading: const Icon(Icons.policy),
                              title: const Text('Terms and Condition').tr(),
                              onTap: () async {
                                push(context, const TermsAndCondition());
                              },
                            ),
                          ),
                          ListTileTheme(
                            style: ListTileStyle.drawer,
                            selectedColor: Colors.purple,
                            child: ListTile(
                              selected: _drawerSelection == DrawerSelection.privacyPolicy,
                              leading: const Icon(Icons.privacy_tip),
                              title: const Text('Privacy policy').tr(),
                              onTap: () async {
                                push(context, const PrivacyPolicyScreen());
                              },
                            ),
                          ),
                          ListTileTheme(
                            style: ListTileStyle.drawer,
                            selectedColor: Colors.purple,
                            child: ListTile(
                              selected: _drawerSelection == DrawerSelection.Logout,
                              leading: Icon(Icons.logout),
                              title: Text('Log out').tr(),
                              onTap: () async {
                                Navigator.pop(context);
                                await FireStoreUtils.getCurrentUser(MyAppState.currentUser!.userID).then((value) {
                                  MyAppState.currentUser = value;
                                });
                                MyAppState.currentUser!.isActive = false;
                                MyAppState.currentUser!.lastOnlineTimestamp = Timestamp.now();
                                await FireStoreUtils.updateCurrentUser(MyAppState.currentUser!);
                                await auth.FirebaseAuth.instance.signOut();
                                MyAppState.currentUser = null;
                                location.enableBackgroundMode(enable: false);
                                pushAndRemoveUntil(context, AuthScreen(), false);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("V : $appVersion"),
                    )
                  ],
                ),
              ),
              appBar: AppBar(
                iconTheme: IconThemeData(
                  color: isDarkMode(context) ? Colors.white : Color(DARK_COLOR),
                ),
                centerTitle: _drawerSelection == DrawerSelection.Wallet ? true : false,
                backgroundColor: isDarkMode(context) ? Color(DARK_COLOR) : Colors.white,
                actions: [
                  if (_currentWidget is ParcelHomeScreen &&
                      MyAppState.currentUser!.isActive &&
                      MyAppState.currentUser!.orderParcelRequestData == null &&
                      MyAppState.currentUser!.inProgressOrderID == null)
                    IconButton(
                        icon: Icon(
                          CupertinoIcons.power,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          MyAppState.currentUser!.isActive = false;
                          setState(() {});
                          await FireStoreUtils.updateCurrentUser(MyAppState.currentUser!);
                        }),
                ],
                title: Text(
                  _appBarTitle,
                  style: TextStyle(
                    color: isDarkMode(context) ? Colors.white : Colors.black,
                  ),
                ),
              ),
              body: _currentWidget,
            );
          },
        ),
      ),
    );
  }

  curcy(CurrencyModel currency) {
    if (currency.isactive == true) {
      symbol = currency.symbol;
      isRight = currency.symbolatright;
      decimal = currency.decimal;
      return Center();
    }
    return Center();
  }

  Future<void> getLanguages() async {
    await FireStoreUtils.firestore.collection(Setting).doc("languages").get().then((value) {
      if (value != null) {
        List list = value.data()!["list"];
        isLanguageShown = (list.length > 0);
        setState(() {});
      }
    });
  }
}
