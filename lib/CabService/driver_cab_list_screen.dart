import 'package:easy_localization/easy_localization.dart';
import 'package:emartdriver/CabService/add_cab_driver_screen.dart';
import 'package:emartdriver/CabService/driver_cab_order_list.dart';
import 'package:emartdriver/constants.dart';
import 'package:emartdriver/main.dart';
import 'package:emartdriver/model/User.dart';
import 'package:emartdriver/services/FirebaseHelper.dart';
import 'package:emartdriver/services/helper.dart';
import 'package:flutter/material.dart';

class DriverCabListScreen extends StatefulWidget {
  const DriverCabListScreen({Key? key}) : super(key: key);

  @override
  State<DriverCabListScreen> createState() => _DriverCabListScreenState();
}

class _DriverCabListScreenState extends State<DriverCabListScreen> {
  List<User> driverList = [];

  @override
  void initState() {
    // TODO: implement initState
    getCompanyDriver();
    super.initState();
  }

  getCompanyDriver() async {
    await FireStoreUtils().getCabCompanyDriver(MyAppState.currentUser!.userID).then((value) {
      setState(() {
        driverList = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          child: ListView.builder(
            itemCount: driverList.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode(context) ? Colors.grey.shade700 : Colors.white,
                      borderRadius:
                          const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 2,
                          offset: const Offset(0, 2), // changes position of shadow
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              driverList[index].profilePictureURL.isEmpty
                                  ? CircleAvatar(
                                      radius: 20.0,
                                      backgroundImage: AssetImage('assets/images/placeholder.jpg'),
                                      backgroundColor: Colors.transparent,
                                    )
                                  : CircleAvatar(
                                      radius: 20.0,
                                      backgroundImage: NetworkImage(driverList[index].profilePictureURL.toString()),
                                      backgroundColor: Colors.transparent,
                                    ),
                              const SizedBox(
                                width: 5,
                              ),
                              Expanded(
                                child: Text(driverList[index].firstName.toString(),
                                    style: TextStyle(fontSize: 16, color: Colors.black, letterSpacing: 1, fontWeight: FontWeight.w600)),
                              ),
                              InkWell(
                                onTap: () {
                                  push(
                                      context,
                                      DriverCabOrderList(
                                        driverId: driverList[index].userID,
                                      ));
                                },
                                child: Text("View Rides".tr(), style: TextStyle(fontSize: 16, color: Colors.purple, letterSpacing: 1, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Row(
                            children: [
                              Text(
                                "Car Info :- ".tr(),
                                style: TextStyle(color: Colors.black.withOpacity(0.60), fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                "${driverList[index].carName.toString()} ${driverList[index].carMakes.toString()}",
                                style: const TextStyle(color: Colors.black, fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                    onTap: () async {
                                      showProgress(context, 'Please wait...'.tr(), false);
                                      print("--------->${driverList[index].userID}");
                                      await FireStoreUtils().deleteOtherUser(driverList[index].userID).then((value) {
                                        hideProgress();
                                        getCompanyDriver();
                                      });
                                    },
                                    child: Icon(Icons.delete, color: Colors.red)),
                                SizedBox(
                                  width: 10,
                                ),
                                InkWell(
                                    onTap: () async {
                                      final result = await Navigator.of(context).push(MaterialPageRoute(
                                          builder: (context) => AddCabDriverScreen(
                                                driverDetails: driverList[index],
                                                isDashBoard: false,
                                              )));
                                      print(result);
                                      if (result != null) {
                                        getCompanyDriver();
                                      }
                                    },
                                    child: Icon(Icons.edit, color: Colors.purple)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        onPressed: () async {
          final result = await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => AddCabDriverScreen(
                    driverDetails: null,
                    isDashBoard: false,
                  )));
          print(result);
          if (result != null) {
            getCompanyDriver();
          }
        },
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
