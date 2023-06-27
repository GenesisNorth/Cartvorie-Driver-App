import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emartdriver/model/User.dart';

class RentalOrderModel {
  String id;
  String? status;
  String? subTotal;
  String? driverRate;
  String? discount;
  String? adminCommission;
  String? adminCommissionType;
  String? discountType;
  String? discountLabel;
  String? tax;
  String? taxType;
  String? taxLabel;
  String? pickupAddress;
  String? dropAddress;
  bool? bookWithDriver;
  List<dynamic>? rejectedByDrivers;
  Timestamp? pickupDateTime;
  Timestamp? dropDateTime;
  UserLocation? pickupLatLong;
  UserLocation? dropLatLong;

  String authorID;
  String paymentMethod;
  User? author;
  User? driver;
  String? driverID;

  User? company;
  String? companyID;
  Timestamp? createdAt;
  Timestamp? trigger_delevery;

  RentalOrderModel({
    this.id = '',
    this.status,
    this.subTotal,
    this.driverRate,
    this.discount,
    this.adminCommission,
    this.adminCommissionType,
    this.discountType,
    this.discountLabel,
    this.tax,
    this.taxType,
    this.taxLabel,
    this.pickupAddress,
    this.dropAddress,
    this.pickupDateTime,
    this.dropDateTime,
    this.pickupLatLong,
    this.dropLatLong,
    this.rejectedByDrivers,
    this.driver,
    this.author,
    this.driverID,
    this.company,
    this.companyID = '',
    this.authorID = '',
    this.paymentMethod = '',
    this.bookWithDriver = false,
    this.createdAt,
    this.trigger_delevery,
  });

  factory RentalOrderModel.fromJson(Map<String, dynamic> json) {
    return RentalOrderModel(
      id: json['id'] ?? "",
      status: json['status'] ?? "",
      subTotal: json['subTotal'] ?? "",
      driverRate: json['driverRate'] ?? "",
      discount: json['discount'] ?? "",
      adminCommission: json['adminCommission'] ?? "",
      adminCommissionType: json['adminCommissionType'] ?? "",
      discountLabel: json['discountLabel'] ?? "",
      discountType: json['discountType'] ?? "",
      tax: json['tax'] ?? "",
      taxType: json['taxType'] ?? "",
      taxLabel: json['taxLabel'] ?? "",
      pickupAddress: json['pickupAddress'] ?? "",
      dropAddress: json['dropAddress'] ?? "",
      bookWithDriver: json['bookWithDriver'] ?? false,
      rejectedByDrivers: json['rejectedByDrivers'] ?? [],
      pickupDateTime: json['pickupDateTime'] ?? Timestamp.now(),
      dropDateTime: json['dropDateTime'] ?? Timestamp.now(),
      pickupLatLong: json['pickupLatLong'] != null ? UserLocation.fromJson(json['pickupLatLong']) : UserLocation(),
      dropLatLong: json['dropLatLong'] != null ? UserLocation.fromJson(json['dropLatLong']) : UserLocation(),
      author: json.containsKey('author') ? User.fromJson(json['author']) : User(),
      company: json.containsKey('company') ? User.fromJson(json['company']) : User(),
      authorID: json['authorID'] ?? '',
      companyID: json['companyID'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      createdAt: json['createdAt'] ?? Timestamp.now(),
      trigger_delevery: json['trigger_delevery'] ?? Timestamp.now(),
      driver: json.containsKey('driver') ? User.fromJson(json['driver']) : null,
      driverID: json.containsKey('driverID') ? json['driverID'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      "id": id,
      "status": status,
      "subTotal": subTotal,
      "driverRate": driverRate,
      "discount": discount,
      "adminCommission": adminCommission,
      "adminCommissionType": adminCommissionType,
      "discountLabel": discountLabel,
      "discountType": discountType,
      "tax": tax,
      "taxType": taxType,
      "taxLabel": taxLabel,
      "pickupAddress": pickupAddress,
      "dropAddress": dropAddress,
      "pickupDateTime": pickupDateTime,
      "dropDateTime": dropDateTime,
      "bookWithDriver": bookWithDriver,
      "pickupLatLong": pickupLatLong!.toJson(),
      "dropLatLong": dropLatLong!.toJson(),
      "rejectedByDrivers": rejectedByDrivers,
      'author': author!.toJson(),
      'authorID': authorID,
      'payment_method': paymentMethod,
      'createdAt': createdAt,
      'trigger_delevery': trigger_delevery,
    };
    if (driver != null) {
      json.addAll({'driverID': driverID, 'driver': driver!.toJson()});
      if (companyID!.isNotEmpty) {
        json.addAll({'companyID': companyID, 'company': company!.toJson()});
      }
    }
    return json;
  }
}
