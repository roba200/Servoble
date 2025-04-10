import 'dart:async';
import 'dart:convert';
import 'package:Luftklappensteuerung/providers/deviceProvider.dart';
import 'package:Luftklappensteuerung/settings.dart';
import 'package:Luftklappensteuerung/snackbar.dart';
import 'package:Luftklappensteuerung/utility/app_color.dart';
import 'package:Luftklappensteuerung/utility/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'blutoothdevice.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'customButtons.dart';
import 'customizeText.dart';
import 'mainScreen.dart';
import 'package:path_provider/path_provider.dart';

class ConnectDevice extends StatefulWidget {
  const ConnectDevice({
    super.key,
  });

  @override
  State<ConnectDevice> createState() => _ConnectDeviceState();
}

class _ConnectDeviceState extends State<ConnectDevice> {
  int _counter = 0;

  List<BluetoothDevice> _systemDevices = [];
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  bool _isScanning = false;

  List<ScanResult> _scanResults = [];
  List<ScanResult> filteredResults = [];
  bool isConnected = false;
  List<BluetoothDevice> connectedDevicesList = [];
  static const String _deviceNameKey = 'bluetooth_device_name';
  static const String _deviceAddressKey = 'bluetooth_device_address';
  String? deviceName;
  String? deviceAddress;

  String? lastConnectedTime;
  late BluetoothDevicePro bluetoothDevicePro;
  BluetoothDevice? device;
  bool _isDiscoveringServices = false;
  late BluetoothCharacteristic readCharacteristicss;
  late BluetoothCharacteristic writeCharacteristicss;

  @override
  void initState() {
    super.initState();
    checkBluetooth();
    bluetoothDevicePro = BluetoothDevicePro();
    onScanPressed();
    getdevice();
    getDeviceFromSharedPreferences();
  }

  @override
  void dispose() {
    // Cancel subscriptions to avoid memory leaks
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();

    // Ensure any other listeners or streams are canceled
    FlutterBluePlus.scanResults.drain();
    FlutterBluePlus.isScanning.drain();

    super.dispose();
  }

