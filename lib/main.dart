import 'package:Luftklappensteuerung/providers/deviceProvider.dart';
import 'package:Luftklappensteuerung/mainScreen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'blutoothdevice.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Removed the removeConnection method as we want to keep connections

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, screenType) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BluetoothProvider()),
        ],
        child: MaterialApp(
          title: 'Luftklappensteuerung',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        ),
      );
    });
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  bool _isInitialized = false;
  BluetoothDevice? reconnectedDevice;

  @override
  void initState() {
    super.initState();
    // Instead of removing connections, try to reconnect
    initializeBluetoothAndReconnect();
  }

  // New method to handle Bluetooth initialization and reconnection
  Future<void> initializeBluetoothAndReconnect() async {
    try {
      print("Starting Bluetooth initialization and reconnect sequence");

      // Initialize Bluetooth
      await _initializeBluetooth();

      // Check if we have a device to reconnect to
      String? savedDeviceId = await getDeviceIdFromFile();

      if (savedDeviceId != null && savedDeviceId.isNotEmpty) {
        print("Found saved device ID: $savedDeviceId");
        try {
          var device = BluetoothDevice.fromId(savedDeviceId);

          // Start reconnection process
          await _reconnectToDevice(device);

          // Store the device for the main screen
          reconnectedDevice = device;
        } catch (e) {
          print("Failed to reconnect to saved device: $e");
        }
      } else {
        print("No saved device found for auto-reconnect");
      }
    } catch (e) {
      print("Error during initialization: $e");
    } finally {
      // Mark initialization as complete and navigate
      setState(() {
        _isInitialized = true;
      });

      // Navigate after initialization
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    MainScreen(reconnectedDevice: reconnectedDevice)));
      });
    }
  }

  // Helper method to initialize Bluetooth
  Future<void> _initializeBluetooth() async {
    if (Platform.isAndroid) {
      // Turn on Bluetooth programmatically on Android
      try {
        await FlutterBluePlus.turnOn();
        print("Bluetooth turned on");
      } catch (e) {
        print("Error turning on Bluetooth: $e");
      }
    }
  }

  // Helper method to reconnect to a device
  Future<void> _reconnectToDevice(BluetoothDevice device) async {
    try {
      print("Attempting to connect to device: ${device.id}");

      // First disconnect if already connected to reset connection state
      try {
        await device.disconnect();
        await Future.delayed(Duration(seconds: 1));
      } catch (e) {
        print("Device was not connected: $e");
      }

      // Connect to device
      await device.connect();
      await Future.delayed(Duration(seconds: 2)); // Give time for connection

      // Discover services
      print("Discovering services...");
      List<BluetoothService> services = await device.discoverServices();
      print("Found ${services.length} services");

      // Find the specific service and characteristic we need
      BluetoothCharacteristic? readCharacteristic;
      BluetoothCharacteristic? writeCharacteristic;

      for (var service in services) {
        print("Checking service: ${service.uuid}");
        if (service.uuid.toString() == "ffe0") {
          print("Found target service: ${service.uuid}");
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == "ffe1") {
              print("Found target characteristic: ${characteristic.uuid}");
              readCharacteristic = characteristic;
              writeCharacteristic = characteristic;
            }
          }
        }
      }

      // Store the characteristics in the provider
      if (readCharacteristic != null) {
        final bluetoothProvider =
            Provider.of<BluetoothProvider>(context, listen: false);
        bluetoothProvider.setCharacteristics(
            readCharacteristic: readCharacteristic,
            writeCharacteristic: writeCharacteristic ?? readCharacteristic);
        print("Characteristics set in provider");
      }

      // Store the connection in global BluetoothDevicePro
      final bluetoothDevicePro = BluetoothDevicePro();
      bluetoothDevicePro.setbluetoothdevice(device);

      // Update shared preferences
      await storeConnectionInfo(device, true);

      print("Successfully reconnected to device");
    } catch (e) {
      print("Error reconnecting to device: $e");
      throw e;
    }
  }

  // Helper method to get device ID from file
  Future<String?> getDeviceIdFromFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/remoteId.txt');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      print("Error reading device ID from file: $e");
    }
    return null;
  }

  // Helper method to store connection info
  Future<void> storeConnectionInfo(
      BluetoothDevice device, bool isConnected) async {
    try {
      var prefs = await SharedPreferences.getInstance();
      await prefs.setBool('IS_CONNECTED', isConnected);
      await prefs.setString('bluetooth_device_name', device.name);
      await prefs.setString('bluetooth_device_address', device.id.toString());
    } catch (e) {
      print("Error storing connection info: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.only(left: 10.w, right: 10.w),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/applogo.png',
                    color: Colors.black,
                  ),
                  SizedBox(height: 20),
                  if (!_isInitialized)
                    Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Attempting to reconnect..."),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
