import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartdriver/Parcel_service/parcel_order_model.dart';
import 'package:emartdriver/constants.dart';
import 'package:emartdriver/services/helper.dart';
import 'package:flutter/material.dart';

class ParcelOrderDetailScreen extends StatefulWidget {
  final ParcelOrderModel orderModel;

  const ParcelOrderDetailScreen({Key? key, required this.orderModel}) : super(key: key);

  @override
  State<ParcelOrderDetailScreen> createState() => _ParcelOrderDetailScreenState();
}

class _ParcelOrderDetailScreenState extends State<ParcelOrderDetailScreen> {
  ParcelOrderModel? orderModel;
  String totalAmount = "";

  @override
  void initState() {
    // TODO: implement initState
    orderModel = widget.orderModel;
    totalAmount =
        "$symbol ${(double.parse(orderModel!.subTotal!.toString()) - double.parse(orderModel!.discount!.toString()) + taxCalculation(orderModel!)).toStringAsFixed(decimal)}";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Oder Detail".tr(),
          style: TextStyle(
            color: isDarkMode(context) ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
                child: Column(
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
                              buildUsersDetails(context, isSender: true, userDetails: orderModel?.sender),
                              const SizedBox(
                                height: 20,
                              ),
                              buildUsersDetails(context, isSender: false, userDetails: orderModel?.receiver),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        buildOtherDetails(
                          title: "Distance",
                          value: orderModel!.distance.toString() + " Km",
                        ),
                        buildOtherDetails(
                          title: "Weight",
                          value: orderModel!.parcelWeight.toString(),
                        ),
                        buildOtherDetails(title: "Rate", value: symbol + double.parse(orderModel!.subTotal!).toStringAsFixed(decimal), color: Colors.purple),
                      ],
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              height: 60,
                              width: 60,
                              imageUrl: orderModel!.author!.profilePictureURL,
                              placeholder: (context, url) => Image.asset('assets/images/img_placeholder.png'),
                              errorWidget: (context, url, error) => Image.asset('assets/images/placeholder.jpg', fit: BoxFit.fill),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  orderModel!.author!.firstName + " " + orderModel!.author!.lastName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(
                                  height: 2,
                                ),
                                Text(
                                  "Your Customer",
                                  style: TextStyle(color: Colors.black.withOpacity(0.60)),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    buildPaymentDetails(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
            Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: color)),
          ],
        ),
      ),
    );
  }

  buildPaymentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Text(
            'Order Summary'.tr(),
            style: TextStyle(
              fontFamily: 'Poppinsm',
              fontSize: 16,
              letterSpacing: 0.5,
              color: isDarkMode(context) ? Colors.white : const Color(0XFF000000),
            ),
          ),
        ),
        const Divider(
          color: Color(0xffE2E8F0),
          thickness: 1,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Subtotal".tr(),
              style: TextStyle(fontFamily: "Poppinsm", color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff888888), fontSize: 16),
            ),
            Text(
              symbol + double.parse(orderModel!.subTotal!).toStringAsFixed(decimal),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDarkMode(context) ? Colors.white : Colors.black,
              ),
            )
          ],
        ),
        const Divider(
          color: Color(0xffE2E8F0),
          thickness: 1,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Discount".tr(),
              style: TextStyle(fontFamily: "Poppinsm", color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff888888), fontSize: 16),
            ),
            Text(
              symbol + orderModel!.discount!.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDarkMode(context) ? Colors.white : Colors.black,
              ),
            )
          ],
        ),
        const Divider(
          color: Color(0xffE2E8F0),
          thickness: 1,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              ((orderModel!.taxLabel!.isNotEmpty) ? orderModel!.taxLabel.toString() : "Tax".tr()) + " ${(orderModel!.taxType == "fix") ? "" : "(${orderModel!.tax} %)"}",
              style: TextStyle(fontFamily: "Poppinsm", color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff888888), fontSize: 16),
            ),
            Text(
              symbol + taxCalculation(orderModel!).toStringAsFixed(decimal),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDarkMode(context) ? Colors.white : Colors.black,
              ),
            )
          ],
        ),
        const Divider(
          color: Color(0xffE2E8F0),
          thickness: 1,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Total".tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDarkMode(context) ? Colors.white : Colors.black,
              ),
            ),
            Text(
              "$symbol ${((double.parse(orderModel!.subTotal!.toString())) - double.parse(orderModel!.discount!.toString()) + taxCalculation(orderModel!)).toStringAsFixed(decimal)}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        SizedBox(
          height: 10,
        )
      ],
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

  buildUsersDetails(context, {bool isSender = true, required ParcelUserDetails? userDetails}) {
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
                  style: TextStyle(fontSize: 18, color: Colors.purple),
                ),
                Text(
                  userDetails!.name!,
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Text(
            userDetails.phone!,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            userDetails.address!,
            maxLines: 3,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  ///createLine
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
                padding: EdgeInsets.zero,
                itemCount: 18,
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
