import 'dart:convert';
import 'package:Luftklappensteuerung/customButtons.dart';
import 'package:Luftklappensteuerung/customizeText.dart';

import 'package:Luftklappensteuerung/providers/deviceProvider.dart';
import 'package:Luftklappensteuerung/settings.dart';
import 'package:Luftklappensteuerung/utility/app_color.dart';
import 'package:Luftklappensteuerung/utility/app_icons.dart';
import 'package:Luftklappensteuerung/utility/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'dart:io';

class MainScreen extends StatefulWidget {
  final BluetoothDevice? reconnectedDevice;

  const MainScreen({
    Key? key,
    this.reconnectedDevice,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  TextEditingController minTemp = TextEditingController();
  TextEditingController maxTemp = TextEditingController();
  TextEditingController sollTemp = TextEditingController();
  TextEditingController hysteresis = TextEditingController();
  TextEditingController servoMaxPosition = TextEditingController();
  TextEditingController servoMinPosition = TextEditingController();
  TextEditingController servoSteps = TextEditingController();
  DateTime? selectedDate;
  late BluetoothProvider bluetoothProvider;
  String readUUID = '';
  double tempp = 0.0;
  int servoP = 0;
  double istTempp = 0.0;
  double sollTempp = 0.0;
  double hyst = 0.0;
  int servoA = 0;
  int servoMax = 0;
  int servoMin = 0;
  int servoS = 0;
  double maxTempp = 0.0;
  double minTempp = 0.0;
  String? date;
  bool isConnect = false;

  StringBuffer logBuffer = StringBuffer(); // To store all logs
  bool isDownloading = false; // Add this line to track the download state
  List<String> logEntries = [];
  bool hasDownloadedLogs = false; // Flag to track if logs have been downloaded
  double downloadProgress = 0.0; // Add this line to track the download progress

  @override
  void initState() {
    super.initState();

    bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);

    // Process the reconnected device if available
    if (widget.reconnectedDevice != null) {
      print(
          "Using reconnected device from splash screen: ${widget.reconnectedDevice!.id}");

      // Ensure we have proper connection and characteristics
      Future.delayed(Duration(seconds: 1), () async {
        await initializeReconnectedDevice();
        await enableNotificationAndReadData();
      });
    } else {
      // Regular initialization without reconnection
      getConnectionStatus();
      enableNotificationAndReadData();
    }

    loadCharacteristicsFromSharedPreferences();
    requestPermissions();
  }

  getConnectionStatus() async {
    var prefs = await SharedPreferences.getInstance();
    isConnect = prefs.getBool("IS_CONNECTED") ?? false;
    print("connection:$isConnect");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: AppColours.bgColor,
            height: 100.h,
            width: 100.w,
            child: Padding(
              padding: EdgeInsets.only(top: 6.h, left: 5.w, right: 5.w),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 8.h,
                      width: 100.w,
                      //    color: Colors.yellow,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            isConnect
                                ? Icons.bluetooth_connected
                                : Icons.bluetooth_disabled,
                            color: isConnect ? Colors.green : Colors.black,
                          ),
                          Container(
                              width: 18.w,
                              //   color: Colors.blueGrey,
                              height: 7.h,
                              child: SvgPicture.asset(
                                AppIcons.logo,
                                fit: BoxFit.cover,
                              )),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Settting()));
                            },
                            child: Icon(
                              Icons.menu,
                              color: AppColours.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 3.h,
                    ),
                    CustomizeText(
                        text: "Home",
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        textColor: AppColours.primaryColor),
                    SizedBox(
                      height: 2.h,
                    ),
                    Container(
                      height: 68.h,
                      width: 100.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColours.shadowColor
                                .withOpacity(0.4), // Shadow color with opacity
                            spreadRadius: 0, // Spread radius
                            blurRadius: 0.48, // Blur radius
                            offset: Offset(0,
                                2), // Changes position of shadow: (horizontal, vertical)
                          ),
                        ],
                      ),
                      child: Padding(
                        padding:
                            EdgeInsets.only(top: 2.h, left: 5.w, right: 5.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomizeText(
                                text: "Current Data",
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                textColor: AppColours.primaryColor),
                            SizedBox(
                              height: 2.h,
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 2.w, right: 2.w),
                              child: Column(
                                children: [
                                  buildRow(context, "Temperature:", "$tempp °C",
                                      AppIcons.temp),
                                  SizedBox(
                                    height: 2.h,
                                  ),
                                  buildRow(context, "Servo Position:",
                                      " $servoP°", AppIcons.pos),
                                  // SizedBox(
                                  //   height: 2.h,
                                  //
                                  // ),
                                  // buildRow(context, "Ist Temperature", " $istTempp °C", AppIcons.temp),
                                  SizedBox(
                                    height: 2.h,
                                  ),
                                  buildRow(context, "Servo Angle:", " $servoA°",
                                      AppIcons.pos),
                                  SizedBox(
                                    height: 2.h,
                                  ),
                                  buildRow(context, "Min Temperature:",
                                      " $minTempp °C", AppIcons.minTemp),
                                  SizedBox(
                                    height: 2.h,
                                  ),
                                  buildRow(context, "Max Temperature:",
                                      " $maxTempp °C", AppIcons.maxTemp),
                                  SizedBox(
                                    height: 2.h,
                                  ),
                                  buildRow(context, "Soll Temperature:",
                                      " $sollTempp °C", AppIcons.soll_icon),
                                  SizedBox(
                                    height: 2.h,
                                  ),
                                  buildRow(context, "Hysteresis:", " $hyst °C",
                                      AppIcons.hystersis),
                                  SizedBox(
                                    height: 2.h,
                                  ),
                                  buildRow(context, "Servo Max Position:",
                                      " $servoMax°", AppIcons.servoMax),
                                  SizedBox(
                                    height: 2.h,
                                  ),
                                  buildRow(context, "Servo Min Position:",
                                      " $servoMin°", AppIcons.servoMin),
                                  SizedBox(
                                    height: 2.h,
                                  ),
                                  buildRow(context, "Servo Steps:", " $servoS°",
                                      AppIcons.servoSteps),
                                  SizedBox(
                                    height: 2.h,
                                  ),
                                  buildRow(context, "Date:", " $date",
                                      AppIcons.date),
                                ],
                              ),
                            )
                          ],
                        ),
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
                        if (isConnect) {
                          if (logEntries.isEmpty) {
                            // If no logs are available yet, request logs from device
                            setState(() {
                              isDownloading = true;
                              downloadProgress = 0.0; // Start at 0%
                            });
                            sendDownloadLogsCommand();
                          } else {
                            // If logs already received, proceed with download
                            setState(() {
                              isDownloading = true;
                              downloadProgress = 0.0;
                            });
                            downloadLogs();
                          }
                        } else {
                          Utils().toastMsg("Device is not connected");
                        }
                      },
                      text: "Download Log",
                      btnColor: AppColours.btnColor,
                    ),
                    SizedBox(
                      height: 3.h,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isDownloading)
            Container(
              color: Colors.black54,
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Card(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Downloading Logs",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: 200,
                          child: LinearProgressIndicator(
                            value: downloadProgress,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColours.btnColor),
                            minHeight: 10,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "${(downloadProgress * 100).toInt()}%",
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> requestPermissions() async {
    if (await Permission.manageExternalStorage.isGranted) {
      // Permission already granted
      print("Storage permission is already granted");
    } else {
      // Request permission
      final status = await Permission.manageExternalStorage.request();

      if (status.isGranted) {
        print("Storage permission granted");
      } else {
        // Handle permission denied
        print("Storage permission denied");
        // You can show a toast message or dialog here
        // Utils().toastMsg('Storage permission denied');
      }
    }
  }

  void downloadLogs() async {
    final downloadPath = '/storage/emulated/0/Documents/logs.txt';
    String logContent = logEntries.join('\n');

    try {
      // Set initial progress for file preparation
      setState(() {
        downloadProgress = 0.2;
      });

      await Future.delayed(
          Duration(milliseconds: 300)); // Visual feedback delay

      // Create file
      File file = File(downloadPath);

      // Update progress for file creation
      setState(() {
        downloadProgress = 0.4;
      });

      await Future.delayed(
          Duration(milliseconds: 300)); // Visual feedback delay

      // Clean log content
      String cleanedContent =
          logContent.replaceAll(RegExp(r'LOG:|DOWNLOAD_LOGS'), '').trim();

      // Update progress for content processing
      setState(() {
        downloadProgress = 0.6;
      });

      await Future.delayed(
          Duration(milliseconds: 300)); // Visual feedback delay

      // Write to file
      await file.writeAsString(cleanedContent);

      // Update progress for file writing complete
      setState(() {
        downloadProgress = 0.9;
      });

      await Future.delayed(
          Duration(milliseconds: 300)); // Visual feedback delay

      // Complete
      setState(() {
        downloadProgress = 1.0;
      });

      // Notify user of successful save
      Utils().toastMsg('Logs saved to $downloadPath');
      print('Logs saved to $downloadPath');

      // Clear data for next download
      logEntries = [];
      hasDownloadedLogs = false;

      // Hide progress bar after a short delay
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            isDownloading = false;
          });
        }
      });
    } catch (e) {
      // Show error and reset progress
      Utils().toastMsg('Error saving logs: $e');
      print('Error saving logs: $e');
      setState(() {
        isDownloading = false;
      });
    }
  }

  void sendDownloadLogsCommand() async {
    if (bluetoothProvider.readCharacteristic != null) {
      // Clear any existing logs before requesting new ones
      logEntries.clear();
      String command = "DOWNLOAD_LOGS";
      List<int> bytes = utf8.encode(command);

      try {
        if (bluetoothProvider.readCharacteristic!.properties.write) {
          await bluetoothProvider.readCharacteristic
              ?.write(bytes, withoutResponse: false);
          print("Data written successfully: ${utf8.decode(bytes)}");
        } else if (bluetoothProvider
            .readCharacteristic!.properties.writeWithoutResponse) {
          await bluetoothProvider.readCharacteristic
              ?.write(bytes, withoutResponse: true);
          print(
              "Data written without waiting for a response: ${utf8.decode(bytes)}");
        } else {
          print("The characteristic does not support write operations.");
        }

        setState(() {
          isDownloading = true;
          downloadProgress = 0.0;
        });

        // Trust the progress updates from Arduino instead of using a fixed timeout
        // The progress messages from the device will control the download state
      } catch (e) {
        print("Error sending command: $e");
        setState(() {
          isDownloading = false;
        });
        Utils().toastMsg("Error sending command to device");
      }
    } else {
      print("Bluetooth characteristic is not available.");
      setState(() {
        isDownloading = false;
      });
      Utils().toastMsg("Bluetooth not connected");
    }
  }

  Widget buildRow(
      BuildContext context, String name, String value, String icon) {
    return Row(
      children: [
        SvgPicture.asset(icon),
        SizedBox(
          width: 5.w,
        ),
        CustomizeText(
            text: "$name $value",
            fontSize: 12,
            fontWeight: FontWeight.normal,
            textColor: AppColours.primaryColor),
      ],
    );
  }

  Future<void> loadCharacteristicsFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load the UUIDs from SharedPreferences
    readUUID = prefs.getString('readCharacteristicUUID') ?? '';
    print("readUUID");

    print(readUUID);
    String? writeUUID = prefs.getString('writeCharacteristicUUID');

    if (readUUID != null && writeUUID != null) {}
  }

  Future<void> enableNotificationAndReadData() async {
    if (bluetoothProvider.readCharacteristic == null) {
      print("Cannot enable notifications: characteristic is null");
      return;
    }

    String buffer = '';

    try {
      print(
          "Setting up notifications on characteristic: ${bluetoothProvider.readCharacteristic}");

      // First disable notifications to reset the state
      await bluetoothProvider.readCharacteristic?.setNotifyValue(false);
      await Future.delayed(Duration(milliseconds: 500));

      // Now enable notifications
      bool success =
          await bluetoothProvider.readCharacteristic?.setNotifyValue(true) ??
              false;

      if (success) {
        print("Notifications enabled successfully");
      } else {
        print("Failed to enable notifications");
      }

      bluetoothProvider.readCharacteristic?.value.listen((value) async {
        String readableData = String.fromCharCodes(value);
        print("Raw data received: $readableData");

        buffer += readableData;
        print("Buffer content: $buffer");

        if (mounted) {
          setState(() {});
        }

        if (buffer.contains('\n')) {
          List<String> messages = buffer.split('\n');

          for (int i = 0; i < messages.length - 1; i++) {
            String message = messages[i].trim();

            // Handle log entries
            if (message.startsWith("DOWNLOAD_LOGSLOG:") ||
                message.startsWith("LOG:")) {
              logEntries.add(message);
              print("logList:$logEntries");
              print("logList Length: ${logEntries.length}");
            }
            // Handle progress updates from Arduino
            else if (message.startsWith("PROGRESS:")) {
              String progressStr = message.split(":")[1].trim();
              int progress = int.tryParse(progressStr) ?? 0;

              // Handle error case (-1)
              if (progress < 0) {
                setState(() {
                  isDownloading = false;
                });
                Utils().toastMsg("Error downloading logs from device");
              }
              // Handle normal progress
              else {
                setState(() {
                  downloadProgress = progress / 100.0;

                  // When progress reaches 100%, directly save the logs without restarting progress
                  if (progress >= 100 && isDownloading && !logEntries.isEmpty) {
                    // Save the logs directly without creating a new progress sequence
                    saveLogsToFile();
                  }
                });
                print("Download progress: $progress%");
              }
            }

            if (message.startsWith("LOG ENDs") && !hasDownloadedLogs) {
              hasDownloadedLogs = true;
              print("End of logs detected");

              if (isDownloading) {
                downloadLogs();
              }

              print("Log entries processed");
            }

            processMessage(message);
          }

          buffer = messages.last.trim();
        }
      });
    } catch (e) {
      print("Error enabling notifications: $e");
    }
  }

  Future<void> initializeReconnectedDevice() async {
    try {
      print("Initializing reconnected device...");

      if (bluetoothProvider.readCharacteristic != null) {
        print("Characteristics already available in provider");

        setState(() {
          isConnect = true;
        });

        try {
          List<int> bytes = utf8.encode("READ");
          await bluetoothProvider.readCharacteristic?.write(bytes);
          print("Wake-up command sent");
        } catch (e) {
          print("Error sending wake-up command: $e");
        }
      } else {
        print("Characteristics not available, discovering services");

        List<BluetoothService> services =
            await widget.reconnectedDevice!.discoverServices();

        for (var service in services) {
          if (service.uuid.toString() == "ffe0") {
            for (var characteristic in service.characteristics) {
              if (characteristic.uuid.toString() == "ffe1") {
                bluetoothProvider.setCharacteristics(
                  readCharacteristic: characteristic,
                  writeCharacteristic: characteristic,
                );

                setState(() {
                  isConnect = true;
                });

                print("Characteristics set after rediscovery");
                break;
              }
            }
          }
        }
      }
    } catch (e) {
      print("Error initializing reconnected device: $e");
    }
  }

  void processMessage(String message) {
    try {
      if (message.startsWith("TEMP:")) {
        String tempStr = message.split(":")[1].trim();
        tempp = double.parse(tempStr);
      } else if (message.startsWith("SERVO_POS:")) {
        String servoStr = message.split(":")[1].trim();
        servoP = int.parse(servoStr);
      } else if (message.startsWith("IST_TEMP:")) {
        String istTempStr = message.split(":")[1].trim();
        istTempp = double.parse(istTempStr);
      } else if (message.startsWith("SOLL_TEMP:")) {
        String sollTempStr = message.split(":")[1].trim();
        sollTempp = double.parse(sollTempStr);
      } else if (message.startsWith("HYST:")) {
        String hystStr = message.split(":")[1].trim();
        hyst = double.parse(hystStr);
      } else if (message.startsWith("WINKEL:")) {
        String winkelStr = message.split(":")[1].trim();
        servoA = int.parse(winkelStr);
      } else if (message.startsWith("SERVO_MAX:")) {
        String servoMaxStr = message.split(":")[1].trim();
        servoMax = int.parse(servoMaxStr);
      } else if (message.startsWith("SERVO_MIN:")) {
        String oMinStr = message.split(":")[1].trim();
        servoMin = int.parse(oMinStr);
      } else if (message.startsWith("SCHRITTE:")) {
        String schritteStr = message.split(":")[1].trim();
        servoS = int.parse(schritteStr);
      } else if (message.startsWith("MAX_TEMP:")) {
        String maxTempStr = message.split(":")[1].trim();
        maxTempp = double.parse(maxTempStr);
      } else if (message.startsWith("MIN_TEMP:")) {
        String minTempStr = message.split(":")[1].trim();
        minTempp = double.parse(minTempStr);
      } else if (message.startsWith("DATE:")) {
        String dateStr = message.split(":")[1].trim();
        date = dateStr.replaceAll(',', '').trim();
      }
    } catch (e) {
      print("Error parsing message: $message, error: $e");
    }
  }

  // Add new method to save logs directly to file
  void saveLogsToFile() async {
    final downloadPath = '/storage/emulated/0/Documents/logs.txt';
    String logContent = logEntries.join('\n');

    try {
      // Create file
      File file = File(downloadPath);

      // Clean log content
      String cleanedContent =
          logContent.replaceAll(RegExp(r'LOG:|DOWNLOAD_LOGS'), '').trim();

      // Write to file
      await file.writeAsString(cleanedContent);

      // Notify user of successful save
      Utils().toastMsg('Logs saved to $downloadPath');
      print('Logs saved to $downloadPath');

      // Clear data for next download
      logEntries = [];
      hasDownloadedLogs = false;

      // Hide progress bar
      setState(() {
        isDownloading = false;
      });
    } catch (e) {
      // Show error and reset progress
      Utils().toastMsg('Error saving logs: $e');
      print('Error saving logs: $e');
      setState(() {
        isDownloading = false;
      });
    }
  }
}
