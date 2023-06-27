import 'model/CurrencyModel.dart';

const FINISHED_ON_BOARDING = 'finishedOnBoarding';
const COLOR_ACCENT = 0xff8e24aa;
const COLOR_PRIMARY_DARK = 0xFF2c7305;
var COLOR_PRIMARY = 0xff8e24aa;
const DARK_COLOR = 0xff191A1C;
const COLOR_ACCENt1 = 0xFF94D5BE;
var WHITE = 0xFFFFFFFF;
// 0xFF5EA23A;
const FACEBOOK_BUTTON_COLOR = 0xFF415893;
const USERS = 'users';
const CARMAKES = 'car_make';
const VEHICLETYPE = 'vehicle_type';
const RENTALVEHICLETYPE = 'rental_vehicle_type';
const CARMODEL = 'car_model';
const RIDESORDER = "rides";
const PARCELORDER = "parcel_orders";
const RENTALORDER = "rental_orders";

String appVersion = '';

const STORAGE_ROOT = 'emart';
const CHANNEL_PARTICIPATION = 'channel_participation';
const CHANNELS = 'channels';
const THREAD = 'thread';
const REPORTS = 'reports';
const CATEGORIES = 'vendor_categories';
const VENDORS = 'vendors';
const PRODUCTS = 'vendor_products';
const Setting = 'settings';
const CONTACT_US = 'ContactUs';
const ORDERS = 'vendor_orders';
const OrderTransaction = "order_transactions";
const driverPayouts = "driver_payouts";
const Order_Rating = 'items_review';
const Wallet = "wallet";

const SECOND_MILLIS = 1000;
const MINUTE_MILLIS = 60 * SECOND_MILLIS;
const HOUR_MILLIS = 60 * MINUTE_MILLIS;
const SERVER_KEY = 'Replace with your Server key';
const GOOGLE_API_KEY = 'Replace with your API key';

String placeholderImage = 'https://firebasestorage.googleapis.com/v0/b/emart-8d99f.appspot.com/o/images%2Fplace_holder%20(2).png?alt=media&token=c2eb35a9-ddf2-4b66-9cc6-d7d82e48d97b';

const ORDER_STATUS_PLACED = 'Order Placed';
const ORDER_STATUS_ACCEPTED = 'Order Accepted';
const ORDER_STATUS_REJECTED = 'Order Rejected';
const ORDER_STATUS_DRIVER_PENDING = 'Driver Pending';
const ORDER_STATUS_DRIVER_ACCEPTED = 'Driver Accepted';
const ORDER_STATUS_DRIVER_REJECTED = 'Driver Rejected';
const ORDER_STATUS_SHIPPED = 'Order Shipped';
const ORDER_STATUS_IN_TRANSIT = 'In Transit';
const ORDER_STATUS_COMPLETED = 'Order Completed';
const ORDER_REACHED_DESTINATION = 'Reached Destination';

const USER_ROLE_DRIVER = 'driver';

const DEFAULT_CAR_IMAGE = 'https://firebasestorage.googleapis.com/v0/b/emart-8d99f.appspot.com/o/images%2Fcar_default_image.png?alt=media&token=ba12a79d-d876-4b1c-87ed-2b06cd5b50f0';

const Currency = 'currencies';
String symbol = '';
bool isRight = false;
int decimal = 2;

int driverOrderAcceptRejectDuration = 0;
bool enableOTPParcelReceive = false;
bool enableOTPTripStart = false;

String currName = "";
CurrencyModel? currencyData;
String currentCabOrderID = "";
