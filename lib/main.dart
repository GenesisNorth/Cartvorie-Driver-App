import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartdriver/CabService/dashboard_cab_service.dart';
import 'package:emartdriver/Parcel_service/parcel_service_dashboard.dart';
import 'package:emartdriver/constants.dart';
import 'package:emartdriver/model/ConversationModel.dart';
import 'package:emartdriver/model/HomeConversationModel.dart';
import 'package:emartdriver/rental_service/rental_service_dashboard.dart';
import 'package:emartdriver/services/FirebaseHelper.dart';
import 'package:emartdriver/services/helper.dart';
import 'package:emartdriver/ui/auth/AuthScreen.dart';
import 'package:emartdriver/ui/chat/ChatScreen.dart';
import 'package:emartdriver/ui/container/ContainerScreen.dart';
import 'package:emartdriver/ui/onBoarding/OnBoardingScreen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/User.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  SharedPreferences sp = await SharedPreferences.getInstance();

  await Firebase.initializeApp();

  runApp(
    EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: sp.getString('languageCode') != null ? Locale(sp.getString('languageCode')!) : Locale('en'),
        saveLocale: true,
        useOnlyLangCode: true,
        useFallbackTranslations: true,
        child: MyApp()),
  );
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  /// this key is used to navigate to the appropriate screen when the
  /// notification is clicked from the system tray
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey(debugLabel: 'Main Navigator');

  static User? currentUser;

  // Set default `_initialized` and `_error` state to false
  bool _initialized = false, isColorLoad = false;
  bool _error = false;

  // Define an async function to initialize FlutterFire
  void initializeFlutterFire() async {
    try {
      // Wait for Firebase to initialize and set `_initialized` state to true

      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotification(initialMessage.data, navigatorKey);
      }
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? remoteMessage) {
        if (remoteMessage != null) {
          _handleNotification(remoteMessage.data, navigatorKey);
        }
      });

      /// configure the firebase messaging , required for notifications handling
      if (!Platform.isIOS) {
        FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);
      }

      FirebaseFirestore.instance.collection(Setting).doc("globalSettings").get().then((dineinresult) {
        if (dineinresult != null && dineinresult.exists && dineinresult.data() != null && dineinresult.data()!.containsKey("website_color")) {
          COLOR_PRIMARY = int.parse(dineinresult.data()!["website_color"].replaceFirst("#", "0xff"));
        }
        setState(() {
          isColorLoad = true;
        });
      });

      await FirebaseFirestore.instance.collection(Setting).doc("Version").get().then((value) {
        print(value.data());
        appVersion = value.data()!['app_version'].toString();
      });

      /// listen to firebase token changes and update the user object in the
      /// database with it's new toke

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      // Set `_error` state to true if Firebase initialization fails
      setState(() {
        _error = true;
      });
    }
  }

  setUpToken() async {
    if (MyAppState.currentUser != null) {
      await FireStoreUtils.firebaseMessaging.getToken().then((value) {
        MyAppState.currentUser!.fcmToken = value!;
        FireStoreUtils.updateCurrentUser(currentUser!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error message if initialization failed
    if (_error) {
      return MaterialApp(
          home: Scaffold(
        body: Container(
          color: Colors.white,
          child: Center(
              child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 25,
              ),
              SizedBox(height: 16),
              Text(
                'Failed to initialise firebase!'.tr(),
                style: TextStyle(color: Colors.red, fontSize: 25),
              ),
            ],
          )),
        ),
      ));
    }

    print("side call");
    // Show a loader until FlutterFire is initialized
    if (!_initialized || !isColorLoad) {
      return Container(
        color: Colors.white,
        child: Center(
          child: CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation(
              Colors.purple,
            ),
          ),
        ),
      );
    }

    print("MAin call");
    return MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        title: 'Cartvorie Driver'.tr(),
        theme: ThemeData(
            appBarTheme: AppBarTheme(
                centerTitle: true,
                color: Colors.transparent,
                elevation: 0,
                actionsIconTheme: IconThemeData(color: Colors.purple),
                iconTheme: IconThemeData(color: Colors.purple),
                systemOverlayStyle: SystemUiOverlayStyle.dark,
                toolbarTextStyle: TextTheme(headline6: TextStyle(color: Colors.black, fontSize: 17.0, letterSpacing: 0, fontWeight: FontWeight.w700)).bodyText2,
                titleTextStyle: TextTheme(headline6: TextStyle(color: Colors.black, fontSize: 17.0, letterSpacing: 0, fontWeight: FontWeight.w700)).headline6),
            bottomSheetTheme: BottomSheetThemeData(backgroundColor: Colors.white),
            primaryColor: Colors.purple,
            brightness: Brightness.light),
        darkTheme: ThemeData(
            appBarTheme: AppBarTheme(
                centerTitle: true,
                color: Colors.transparent,
                elevation: 0,
                actionsIconTheme: IconThemeData(color: Colors.purple),
                iconTheme: IconThemeData(color: Colors.purple),
                toolbarTextStyle: TextTheme(headline6: TextStyle(color: Colors.grey[200], fontSize: 17.0, letterSpacing: 0, fontWeight: FontWeight.w700)).bodyText2,
                titleTextStyle: TextTheme(headline6: TextStyle(color: Colors.grey[200], fontSize: 17.0, letterSpacing: 0, fontWeight: FontWeight.w700)).headline6,
                systemOverlayStyle: SystemUiOverlayStyle.light),
            bottomSheetTheme: BottomSheetThemeData(backgroundColor: Colors.grey.shade900),
            primaryColor: Colors.purple,
            brightness: Brightness.dark),
        debugShowCheckedModeBanner: false,
        color: Colors.purple,
        home: OnBoarding());
  }

  @override
  void initState() {
    initializeFlutterFire();
    WidgetsBinding.instance.addObserver(this);
    setUpToken();
    FireStoreUtils().getDriverOrderSetting();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (auth.FirebaseAuth.instance.currentUser != null && currentUser != null) {
      await FireStoreUtils.getCurrentUser(MyAppState.currentUser!.userID).then((value) {
        MyAppState.currentUser = value;
        if (state == AppLifecycleState.paused) {
          //user offline
          MyAppState.currentUser!.lastOnlineTimestamp = Timestamp.now();
          if (MyAppState.currentUser!.inProgressOrderID != null) {
            MyAppState.currentUser!.isActive = false;
          } else {
            MyAppState.currentUser!.isActive = MyAppState.currentUser!.isActive == true ? false : true;
          }
          FireStoreUtils.updateCurrentUser(MyAppState.currentUser!);
        } else if (state == AppLifecycleState.resumed) {
          //user online
          if (MyAppState.currentUser!.inProgressOrderID != null) {
            MyAppState.currentUser!.isActive = false;
          } else {
            MyAppState.currentUser!.isActive = MyAppState.currentUser!.isActive == false ? true : false;
          }
          FireStoreUtils.updateCurrentUser(MyAppState.currentUser!);
        }
      });
    }
  }
}

