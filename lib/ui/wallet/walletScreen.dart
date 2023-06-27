import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartdriver/Parcel_service/parcel_order_model.dart';
import 'package:emartdriver/model/CabOrderModel.dart';
import 'package:emartdriver/model/OrderModel.dart';
import 'package:emartdriver/model/withdrawHistoryModel.dart';
import 'package:emartdriver/rental_service/model/rental_order_model.dart';
import 'package:emartdriver/services/FirebaseHelper.dart';
import 'package:emartdriver/services/helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../main.dart';
import '../../model/User.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;
  Stream<QuerySnapshot>? withdrawalHistoryQuery;
  Stream<QuerySnapshot>? dailyEarningQuery;
  Stream<QuerySnapshot>? monthlyEarningQuery;
  Stream<QuerySnapshot>? yearlyEarningQuery;

  Stream<DocumentSnapshot<Map<String, dynamic>>>? userQuery;

  String? selectedRadioTile;

  GlobalKey<FormState> _globalKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController _amountController = TextEditingController(text: 50.toString());
  TextEditingController _noteController = TextEditingController(text: '');

  getData() async {
    try {
      userQuery = fireStore.collection(USERS).doc(userId).snapshots();
      print(userQuery!.isEmpty);
    } catch (e) {
      print(e);
    }

    /// withdrawal History
    withdrawalHistoryQuery = fireStore.collection(driverPayouts).where('driverID', isEqualTo: userId).orderBy('paidDate', descending: true).snapshots();

    DateTime nowDate = DateTime.now();

    if (MyAppState.currentUser!.serviceType == "cab-service") {
      ///earnings History
      if (MyAppState.currentUser!.isCompany == true) {
        dailyEarningQuery = fireStore
            .collection(RIDESORDER)
            .where('companyID', isEqualTo: driverId)
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(nowDate.year, nowDate.month, nowDate.day)))
            .orderBy('createdAt', descending: true)
            .snapshots();

        monthlyEarningQuery = fireStore
            .collection(RIDESORDER)
            .where('companyID', isEqualTo: driverId)
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                  nowDate.year,
                  nowDate.month,
                )))
            .orderBy('createdAt', descending: true)
            .snapshots();

        yearlyEarningQuery = fireStore
            .collection(RIDESORDER)
            .where('companyID', isEqualTo: driverId)
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                  nowDate.year,
                )))
            .orderBy('createdAt', descending: true)
            .snapshots();
      } else {
        dailyEarningQuery = fireStore
            .collection(RIDESORDER)
            .where('driverID', isEqualTo: driverId)
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(nowDate.year, nowDate.month, nowDate.day)))
            .orderBy('createdAt', descending: true)
            .snapshots();

        monthlyEarningQuery = fireStore
            .collection(RIDESORDER)
            .where('driverID', isEqualTo: driverId)
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                  nowDate.year,
                  nowDate.month,
                )))
            .orderBy('createdAt', descending: true)
            .snapshots();

        yearlyEarningQuery = fireStore
            .collection(RIDESORDER)
            .where('driverID', isEqualTo: driverId)
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                  nowDate.year,
                )))
            .orderBy('createdAt', descending: true)
            .snapshots();
      }
    } else if (MyAppState.currentUser!.serviceType == "parcel_delivery") {
      ///earnings History
      dailyEarningQuery = fireStore
          .collection(PARCELORDER)
          .where('driverID', isEqualTo: driverId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(nowDate.year, nowDate.month, nowDate.day)))
          .orderBy('createdAt', descending: true)
          .snapshots();

      monthlyEarningQuery = fireStore
          .collection(PARCELORDER)
          .where('driverID', isEqualTo: driverId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                nowDate.year,
                nowDate.month,
              )))
          .orderBy('createdAt', descending: true)
          .snapshots();

      yearlyEarningQuery = fireStore
          .collection(PARCELORDER)
          .where('driverID', isEqualTo: driverId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                nowDate.year,
              )))
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else if (MyAppState.currentUser!.serviceType == "rental-service") {
      ///earnings History
      if (MyAppState.currentUser!.isCompany == true) {
        dailyEarningQuery = fireStore
            .collection(RENTALORDER)
            .where('companyID', isEqualTo: driverId)
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(nowDate.year, nowDate.month, nowDate.day)))
            .orderBy('createdAt', descending: true)
            .snapshots();

        monthlyEarningQuery = fireStore
            .collection(RENTALORDER)
            .where('companyID', isEqualTo: driverId)
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                  nowDate.year,
                  nowDate.month,
                )))
            .orderBy('createdAt', descending: true)
            .snapshots();

        yearlyEarningQuery = fireStore
            .collection(RENTALORDER)
            .where('companyID', isEqualTo: driverId)
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                  nowDate.year,
                )))
            .orderBy('createdAt', descending: true)
            .snapshots();
      } else {
        dailyEarningQuery = fireStore
            .collection(RENTALORDER)
            .where('driverID', isEqualTo: driverId)
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(nowDate.year, nowDate.month, nowDate.day)))
            .orderBy('createdAt', descending: true)
            .snapshots();

        monthlyEarningQuery = fireStore
            .collection(RENTALORDER)
            .where('driverID', isEqualTo: driverId)
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                  nowDate.year,
                  nowDate.month,
                )))
            .orderBy('createdAt', descending: true)
            .snapshots();

        yearlyEarningQuery = fireStore
            .collection(RENTALORDER)
            .where('driverID', isEqualTo: driverId)
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                  nowDate.year,
                )))
            .orderBy('createdAt', descending: true)
            .snapshots();
      }
    } else {
      ///earnings History
      dailyEarningQuery = fireStore
          .collection(ORDERS)
          .where('driverID', isEqualTo: driverId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(nowDate.year, nowDate.month, nowDate.day)))
          .orderBy('createdAt', descending: true)
          .snapshots();

      monthlyEarningQuery = fireStore
          .collection(ORDERS)
          .where('driverID', isEqualTo: driverId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                nowDate.year,
                nowDate.month,
              )))
          .orderBy('createdAt', descending: true)
          .snapshots();

      yearlyEarningQuery = fireStore
          .collection(ORDERS)
          .where('driverID', isEqualTo: driverId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                nowDate.year,
              )))
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  Map<String, dynamic>? paymentIntentData;

  showAlert(context, {required String response, required Color colors}) {
    return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(response),
      backgroundColor: colors,
      duration: Duration(seconds: 8),
    ));
  }

  final userId = MyAppState.currentUser!.userID;
  final driverId = MyAppState.currentUser!.userID; //'8BBDG88lB4dqRaCcLIhdonuwQtU2';
  UserBankDetails? userBankDetail = MyAppState.currentUser!.userBankDetails;

  @override
  void initState() {
    print("here demo");
    print(MyAppState.currentUser!.lastOnlineTimestamp.toDate());

    print(MyAppState.currentUser!.lastOnlineTimestamp.toDate().toString().contains(DateTime.now().year.toString()));

    getData();
    print(MyAppState.currentUser!.userID);
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        color: Colors.black.withOpacity(0.03),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12),
              child: Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(22), image: DecorationImage(fit: BoxFit.fitWidth, image: AssetImage("assets/images/earning_bg_@3x.png"))),
                width: size.width * 0.9,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 40,
                    ),
                    Text(
                      "Total Balance".tr(),
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 25.0),
                      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: userQuery,
                        builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> asyncSnapshot) {
                          if (asyncSnapshot.hasError) {
                            return Text(
                              "error".tr(),
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30),
                            );
                          }
                          if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                                child: SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 0.8,
                                      color: Colors.white,
                                      backgroundColor: Colors.transparent,
                                    )));
                          }
                          User userData = User.fromJson(asyncSnapshot.data!.data()!);
                          return Text(
                            "$symbol ${userData.walletAmount.toStringAsFixed(decimal)}",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 35),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            tabController(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 5),
        child: MyAppState.currentUser!.serviceType == "rental-service" || MyAppState.currentUser!.serviceType == "cab-service"
            ? MyAppState.currentUser!.isCompany == false && MyAppState.currentUser!.companyId.isNotEmpty
                ? SizedBox()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildButton(context, width: 0.32, title: 'WITHDRAW'.tr(), onPress: () {
                        if (MyAppState.currentUser!.userBankDetails.accountNumber.isNotEmpty) {
                          withdrawAmountBottomSheet(context);
                        } else {
                          final snackBar = SnackBar(
                            backgroundColor: Colors.red[400],
                            content: Text(
                              'Please add your Bank Details first'.tr(),
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        }
                      }),
                      buildTransButton(context, width: 0.55, title: 'WITHDRAWAL HISTORY'.tr(), onPress: () {
                        if (MyAppState.currentUser!.userBankDetails.accountNumber.isNotEmpty) {
                          withdrawalHistoryBottomSheet(context);
                        } else {
                          final snackBar = SnackBar(
                            backgroundColor: Colors.red[400],
                            content: Text(
                              'Please add your Bank Details first'.tr(),
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        }
                      }),
                    ],
                  )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildButton(context, width: 0.32, title: 'WITHDRAW'.tr(), onPress: () {
                    if (MyAppState.currentUser!.userBankDetails.accountNumber.isNotEmpty) {
                      withdrawAmountBottomSheet(context);
                    } else {
                      final snackBar = SnackBar(
                        backgroundColor: Colors.red[400],
                        content: Text(
                          'Please add your Bank Details first'.tr(),
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    }
                  }),
                  buildTransButton(context, width: 0.55, title: 'WITHDRAWAL HISTORY'.tr(), onPress: () {
                    if (MyAppState.currentUser!.userBankDetails.accountNumber.isNotEmpty) {
                      withdrawalHistoryBottomSheet(context);
                    } else {
                      final snackBar = SnackBar(
                        backgroundColor: Colors.red[400],
                        content: Text(
                          'Please add your Bank Details first'.tr(),
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    }
                  }),
                ],
              ),
      ),
    );
  }

  tabController() {
    return Expanded(
      child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Container(
                  height: 40,
                  child: TabBar(
                    //indicator: BoxDecoration(color: const Colors.purple, borderRadius: BorderRadius.circular(2.0)),
                    indicatorColor: Colors.purple,
                    labelColor: Colors.purple,
                    automaticIndicatorColorAdjustment: true,
                    dragStartBehavior: DragStartBehavior.start,
                    unselectedLabelColor: isDarkMode(context) ? Colors.white70 : Colors.black54,
                    indicatorWeight: 1.5,
                    //indicatorPadding: EdgeInsets.symmetric(horizontal: 10),
                    enableFeedback: true,
                    //unselectedLabelColor: const Colors,
                    tabs: [
                      Tab(text: 'Daily'.tr()),
                      Tab(
                        text: 'Monthly'.tr(),
                      ),
                      Tab(
                        text: 'Yearly'.tr(),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: TabBarView(
                    children: [
                      showEarningsHistory(context, query: dailyEarningQuery),
                      showEarningsHistory(context, query: monthlyEarningQuery),
                      showEarningsHistory(context, query: yearlyEarningQuery),
                    ],
                  ),
                ),
              )
            ],
          )),
    );
  }

  Widget showEarningsHistory(BuildContext context, {required Stream<QuerySnapshot>? query}) {
    return StreamBuilder<QuerySnapshot>(
      stream: query,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'.tr()));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: SizedBox(height: 35, width: 35, child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          return ListView(
            shrinkWrap: true,
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              final earningData;
              print("-------->" + MyAppState.currentUser!.serviceType);
              if (MyAppState.currentUser!.serviceType == "cab-service") {
                earningData = CabOrderModel.fromJson(document.data() as Map<String, dynamic>);
              } else if (MyAppState.currentUser!.serviceType == "parcel_delivery") {
                earningData = ParcelOrderModel.fromJson(document.data() as Map<String, dynamic>);
              } else if (MyAppState.currentUser!.serviceType == "rental-service") {
                earningData = RentalOrderModel.fromJson(document.data() as Map<String, dynamic>);
              } else {
                earningData = OrderModel.fromJson(document.data() as Map<String, dynamic>);
              }
              return buildEarningCard(
                orderModel: earningData,
              );
            }).toList(),
          );
        } else {
          return Center(
              child: Text(
            "No Transaction History".tr(),
            style: TextStyle(fontSize: 18),
          ));
        }
      },
    );
  }

  Widget buildEarningCard({required var orderModel}) {
    final size = MediaQuery.of(context).size;
    double amount = 0;
    if (MyAppState.currentUser!.serviceType == "cab-service") {
      double totalTax = 0.0;

      if (orderModel.taxType!.isNotEmpty) {
        if (orderModel.taxType == "percent") {
          totalTax = (double.parse(orderModel.subTotal.toString()) - double.parse(orderModel.discount.toString())) * double.parse(orderModel.tax.toString()) / 100;
        } else {
          totalTax = double.parse(orderModel.tax.toString());
        }
      }

      double subTotal = double.parse(orderModel.subTotal.toString()) - double.parse(orderModel.discount.toString());
      double adminComm = 0.0;
      if (orderModel.adminCommission!.isNotEmpty) {
        adminComm = (orderModel.adminCommissionType == 'Percent') ? (subTotal * double.parse(orderModel.adminCommission!)) / 100 : double.parse(orderModel.adminCommission!);
      }

      print("--->finalAmount---- $subTotal");
      double tipValue = orderModel.tipValue!.isEmpty ? 0.0 : double.parse(orderModel.tipValue.toString());
      if (orderModel.payment_method.toLowerCase() != "cod") {
        amount = subTotal + totalTax + tipValue + adminComm;
      } else {
        amount = -(subTotal + totalTax + tipValue + adminComm);
      }
    } else if (MyAppState.currentUser!.serviceType == "parcel_delivery") {
      double totalTax = 0.0;

      if (orderModel.taxType!.isNotEmpty) {
        if (orderModel.taxType == "percent") {
          totalTax = (double.parse(orderModel.subTotal.toString()) - double.parse(orderModel.discount.toString())) * double.parse(orderModel.tax.toString()) / 100;
        } else {
          totalTax = double.parse(orderModel.tax.toString());
        }
      }

      double subTotal = double.parse(orderModel.subTotal.toString()) - double.parse(orderModel.discount.toString());
      double adminComm = 0.0;
      if (orderModel.adminCommission!.isNotEmpty) {
        adminComm = (orderModel.adminCommissionType == 'Percent') ? (subTotal * double.parse(orderModel.adminCommission!)) / 100 : double.parse(orderModel.adminCommission!);
      }

      print("--->finalAmount---- $subTotal");
      if (orderModel.paymentMethod.toLowerCase() != "cod") {
        amount = subTotal + totalTax + adminComm;
      } else {
        amount = -(subTotal + totalTax + adminComm);
      }
    } else if (MyAppState.currentUser!.serviceType == "rental-service") {
      double totalTax = 0.0;
      double subTotal = (double.parse(orderModel.subTotal.toString()) + double.parse(orderModel.driverRate.toString())) - double.parse(orderModel.discount.toString());

      if (orderModel.taxType!.isNotEmpty) {
        if (orderModel.taxType == "percent") {
          totalTax = subTotal * double.parse(orderModel.tax.toString()) / 100;
        } else {
          totalTax = double.parse(orderModel.tax.toString());
        }
      }

      double adminComm = 0.0;
      if (orderModel.adminCommission!.isNotEmpty) {
        adminComm = (orderModel.adminCommissionType == 'Percent')
            ? (double.parse(orderModel.subTotal.toString()) + double.parse(orderModel.driverRate.toString()) * double.parse(orderModel.adminCommission!)) / 100
            : double.parse(orderModel.adminCommission!);
      }


      if (orderModel.paymentMethod.toLowerCase() != "cod") {
        amount = subTotal + totalTax  + adminComm;
      } else {
        amount = -(subTotal + totalTax  + adminComm);
      }

    } else {
      print("delv charge ${orderModel.deliveryCharge}");
      if (orderModel.deliveryCharge != null && orderModel.deliveryCharge!.isNotEmpty) {
        amount += double.parse(orderModel.deliveryCharge!);
      }

      if (orderModel.tipValue != null && orderModel.tipValue!.isNotEmpty) {
        amount += double.parse(orderModel.tipValue!);
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: size.width * 0.52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${DateFormat('dd-MM-yyyy, KK:mma').format(orderModel.createdAt.toDate()).toUpperCase()}",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Opacity(
                      opacity: 0.75,
                      child: Text(
                        orderModel.status,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 17,
                          color: orderModel.status == "Order Completed" ? Colors.green : Colors.deepOrangeAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 3.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      " $symbol${amount.toStringAsFixed(decimal)}",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: orderModel.status == "Order Completed"
                            ? amount < 0
                                ? Colors.red
                                : Colors.green
                            : Colors.deepOrange,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    // Icon(
                    //   Icons.arrow_forward_ios,
                    //   size: 15,
                    // )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget showWithdrawalHistory(BuildContext context, {required Stream<QuerySnapshot>? query}) {
    return StreamBuilder<QuerySnapshot>(
      stream: query,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'.tr()));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: SizedBox(height: 35, width: 35, child: CircularProgressIndicator()));
        }
        if (snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text(
            "No Transaction History".tr(),
            style: TextStyle(fontSize: 18),
          ));
        } else {
          return ListView(
            shrinkWrap: true,
            physics: BouncingScrollPhysics(),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              final topUpData = WithdrawHistoryModel.fromJson(document.data() as Map<String, dynamic>);
              //Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              return buildTransactionCard(
                withdrawHistory: topUpData,
                date: topUpData.paidDate.toDate(),
              );
            }).toList(),
          );
        }
      },
    );
  }

  Widget buildTransactionCard({
    required WithdrawHistoryModel withdrawHistory,
    required DateTime date,
  }) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3),
      child: GestureDetector(
        onTap: () => showWithdrawalModelSheet(context, withdrawHistory),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipOval(
                  child: Container(
                    color: Colors.green.withOpacity(0.06),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Icon(Icons.account_balance_wallet_rounded, size: 28, color: Color(0xff8e24aa)),
                    ),
                  ),
                ),
                SizedBox(
                  width: size.width * 0.75,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: SizedBox(
                          width: size.width * 0.52,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${DateFormat('MMM dd, yyyy, KK:mma').format(withdrawHistory.paidDate.toDate()).toUpperCase()}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17,
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Opacity(
                                opacity: 0.75,
                                child: Text(
                                  withdrawHistory.paymentStatus,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 17,
                                    color: withdrawHistory.paymentStatus == "Success" ? Colors.green : Colors.deepOrangeAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 3.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              " $symbol${double.parse(withdrawHistory.amount.toString()).toStringAsFixed(decimal)}",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: withdrawHistory.paymentStatus == "Success" ? Colors.green : Colors.deepOrangeAccent,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 15,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  withdrawAmountBottomSheet(BuildContext context) {
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        ),
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 5),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 25.0, bottom: 10),
                      child: Text(
                        "Withdraw".tr(),
                        style: TextStyle(
                          fontSize: 18,
                          color: isDarkMode(context) ? Colors.white : Color(DARK_COLOR),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 25),
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: Color(COLOR_ACCENt1), width: 4)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    userBankDetail!.bankName,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(COLOR_PRIMARY_DARK),
                                    ),
                                  ),
                                  Icon(
                                    Icons.account_balance,
                                    size: 40,
                                    color: Color(COLOR_ACCENt1),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 2,
                              ),
                              Text(
                                userBankDetail!.accountNumber,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode(context) ? Colors.white.withOpacity(0.9) : Color(DARK_COLOR).withOpacity(0.9),
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                userBankDetail!.holderName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode(context) ? Colors.white.withOpacity(0.7) : Color(DARK_COLOR).withOpacity(0.7),
                                ),
                              ),
                              SizedBox(
                                height: 4,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    userBankDetail!.otherDetails,
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: isDarkMode(context) ? Colors.white.withOpacity(0.9) : Color(DARK_COLOR).withOpacity(0.9),
                                    ),
                                  ),
                                  Text(
                                    userBankDetail!.branchName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: isDarkMode(context) ? Colors.white.withOpacity(0.7) : Color(DARK_COLOR).withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
                          child: RichText(
                            text: TextSpan(
                              text: "Amount to Withdraw".tr(),
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode(context) ? Colors.white70 : Color(DARK_COLOR).withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Form(
                      key: _globalKey,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 2),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 8),
                          child: TextFormField(
                            controller: _amountController,
                            style: TextStyle(
                              color: Color(COLOR_PRIMARY_DARK),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                            //initialValue:"50",
                            maxLines: 1,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "*required Field".tr();
                              } else {
                                if (double.parse(value) <= 0) {
                                  return "*Invalid Amount".tr();
                                } else if (double.parse(value) > double.parse(MyAppState.currentUser!.walletAmount.toString())) {
                                  return "*withdraw is more then wallet balance".tr();
                                } else {
                                  return null;
                                }
                              }
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              prefix: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2),
                                child: Text(
                                  "$symbol",
                                  style: TextStyle(
                                    color: isDarkMode(context) ? Colors.white : Color(DARK_COLOR),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              fillColor: Colors.grey[200],
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0), borderSide: BorderSide(color: Colors.purple, width: 1.50)),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Theme.of(context).errorColor),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Theme.of(context).errorColor),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                      child: TextFormField(
                        controller: _noteController,
                        style: TextStyle(
                          color: Color(COLOR_PRIMARY_DARK),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        //initialValue:"50",
                        maxLines: 1,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "*required Field".tr();
                          }
                          return null;
                        },
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintText: 'Add note'.tr(),
                          fillColor: Colors.grey[200],
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0), borderSide: BorderSide(color: Colors.purple, width: 1.50)),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).errorColor),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).errorColor),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: buildButton(context, title: "WITHDRAW".tr(), onPress: () {
                        if (_globalKey.currentState!.validate()) {
                          withdrawRequest();
                        }
                      }),
                    ),
                  ],
                ),
              ),
            );
          });
        });
  }

  withdrawRequest() {
    Navigator.pop(context);
    showLoadingAlert();
    FireStoreUtils.createPaymentId(collectionName: driverPayouts).then((value) {
      final paymentID = value;

      WithdrawHistoryModel withdrawHistory = WithdrawHistoryModel(
        amount: double.parse(_amountController.text),
        driverID: userId,
        paymentStatus: "Pending".tr(),
        paidDate: Timestamp.now(),
        id: paymentID.toString(),
        note: _noteController.text,
      );

      print(withdrawHistory.driverID);

      FireStoreUtils.withdrawWalletAmount(withdrawHistory: withdrawHistory).then((value) {
        FireStoreUtils.updateCurrentUserWallet(userId: userId, amount: -double.parse(_amountController.text)).whenComplete(() {
          Navigator.pop(_scaffoldKey.currentContext!);
          ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(SnackBar(
            content: Text("Payment Successful!! \n".tr()),
            backgroundColor: Colors.green,
          ));
        });
      });
    });
  }

  withdrawalHistoryBottomSheet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        ),
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Container(
              height: size.height,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 80.0),
                    child: showWithdrawalHistory(context, query: withdrawalHistoryQuery),
                  ),
                  Positioned(
                    top: 40,
                    left: 15,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios,
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
        });
  }

  buildButton(context, {required String title, double width = 0.9, required Function()? onPress}) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * width,
      child: MaterialButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        color: Color(0xff8e24aa),
        height: 45,
        elevation: 0.0,
        onPressed: onPress,
        child: Text(
          title,
          style: TextStyle(fontSize: 15, color: Colors.white),
        ),
      ),
    );
  }

  buildTransButton(context, {required String title, double width = 0.9, required Function()? onPress}) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * width,
      child: MaterialButton(
        shape: RoundedRectangleBorder(side: BorderSide(color: Color(0xff8e24aa), width: 1), borderRadius: BorderRadius.circular(6)),
        color: Colors.transparent,
        height: 45,
        elevation: 0.0,
        onPressed: onPress,
        child: Text(
          title,
          style: TextStyle(fontSize: 15, color: Color(0xff8e24aa)),
        ),
      ),
    );
  }

  showLoadingAlert() {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CircularProgressIndicator(),
              Text('Please wait!!'.tr()),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                SizedBox(
                  height: 15,
                ),
                Text(
                  'Please wait!! while completing Transaction'.tr(),
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(
                  height: 15,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
