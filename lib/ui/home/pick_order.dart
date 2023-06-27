import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartdriver/constants.dart';
import 'package:emartdriver/model/OrderModel.dart';
import 'package:emartdriver/services/helper.dart';
import 'package:flutter/material.dart';

class PickOrder extends StatefulWidget {
  final OrderModel? currentOrder;

  PickOrder({
    Key? key,
    required this.currentOrder,
  }) : super(key: key);

  @override
  _PickOrderState createState() => _PickOrderState();
}

class _PickOrderState extends State<PickOrder> {
  bool _value = false;
  int val = -1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: -8,
        title: Text(
          "Pick".tr() + ": ${widget.currentOrder!.id}",
          style: TextStyle(
            color: isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff000000),
            fontFamily: "Poppinsr",
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.grey.shade100, width: 0.1),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade200, blurRadius: 2.0, spreadRadius: 0.4, offset: Offset(0.2, 0.2)),
                  ],
                  color: Colors.white),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Image.asset(
                    'assets/images/order3x.png',
                    height: 25,
                    width: 25,
                    color: Colors.purple,
                  ),
                  Text(
                    "Order ready, Pick now !".tr(),
                    style: TextStyle(
                      color: Colors.purple,
                      fontFamily: "Poppinsm",
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 28),
            Text(
              "ITEMS".tr(),
              style: TextStyle(
                color: Color(0xff9091A4),
                fontFamily: "Poppinsm",
              ),
            ),
            SizedBox(height: 24),
            ListView.builder(
                shrinkWrap: true,
                itemCount: widget.currentOrder!.products.length,
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
                                imageUrl: '${widget.currentOrder!.products[index].photo}',
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
                                    '${widget.currentOrder!.products[index].name}',
                                    style: TextStyle(fontFamily: 'Poppinsr', letterSpacing: 0.5, color: isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff333333)),
                                  ),
                                  SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(Icons.close, size: 15, color: Colors.purple),
                                      Text('${widget.currentOrder!.products[index].quantity}',
                                          style: TextStyle(
                                            fontFamily: 'Poppinsm',
                                            fontSize: 17,
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
                  border: Border.all(color: Colors.grey, width: 0.1),
                  // boxShadow: [
                  //   BoxShadow(
                  //       color: Colors.grey.shade200,
                  //       blurRadius: 8.0,
                  //       spreadRadius: 1.2,
                  //       offset: Offset(0.2, 0.2)),
                  // ],
                  color: Colors.white),
              child: ListTile(
                onTap: () {
                  setState(() {
                    _value = !_value;
                  });
                },
                selected: _value,
                leading: _value
                    ? Image.asset(
                        'assets/images/mark_selected3x.png',
                        height: 21,
                        width: 21,
                      )
                    : Image.asset(
                        'assets/images/mark_unselected3x.png',
                        height: 21,
                        width: 21,
                      ),
                title: Text(
                  "Confirm Items".tr(),
                  style: TextStyle(
                    color: _value ? Color(0xff8e24aa) : Colors.black,
                    fontFamily: 'Poppinsm',
                  ),
                ),
              ),
            ),
            SizedBox(height: 26),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey, width: 0.1),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade200, blurRadius: 2.0, spreadRadius: 0.4, offset: Offset(0.2, 0.2)),
                  ],
                  color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0, top: 12),
                    child: Text(
                      "DELIVER".tr(),
                      style: TextStyle(
                        color: Color(0xff9091A4),
                        fontFamily: "Poppinsr",
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text(
                      '${widget.currentOrder!.author.shippingAddress.name}',
                      style: TextStyle(
                        color: Color(0xff333333),
                        fontFamily: "Poppinsm",
                      ),
                    ),
                    subtitle: Text(
                      '${widget.currentOrder!.author.shippingAddress.line1},'
                      '${widget.currentOrder!.author.shippingAddress.line2},'
                      '${widget.currentOrder!.author.shippingAddress.city}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xff9091A4),
                        fontFamily: "Poppinsr",
                      ),
                    ),
                  )
                ],
              ),
            )
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
              backgroundColor: _value ? Colors.purple : Colors.purple.withOpacity(0.4),
            ),
            child: Text(
              "PICKED ORDER".tr(),
              style: TextStyle(letterSpacing: 0.5),
            ),
            onPressed: () => _value ? Navigator.pop(context) : null,
          ),
        ),
      ),
    );
  }
}
