import 'package:easy_localization/easy_localization.dart';
import 'package:emartdriver/Parcel_service/parcel_order_detail_screen.dart';
import 'package:emartdriver/Parcel_service/parcel_order_model.dart';
import 'package:emartdriver/constants.dart';
import 'package:emartdriver/main.dart';
import 'package:emartdriver/services/FirebaseHelper.dart';
import 'package:emartdriver/services/helper.dart';
import 'package:flutter/material.dart';

class ParcelOrderScreen extends StatefulWidget {
  const ParcelOrderScreen({Key? key}) : super(key: key);

  @override
  State<ParcelOrderScreen> createState() => _ParcelOrderScreenState();
}

class _ParcelOrderScreenState extends State<ParcelOrderScreen> {
  late Future<List<ParcelOrderModel>> ordersFuture;
  FireStoreUtils _fireStoreUtils = FireStoreUtils();
  List<ParcelOrderModel> ordersList = [];

  @override
  void initState() {
    super.initState();
    ordersFuture = _fireStoreUtils.getParcelDriverOrders(MyAppState.currentUser!.userID);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<ParcelOrderModel>>(
          future: ordersFuture,
          initialData: [],
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return Container(
                child: Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(
                      Colors.purple,
                    ),
                  ),
                ),
              );
            if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
              return Center(
                child: showEmptyState('No Previous Orders'.tr(), description: "Let's deliver food!".tr()),
              );
            } else {
              ordersList = snapshot.data!;
              return ListView.builder(itemCount: ordersList.length, itemBuilder: (context, index) => buildHistory(ordersList[index]));
            }
          }),
    );
  }

  buildHistory(ParcelOrderModel orderModel) {
    return GestureDetector(
      onTap: () {
        push(context, ParcelOrderDetailScreen(orderModel: orderModel));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildLine(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          buildUsersDetails(context, isSender: true, userDetails: orderModel.sender),
                          const SizedBox(
                            height: 20,
                          ),
                          buildUsersDetails(context, isSender: false, userDetails: orderModel.receiver),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(
                  color: Colors.black12,
                  thickness: 1,
                ),
                const SizedBox(
                  height: 5,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text("Parcel Type : ", style: const TextStyle(color: Colors.grey)),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(orderModel.parcelType.toString(), style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                const Divider(
                  color: Colors.black12,
                  thickness: 1,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildOtherDetails(
                      title: "Order Status",
                      value: orderModel.status == ORDER_STATUS_PLACED
                          ? "Order Placed"
                          : orderModel.status == ORDER_STATUS_DRIVER_REJECTED || orderModel.status == ORDER_STATUS_DRIVER_PENDING
                              ? "Driver Pending"
                              : orderModel.status == ORDER_STATUS_SHIPPED
                                  ? "Order Ready to Pickup"
                                  : orderModel.status == ORDER_STATUS_IN_TRANSIT
                                      ? "In Transit"
                                      : orderModel.status == ORDER_STATUS_REJECTED
                                          ? "Order Rejected"
                                          : "Order Completed",
                    ),
                    buildOtherDetails(
                      title: "Order Date",
                      value: DateFormat('yyyy-MM-dd hh:mm a').format(orderModel.createdAt!.toDate()),
                    ),
                  ],
                ),
                Visibility(
                  visible: orderModel.isSchedule == true ? true : true,
                  child: Column(
                    children: [
                      const Divider(
                        color: Colors.black12,
                        thickness: 1,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: buildOtherDetails(
                              title: "PickUp date",
                              value: DateFormat('yyyy-MM-dd hh:mm a').format(orderModel.senderPickupDateTime!.toDate()),
                            ),
                          ),
                          Expanded(
                            child: buildOtherDetails(
                              title: "Drop Date",
                              value: DateFormat('yyyy-MM-dd hh:mm a').format(orderModel.receiverPickupDateTime!.toDate()),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: Colors.black12,
                  thickness: 1,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildOtherDetails(
                      title: "Distance",
                      value: orderModel.distance.toString() + " Km",
                    ),
                    buildOtherDetails(
                      title: "Weight",
                      value: orderModel.parcelWeight.toString(),
                    ),
                    buildOtherDetails(title: "Rate", value: symbol + double.parse(orderModel.subTotal!).toStringAsFixed(decimal), color: Colors.purple),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double taxCalculation(ParcelOrderModel orderModel) {
    double totalTax = 0.0;

    if (orderModel.taxType!.isNotEmpty) {
      if (orderModel.taxType == "percent") {
        totalTax = (double.parse(orderModel.subTotal.toString()) - double.parse(orderModel.discount.toString())) * double.parse(orderModel.tax.toString()) / 100;
      } else {
        totalTax = double.parse(orderModel.tax.toString());
      }
    }
    return totalTax;
  }

  buildOtherDetails({
    required String title,
    required String value,
    Color color = Colors.black,
  }) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(
              height: 5,
            ),
            Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: color)),
          ],
        ),
      ),
    );
  }

  buildUsersDetails(context, {ParcelUserDetails? userDetails, bool isSender = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(
                  isSender ? "Sender".tr() + " " : "Receiver".tr() + " ",
                  style: TextStyle(fontSize: 18, color: isSender ? Colors.purple : const Color(0xffd17e19)),
                ),
                Text(
                  userDetails!.name.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Text(
            userDetails.phone.toString(),
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          Text(
            userDetails.address.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  buildLine() {
    return Column(
      children: [
        const SizedBox(
          height: 6,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0,
          ),
          child: Image.asset("assets/images/circle.png", height: 20),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 2),
          child: SizedBox(
            width: 1.3,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: 15,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Container(
                      color: Colors.black38,
                      height: 2.5,
                    ),
                  );
                }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Image.asset("assets/images/parcel_Image.png", height: 20),
        ),
      ],
    );
  }
}