class OnBoarding extends StatefulWidget {
  @override
  State createState() {
    return OnBoardingState();
  }
}

class OnBoardingState extends State<OnBoarding> {
  Future hasFinishedOnBoarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool finishedOnBoarding = (prefs.getBool(FINISHED_ON_BOARDING) ?? false);

    if (finishedOnBoarding) {
      auth.User? firebaseUser = auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        User? user = await FireStoreUtils.getCurrentUser(firebaseUser.uid);
        if (user != null && user.role == USER_ROLE_DRIVER) {
          if (user.active) {
            user.isActive = true;
            user.role = USER_ROLE_DRIVER;
            user.fcmToken = await FireStoreUtils.firebaseMessaging.getToken() ?? '';
            await FireStoreUtils.updateCurrentUser(user);
            MyAppState.currentUser = user;
            if (user.serviceType == "cab-service") {
              pushAndRemoveUntil(
                  context,
                  DashBoardCabService(
                    user: user,
                  ),
                  false);
            } else if (user.serviceType == "parcel_delivery") {
              pushAndRemoveUntil(context, ParcelServiceDashBoard(user: user), false);
            } else if (user.serviceType == "rental-service") {
              pushAndRemoveUntil(context, RentalServiceDashBoard(user: user), false);
            } else {
              pushAndRemoveUntil(context, ContainerScreen(user: user), false);
            }
          } else {
            user.isActive = false;
            user.lastOnlineTimestamp = Timestamp.now();
            await FireStoreUtils.updateCurrentUser(user);
            await auth.FirebaseAuth.instance.signOut();
            MyAppState.currentUser = null;
            pushAndRemoveUntil(context, AuthScreen(), false);
          }
        } else {
          pushReplacement(context, AuthScreen());
        }
      } else {
        pushReplacement(context, AuthScreen());
      }
    } else {
      pushReplacement(context, OnBoardingScreen());
    }
  }

  @override
  void initState() {
    super.initState();
    hasFinishedOnBoarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation(
            Colors.purple,
          ),
        ),
      ),
    );
  }
}

/// this faction is called when the notification is clicked from system tray
/// when the app is in the background or completely killed
void _handleNotification(Map<String, dynamic> message, GlobalKey<NavigatorState> navigatorKey) {
  /// right now we only handle click actions on chat messages only
  try {
    if (message.containsKey('members') && message.containsKey('isGroup') && message.containsKey('conversationModel')) {
      List<User> members = List<User>.from((jsonDecode(message['members']) as List<dynamic>).map((e) => User.fromPayload(e))).toList();
      ConversationModel conversationModel = ConversationModel.fromPayload(jsonDecode(message['conversationModel']));
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            homeConversationModel: HomeConversationModel(members: members, conversationModel: conversationModel),
          ),
        ),
      );
    }
  } catch (e, s) {
    print('MyAppState._handleNotification $e $s');
  }
}

Future<dynamic> backgroundMessageHandler(RemoteMessage remoteMessage) async {
  Map<dynamic, dynamic> message = remoteMessage.data;
  if (message.containsKey('data')) {
    // Handle data message
    print('backgroundMessageHandler message.containsKey(data)');
  }

  if (message.containsKey('notification')) {
    // Handle notification message
  }
}
