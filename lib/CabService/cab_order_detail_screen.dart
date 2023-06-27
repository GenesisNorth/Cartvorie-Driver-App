import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../model/CabOrderModel.dart';
import '../services/helper.dart';

class CabOrderDetailScreen extends StatefulWidget {
  final CabOrderModel orderModel;
  const CabOrderDetailScreen({Key? key, required this.orderModel}) : super(key: key);

  @override
  State<CabOrderDetailScreen> createState() => _CabOrderDetailScreenState();
}

class _CabOrderDetailScreenState extends State<CabOrderDetailScreen> {
  CabOrderModel? orderModel;
  String totalAmount = "";

  @override
  void initState() {
    // TODO: implement initState
    orderModel = widget.orderModel;
    totalAmount =
        "$symbol ${(double.parse(orderModel!.subTotal!.toString()) - double.parse(orderModel!.discount!.toString()) + double.parse(orderModel!.tipValue!.toString()) + taxCalculation(orderModel!)).toStringAsFixed(decimal)}";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Ride Detail",
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
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10),
                child: Column(
                  children: [
                    widget.orderModel.driver != null
                        ? Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    CachedNetworkImage(
                                      height: 50,
                                      width: 50,
                                      imageUrl: orderModel!.author.profilePictureURL,
                                      imageBuilder: (context, imageProvider) => Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                                        ),
                                      ),
                                      placeholder: (context, url) => Center(
                                          child: CircularProgressIndicator.adaptive(
                                        valueColor: AlwaysStoppedAnimation(Colors.purple),
                                      )),
                                      errorWidget: (context, url, error) => ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            placeholderImage,
                                            fit: BoxFit.cover,
                                          )),
                                      fit: BoxFit.cover,
                                    ),
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  orderModel!.author.firstName + " " + orderModel!.author.lastName,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                Text(
                                                  totalAmount,
                                                  style: TextStyle(fontSize: 18, color: Colors.purple),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 6,
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                Text(
                                                  orderDate(orderModel!.createdAt).trim(),
                                                  style: const TextStyle(color: Colors.black, fontSize: 14),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                                                  child: Container(
                                                    width: 7,
                                                    height: 7,
                                                    decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
                                                  ),
                                                ),
                                                Text(
                                                  orderModel!.paymentStatus ? "Paid".tr() : "UnPaid".tr(),
                                                  style: TextStyle(fontSize: 15, color: orderModel!.paymentStatus ? Colors.green : Colors.deepOrangeAccent),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const Divider(thickness: 1),
                              buildCabDetail(),
                            ],
                          )
                        : Container(),
                    const Divider(thickness: 1),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        Image.asset(
                          "assets/images/ic_pic_drop_location.png",
                          height: 80,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                        child: Text(
                                      orderModel!.sourceLocationName.toString(),
                                      maxLines: 2,
                                    )),
                                    const Text(""),
                                  ],
                                ),
                                SizedBox(
                                  height: 30,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                        child: Text(
                                      orderModel!.destinationLocationName.toString(),
                                      maxLines: 2,
                                    )),
                                    const Text(""),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    const Divider(thickness: 1),
                    buildPaymentDetails(),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  buildCabDetail() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 30),
          child: Text(
            "Cab Details :".tr(),
            style: TextStyle(
              color: isDarkMode(context) ? Colors.white54 : Colors.black54,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              orderModel!.driver!.carNumber,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDarkMode(context) ? Colors.white : Colors.black,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                "|",
                style: TextStyle(color: isDarkMode(context) ? Colors.white54 : Colors.black54, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              orderModel!.driver!.carMakes,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDarkMode(context) ? Colors.white : Colors.black,
              ),
            )
          ],
        ),
      ],
    );
  }

  buildPaymentDetails() {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              "Payment Details".tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode(context) ? Colors.white : Colors.black,
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Sub Total".tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode(context) ? Colors.white54 : Colors.black54,
                ),
              ),
              Text(
                symbol + double.parse(orderModel!.subTotal.toString()).toStringAsFixed(decimal),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode(context) ? Colors.white : Colors.black,
                ),
              )
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Discount".tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode(context) ? Colors.white54 : Colors.black54,
                ),
              ),
              Text(
                symbol + orderModel!.discount!.toStringAsFixed(decimal),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode(context) ? Colors.white : Colors.black,
                ),
              )
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tax".tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode(context) ? Colors.white54 : Colors.black54,
                ),
              ),
              Text(
                symbol + taxCalculation(orderModel!).toStringAsFixed(decimal),
                style: TextStyle(fontFamily: "Poppinssm", color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: 16),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tip".tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode(context) ? Colors.white54 : Colors.black54,
                ),
              ),
              Text(
                symbol + (orderModel!.tipValue!.toString().isEmpty ? "0.0" : orderModel!.tipValue!.toString()),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode(context) ? Colors.white : Colors.black,
                ),
              )
            ],
          ),
          const Divider(),
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
                symbol + getTotalAmount().toStringAsFixed(decimal),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.purple,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  double getTotalAmount() {
    return double.parse(orderModel!.subTotal.toString()) -
        double.parse(orderModel!.discount.toString()) +
        taxCalculation(orderModel!) +
        double.parse(orderModel!.tipValue!.isEmpty ? "0.0" : orderModel!.tipValue.toString());
  }

  double taxCalculation(CabOrderModel orderModel) {
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
}