  Widget _controlBT() {
    return StreamBuilder<BluetoothAdapterState>(
      stream: FlutterBluePlus.adapterState, // Use adapterState instead of state
      initialData: BluetoothAdapterState
          .unknown, // Add initial data to handle null safety
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final bluetoothState = snapshot.data;
          return Padding(
            padding: EdgeInsets.only(left: 6.w, right: 6.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(bluetoothState == BluetoothAdapterState.on
                    ? "Bluetooth on"
                    : "Bluetooth off"),
                ElevatedButton(
                  onPressed: () async {
                    if (bluetoothState == BluetoothAdapterState.off) {
                      // Ask the user to enable Bluetooth
                      // On Android, users can be prompted to enable Bluetooth.
                      await FlutterBluePlus.startScan(
                          timeout:
                              Duration(seconds: 4)); // Starting Bluetooth scan
                    } else {
                      await FlutterBluePlus
                          .stopScan(); // Stopping Bluetooth scan
                    }
                  },
                  child: Text(bluetoothState == BluetoothAdapterState.on
                      ? "Disable Bluetooth"
                      : "Enable Bluetooth"),
                ),
              ],
            ),
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  void enableBluetooth() async {
    var state = await FlutterBluePlus.state.first;
    if (state == BluetoothState.off) {
      // Request the user to turn on Bluetooth
      // Note: On iOS, you cannot programmatically enable/disable Bluetooth
      print('Bluetooth is off, please enable it manually.');
    }
  }

  Future<void> checkBluetooth() async {
    var subscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      print(state);
      if (state == BluetoothAdapterState.on) {
        print("isOn");
        // usually start scanning, connecting, etc
      } else {
        // show an error to the user, etc
      }
    });

// turn on bluetooth ourself if we can
// for iOS, the user controls bluetooth enable/disable
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    } else if (Platform.isIOS) {
      //openAppSettings();
    }

// cancel to prevent duplicate listeners
    subscription.cancel();
  }

  void openSettings() {
    // Guide the user to the settings
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Open Settings'),
          content: Text('Please go to Settings and turn on Bluetooth.'),
          actions: [
            TextButton(
              onPressed: () {
                // Open the settings app
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future getdevice() async {
    device = BluetoothDevicePro.Deviceee;
    if (device != null) {
      connectedDevicesList.clear();
      connectedDevicesList.add(device!);
    }
  }

  Future<void> onScanPressed() async {
    print("Scanning...");
    try {
      _systemDevices = await FlutterBluePlus.systemDevices([]);
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("System Devices Error:", e),
          success: false);
    }
    try {
      int divisor = Platform.isAndroid ? 8 : 1;
      await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 30),
          continuousUpdates: true,
          continuousDivisor: divisor);
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Start Scan Error:", e),
          success: false);
    }
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
        });
      }
    }, onError: (e) {});

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      if (mounted) {
        setState(() {
          _isScanning = state;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    filteredResults =
        _scanResults.where((r) => r.device.platformName.isNotEmpty).toList();
    filteredResults.sort((a, b) {
      // Move connected devices to the top
      if (a.device.isConnected && !b.device.isConnected) {
        print("$a , $b");
        return -1;
      } else if (!a.device.isConnected && b.device.isConnected) {
        print("$a , $b");
        return 1;
      }
      return 0;
    });

    // Filter out the connected devices
    _scanResults =
        filteredResults.where((result) => result.device.isConnected).toList();
    List<ScanResult> disconnectedDevices =
        filteredResults.where((result) => !result.device.isConnected).toList();
    // Sort the connected and disconnected devices
    _scanResults
        .sort((a, b) => a.device.platformName.compareTo(b.device.platformName));
    disconnectedDevices
        .sort((a, b) => a.device.platformName.compareTo(b.device.platformName));

    // Divider between connected and disconnected devices
    Widget divider = Divider(
      height: 1.h,
      color: Colors.black26,
      thickness: 1,
      endIndent: 7,
      indent: 7,
    );

    ///AppLocalizations.of(context)!.selectDate,
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 100.h,
            width: 100.w,
            color: AppColours.bgColor,
            // color: Colors.yellow,
            padding: EdgeInsets.only(top: 9.h, left: 5.w, right: 5.w),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //   _controlBT(),
                  //
                  //   SizedBox(height: 3.h,),
                  Row(
                    children: [
                      GestureDetector(
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Settting()),
                                (Route<dynamic> route) =>
                                    false); // This will remove all previous routes);
                          },
                          child: SvgPicture.asset(
                            AppIcons.left,
                            color: AppColours.primaryColor,
                            height: 3.h,
                            width: 4.w,
                          )),
                      SizedBox(
                        width: 7.w,
                      ),
                      CustomizeText(
                          text: 'Connect Device',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          textColor: AppColours.primaryColor),
                    ],
                  ),

                  SizedBox(
                    height: 4.h,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 3.w),
                    child: CustomizeText(
                        text: "${filteredResults.length} devices found",
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        textColor: AppColours.lightColor),
                  ),
                  SizedBox(
                    height: 1.h,
                  ),

                  Container(
                    // padding: EdgeInsets.only(left: 6.w,right: 6.w),
                    height: 70.h,
                    width: 100.w,
                    //    color: Colors.yellow,

                    child: Column(
                      children: [
                        SizedBox(
                          height: 1.h,
                        ),
                        Visibility(
                          visible: isConnected,
                          child: Container(
                            //     color: Colors.grey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  //   color: Colors.yellow,
                                  height: 10
                                      .h, // Set a constrained height for the ListView

                                  child: ListView.builder(
                                    itemBuilder: (context, index) {
                                      final device =
                                          connectedDevicesList[index];
                                      //     print("cdevice:$device");
                                      return _buildCustomCard(
                                          context,
                                          device.platformName,
                                          "Connected",
                                          AppColours.primaryColor,
                                          device);
                                    },
                                    itemCount: connectedDevicesList.length,
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                  ),
                                ),
                                SizedBox(height: 1.h),
                                divider,
                                SizedBox(height: 1.h),
                              ],
                            ),
                          ),
                        ),
                        //    if (disconnectedDevices.isNotEmpty)

                        Expanded(
                          child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: disconnectedDevices.length,
                              padding: EdgeInsets.zero,
                              itemBuilder: (context, index) {
                                return _buildCustomCard(
                                    context,
                                    disconnectedDevices[index]
                                        .device
                                        .platformName,
                                    "",
                                    Colors.transparent,
                                    disconnectedDevices[index].device);
                              }),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: 2.h,
                  ),
                  CustomButtons(
                    width: 100.w,
                    outlineColor: AppColours.btnColor,
                    textColor: Colors.white,
                    onPressed: () {
                      onScanPressed();
                    },
                    text: "Search Devices",
                    btnColor: AppColours.btnColor,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCustomCard(BuildContext context, String title, String subTitle,
      Color borderColor, BluetoothDevice devicee) {
    return Padding(
      padding: EdgeInsets.only(top: 1.h, bottom: 1.h),
      child: IntrinsicHeight(
        child: Container(
          //  height: 8.h,
          width: 100.w,
          decoration: BoxDecoration(
            color: AppColours.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: AppColours.shadowColor,
                spreadRadius: 1,
                blurRadius: 0.6,
                offset: Offset(0, 0), // Adjust the shadow position as needed
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                //color: Colors.blue,
                padding: EdgeInsets.only(
                    top: 2.h, bottom: 1.h, left: 5.w, right: 5.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomizeText(
                        text: title,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        textColor: AppColours.primaryColor),
                    CustomizeText(
                        text: subTitle,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        textColor: AppColours.lightColor)
                  ],
                ),
              ),
              PopupMenuButton<String>(
                surfaceTintColor: AppColours.bgColor,
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                      value: 'connect_disconnect_device',
                      child: isConnected
                          ? CustomizeText(
                              text: "Disconnect",
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              textColor: AppColours.primaryColor)
                          : CustomizeText(
                              text: "Connect",
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              textColor: AppColours.primaryColor)),
                  // PopupMenuItem<String>(
                  //     value: 'forget device',
                  //     child:
                  //     CustomizeText(text: 'Forget device', fontSize: 10, fontWeight: FontWeight.w500, textColor: AppColours.primaryColor)
                  //
                  // ),
                ],
                onSelected: (String value) async {
                  if (value == 'connect_disconnect_device' && isConnected) {
                    await devicee.disconnect();
                    storeConnectionStatus(devicee, false);

                    getLastConnectedTime(devicee.name);
                    checkconnection(devicee);
                    print("device disconnected: $devicee");
                    var prefs = await SharedPreferences.getInstance();
                    prefs.remove("IS_CONNECTED");
                    await prefs.setString('connection', '0');
                    connectedDevicesList.clear();
                    print(connectedDevicesList);
                    getdevice();
                    // Start scanning again to rediscover the device
                    await FlutterBluePlus.startScan(
                        timeout: Duration(seconds: 5));
                  } else {
                    onConnect(devicee);
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  //Connect to the device
  Future<void> onConnect(BluetoothDevice device,
      {bool autoConnect = false}) async {
    print("Connecting to device: $device");
    if (!mounted) return; // Ensure the widget is still in the tree
    setState(() {});

    try {
      if (autoConnect) {
        await device.connect(autoConnect: true, mtu: null);
        await device.connectionState
            .where((val) => val == BluetoothConnectionState.connected)
            .first;
      } else {
        await device.connect();
      }
      storeConnectionStatus(device, true);

      // Store the current time as the last connected time
      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      storeLastConnectedTime(device.platformName, currentDate);

      if (mounted) {
        setState(() {
          isConnected = true;
        });
      }
      print("Connected device: ${device.platformName}");

      bluetoothDevicePro.setbluetoothdevice(
          device); // Set the Bluetooth device in the instance
      print("bluetoothDevicePro.Deviceee: ${BluetoothDevicePro.Deviceee}");
      getdevice();

      // Discover services and enable notifications
      await onDiscoverServicesPressed();
      await enableNotificationAndReadData();
      checkconnection(device);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Connect Error:", e),
          success: false);
    }
  }

// Function to enable notifications and listen for data
  Future<void> enableNotificationAndReadData() async {
    String notifiedData = "";

    try {
      print("Enabling notifications for characteristic: $readCharacteristicss");

      if (readCharacteristicss == null) {
        throw Exception(
            "Characteristic is null, services may not be discovered properly");
      }

      // First, disable notifications if they were previously enabled
      await readCharacteristicss.setNotifyValue(false);
      await Future.delayed(Duration(milliseconds: 500));

      // Now enable notifications
      bool success = await readCharacteristicss.setNotifyValue(true);
      if (!success) {
        throw Exception("Failed to enable notifications");
      }

      print("Notification setting successful, waiting for updates...");

      // Listen to characteristic value changes
      readCharacteristicss.value.listen((value) {
        if (mounted) {
          print("Raw byte data: $value");
          String readableData = String.fromCharCodes(value);
          print("Notified value: $readableData");

          setState(() {
            notifiedData = readableData;
          });
        }
      }, onError: (error) {
        print("Error in notification stream: $error");
      });

      print("Notifications enabled and listening...");
    } catch (e) {
      print("Error enabling notifications: $e");
      throw e; // Rethrow for retry mechanism
    }
  }

  Future<void> writeDataToDevice(String dataToSend) async {
    try {
      print("Attempting to write data: $dataToSend");

      List<int> bytes = utf8.encode(dataToSend);

      // Try with response first
      if (readCharacteristicss.properties.write) {
        await readCharacteristicss.write(bytes, withoutResponse: false);
        print("Data written successfully (with response): $dataToSend");
      }
      // Otherwise try without response
      else if (readCharacteristicss.properties.writeWithoutResponse) {
        await readCharacteristicss.write(bytes, withoutResponse: true);
        print("Data written successfully (without response): $dataToSend");
      } else {
        print("The characteristic does not support write operations.");
      }

      // Wait after writing to allow device to process
      await Future.delayed(Duration(milliseconds: 300));
    } catch (e) {
      print("Error writing data: $e");
    }
  }

  //service discover
  Future onDiscoverServicesPressed() async {
    print('services discover');
    if (mounted) {
      setState(() {
        _isDiscoveringServices = true;
      });
    }

    try {
      device = BluetoothDevicePro.Deviceee;
      print("device::::$device");
      List<BluetoothService> services = await device!.discoverServices();
      // print("Services found");
      print(services);
      services.forEach((service) {
        // print(service);
        print("new service ${service.uuid.toString()}");
        if (service.uuid.toString() == "ffe0") {
          print("Service find");
          service.characteristics.forEach((characteristics) async {
            print("bla bla ${characteristics.uuid.toString()}");
            if (characteristics.uuid.toString() == "ffe1") {
              print("read chrc: $characteristics");
              readCharacteristicss = characteristics;
              print("nexttttttttt");
              final characteristicsProvider =
                  Provider.of<BluetoothProvider>(context, listen: false);
              characteristicsProvider.setCharacteristics(
                  readCharacteristic: characteristics,
                  writeCharacteristic: characteristics);
              print("readchrc:$readCharacteristicss");
              print("writechrc:$readCharacteristicss");
              //    await enableNotificationAndReadData();
              //   await  writeDataToDevice("Devicee");
            }
          });
        } else {
          print("The characteristic does not support read.");
        }
      });
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Discover Services Error:", e),
          success: false);
    }
    if (mounted) {
      setState(() {
        _isDiscoveringServices = false;
      });
    }
  }

  void checkconnection(BluetoothDevice device) async {
    print("checkconnection");
    print(device);
    print(device.name);

    getLastConnectedTime(device.name);

    // Subscribe to the connection state stream
    StreamSubscription<BluetoothConnectionState>? connectionSubscription;
    connectionSubscription =
        device.connectionState.listen((BluetoothConnectionState state) {
      // Handle connection state changes
      if (state == BluetoothConnectionState.connected) {
        // Device is connected
        print('Device is connected.');
      } else {
        // Device is not connected
        print('Device is not connectedddd.');
        storeConnectionStatus(device, false);
        connectedDevicesList.clear();
      }
    });
  }

//store device in shared preference
  void storeConnectionStatus(BluetoothDevice device, bool isConnected) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setBool('IS_CONNECTED', isConnected);
    await prefs.setString(_deviceNameKey, device.name);
    await prefs.setString(_deviceAddressKey, device.id.toString());
    print("Stored device name: ${device.name}");
    print("Stored device address: ${device.id}");
    await saveDeviceIdToFile(device.id.toString());
    getDeviceFromSharedPreferences();
  }

  Future<void> saveDeviceIdToFile(String deviceId) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/remoteId.txt');
    await file.writeAsString(deviceId);
  }

  Future<String?> getDeviceIdFromFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/remoteId.txt');
      return await file.readAsString();
    } catch (e) {
      print("Error reading device ID from file: $e");
      return null;
    }
  }

  //get device from shared preference
  void getDeviceFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    deviceName = prefs.getString(_deviceNameKey);
    print("DeviceNmaeee::$deviceName");
    //getLastConnectedTime(deviceName!);
    deviceAddress = prefs.getString(_deviceAddressKey);
    print("DeviceAddresss::$deviceAddress");
    final bool is_Conneected = prefs.getBool('IS_CONNECTED') ?? false;
    print("Devicestatus::$is_Conneected");

    if (mounted) {
      setState(() {
        isConnected = is_Conneected;
        print("After connect:$isConnected");
      });
    }

    print('enddddd');
    print(isConnected);
  }

//store time
  Future<void> storeLastConnectedTime(
      String deviceName, String lastConnectedTime) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(deviceName, lastConnectedTime);
    print("Stored:$deviceName,time:$lastConnectedTime");
  }

  //last connected time
  void getLastConnectedTime(String deviceName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    lastConnectedTime = prefs.getString(deviceName);
    print("devicelastconnected:$lastConnectedTime");
    print("done");
  }
}
