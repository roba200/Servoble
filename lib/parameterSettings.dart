import 'dart:async';
import 'dart:convert';

import 'package:Luftklappensteuerung/providers/deviceProvider.dart';
import 'package:Luftklappensteuerung/settings.dart';
import 'package:Luftklappensteuerung/utility/app_color.dart';
import 'package:Luftklappensteuerung/utility/app_icons.dart';
import 'package:Luftklappensteuerung/utility/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import 'customButtons.dart';
import 'customizeText.dart';

class ParameterSettings extends StatefulWidget {
  const ParameterSettings({super.key});

  @override
  State<ParameterSettings> createState() => _ParameterSettingsState();
}

class _ParameterSettingsState extends State<ParameterSettings> {
  TextEditingController minTemp = TextEditingController();
  TextEditingController maxTemp = TextEditingController();
  TextEditingController sollTemp = TextEditingController();
  TextEditingController hysteresis = TextEditingController();
  TextEditingController servoMaxPosition = TextEditingController();
  TextEditingController servoMinPosition = TextEditingController();
  TextEditingController servoSteps = TextEditingController();
  DateTime? selectedDate;
  String readUUID = '';
  late BluetoothProvider bluetoothProvider;
  bool isConnect = false;
  StreamSubscription<List<int>>?
      _dataSubscription; // Subscription to listen for data
  final Set<String> _receivedKeys = {}; // Track received keys

  @override
  void initState() {
    super.initState();
    bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
    getConnectionStatus();
    loadCharacteristicsFromSharedPreferences();
    loadInputValuesFromDevice(); // Load input values from BLE device
    loadDateFromSharedPreferences(); // Load date when the page loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: 100.h,
        color: AppColours.bgColor,
        width: 100.w,
        child: Padding(
            padding: EdgeInsets.only(top: 9.h, left: 5.w, right: 5.w),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Settting()),
                              (Route<dynamic> route) =>
                                  false, // This will remove all previous routes
                            );
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
                          text: 'Parameter Settings',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          textColor: AppColours.primaryColor),
                    ],
                  ),
                  SizedBox(
                    height: 5.h,
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 4.w, right: 4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildRow(context, "Min Temperature", AppIcons.minTemp,
                            minTemp),
                        SizedBox(
                          height: 2.5.h,
                        ),
                        buildRow(context, "Max Temperature", AppIcons.maxTemp,
                            maxTemp),
                        SizedBox(
                          height: 2.5.h,
                        ),
                        buildRow(context, "Soll Temperature",
                            AppIcons.soll_icon, sollTemp),
                        SizedBox(
                          height: 2.5.h,
                        ),
                        buildRow(context, "Hysteresis", AppIcons.hystersis,
                            hysteresis),
                        SizedBox(
                          height: 2.5.h,
                        ),
                        buildRow(context, "Servo Max Position",
                            AppIcons.servoMax, servoMaxPosition),
                        SizedBox(
                          height: 2.5.h,
                        ),
                        buildRow(context, "Servo Min Position",
                            AppIcons.servoMin, servoMinPosition),
                        SizedBox(
                          height: 2.5.h,
                        ),
                        buildRow(context, "Servo Steps", AppIcons.servoSteps,
                            servoSteps),
                        SizedBox(
                          height: 2.5.h,
                        ),
                        CustomizeText(
                            text: 'Date',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            textColor: AppColours.primaryColor),
                        SizedBox(
                          height: 1.5.h,
                        ),
                        CustomizeText(
                            text: selectedDate != null
                                ? 'Picked Date: ${selectedDate!.toLocal().toString().split(' ')[0]}'
                                : 'No date picked',
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            textColor: AppColours.primaryColor),
                        SizedBox(
                          height: 1.5.h,
                        ),
                        GestureDetector(
                          onTap: () {
                            pickDate(context);
                          },
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                AppIcons.date,
                                color: AppColours.btnColor,
                              ),
                              SizedBox(
                                width: 3.w,
                              ),
                              CustomizeText(
                                text: 'Picked Date',
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                textColor: AppColours.btnColor,
                                textDecoration: TextDecoration.underline,
                                decorationColor: AppColours.btnColor,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 10.h,
                        ),
                        CustomButtons(
                          width: 100.w,
                          outlineColor: AppColours.btnColor,
                          textColor: Colors.white,
                          onPressed: () {
                            if (isConnect) {
                              onSendButtonPressed(); // Call the updated method to send data one by one
                            } else {
                              Utils().toastMsg("Device not connected");
                            }
                          },
                          text: "Submit",
                          btnColor: AppColours.btnColor,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ),
    );
  }

  getConnectionStatus() async {
    var prefs = await SharedPreferences.getInstance();
    isConnect = prefs.getBool("IS_CONNECTED") ?? false;
    print("connection:$isConnect");
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

  Future<void> pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(), // Use selectedDate directly
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate; // Update selectedDate directly
      });
    }
  }

  void onSendButtonPressed() async {
    List<String> dataToSend = [
      'minT:${minTemp.text}',
      'maxT:${maxTemp.text}',
      'sollT:${sollTemp.text}',
      'hys:${hysteresis.text}',
      'servoMax:${servoMaxPosition.text}',
      'servoMin:${servoMinPosition.text}',
      'servoSteps:${servoSteps.text}',
      'date:${selectedDate?.year}-${selectedDate?.month.toString().padLeft(2, '0')}-${selectedDate?.day.toString().padLeft(2, '0')}',
    ];

    for (String data in dataToSend) {
      if (data != '' || data.isNotEmpty) {
        await writeDataToDevice(data);
      }
    }

    saveInputValuesToSharedPreferences(); // Save input values when the submit button is clicked
    saveDateToSharedPreferences(); // Save date when the submit button is clicked
    Utils().toastMsg("Data submitted successfully");
  }

  Future<void> writeDataToDevice(String field) async {
    const int maxChunkSize = 20; // Maximum allowed size for BLE
    const Duration delayBetweenSends =
        Duration(milliseconds: 3000); // Optional delay

    try {
      // Convert the field to bytes and add a newline at the end
      List<int> bytes =
          utf8.encode('${field.trim()}\n'); // Add newline character

      if (bluetoothProvider.readCharacteristic != null) {
        // Send the field in chunks if necessary
        for (int i = 0; i < bytes.length; i += maxChunkSize) {
          final chunk = bytes.sublist(
              i,
              (i + maxChunkSize < bytes.length)
                  ? i + maxChunkSize
                  : bytes.length);

          if (bluetoothProvider.readCharacteristic!.properties.write) {
            await bluetoothProvider.readCharacteristic
                ?.write(chunk, withoutResponse: false);
            print("Data written successfully: ${utf8.decode(chunk)}");
          } else if (bluetoothProvider
              .readCharacteristic!.properties.writeWithoutResponse) {
            await bluetoothProvider.readCharacteristic
                ?.write(chunk, withoutResponse: true);
            print("Data written without response: ${utf8.decode(chunk)}");
          } else {
            print("The characteristic does not support write operations.");
          }
        }
      } else {
        print("Error: readCharacteristic is null.");
      }

      // Optional delay to give time for processing
      await Future.delayed(delayBetweenSends);
    } catch (e) {
      print("Error writing data: $e");
    }
  }

  Future<void> saveInputValuesToSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('minTemp', minTemp.text);
    await prefs.setString('maxTemp', maxTemp.text);
    await prefs.setString('sollTemp', sollTemp.text);
    await prefs.setString('hysteresis', hysteresis.text);
    await prefs.setString('servoMaxPosition', servoMaxPosition.text);
    await prefs.setString('servoMinPosition', servoMinPosition.text);
    await prefs.setString('servoSteps', servoSteps.text);
    if (selectedDate != null) {
      await prefs.setString('selectedDate', selectedDate!.toIso8601String());
    }
  }

  Future<void> loadInputValuesFromDevice() async {
    try {
      if (bluetoothProvider.readCharacteristic != null) {
        // Enable notifications for the characteristic
        await bluetoothProvider.readCharacteristic?.setNotifyValue(true);

        // Listen for incoming data
        _dataSubscription =
            bluetoothProvider.readCharacteristic?.value.listen((value) {
          if (value.isNotEmpty) {
            String data = String.fromCharCodes(value).trim();
            print("Received data: $data");

            // Process the received data
            processReceivedData(data);

            // Stop listening if all required keys are received
            if (_receivedKeys.containsAll([
              "MIN_TEMP",
              "MAX_TEMP",
              "SOLL_TEMP",
              "HYST",
              "SERVO_MAX",
              "SERVO_MIN",
              "SCHRITTE",
              "DATE"
            ])) {
              _dataSubscription?.cancel();
              _dataSubscription = null;
              print("All data received. Stopping listener.");
            }
          }
        }, onError: (error) {
          print("Error receiving data: $error");
        });
      } else {
        print("Error: readCharacteristic is null.");
      }
    } catch (e) {
      print("Error setting up notifications: $e");
    }
  }

  void processReceivedData(String data) {
    try {
      if (data.contains(":")) {
        List<String> parts = data.split(":");
        if (parts.length == 2) {
          String key = parts[0].trim();
          String value = parts[1].trim();

          setState(() {
            switch (key) {
              case "MIN_TEMP":
                minTemp.text = value;
                _receivedKeys.add(key);
                break;
              case "MAX_TEMP":
                maxTemp.text = value;
                _receivedKeys.add(key);
                break;
              case "SOLL_TEMP":
                sollTemp.text = value;
                _receivedKeys.add(key);
                break;
              case "HYST":
                hysteresis.text = value;
                _receivedKeys.add(key);
                break;
              case "SERVO_MAX":
                servoMaxPosition.text = value;
                _receivedKeys.add(key);
                break;
              case "SERVO_MIN":
                servoMinPosition.text = value;
                _receivedKeys.add(key);
                break;
              case "SCHRITTE":
                servoSteps.text = value;
                _receivedKeys.add(key);
                break;
              case "DATE":
                selectedDate = DateTime.tryParse(value);
                _receivedKeys.add(key);
                break;
              default:
                print("Unknown key: $key");
            }
          });
        }
      }
    } catch (e) {
      print("Error processing received data: $e");
    }
  }

  Future<void> saveDateToSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (selectedDate != null) {
      await prefs.setString('selectedDate', selectedDate!.toIso8601String());
    }
  }

  Future<void> loadDateFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? dateString = prefs.getString('selectedDate');
    if (dateString != null) {
      setState(() {
        selectedDate = DateTime.parse(dateString);
      });
    }
  }

  Widget buildRow(BuildContext context, String name, String icon,
      TextEditingController controller) {
    return Row(
      children: [
        SvgPicture.asset(icon),
        SizedBox(
          width: 5.w,
        ),
        SizedBox(
          width: 38.w,
          child: CustomizeText(
              text: name,
              fontSize: 12,
              fontWeight: FontWeight.normal,
              textColor: AppColours.primaryColor),
        ),
        SizedBox(
          width: 5.w,
        ),
        Container(
          height: 5.h,
          width: 27.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColours.textfieldBorderColor),
          ),
          child: Center(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: InputBorder.none,
                counterText: "",
                hintText: name.contains("Servo")
                    ? "-360 to 360"
                    : name.contains("Steps")
                        ? "0 to 360"
                        : "-999 to 999",
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(name.contains("Servo")
                    ? r'^-?(360|[1-9]?[0-9]|[1-2][0-9]{2}|3[0-5][0-9])$'
                    : r'^-?\d{0,3}$')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Cancel the subscription if it's still active
    _dataSubscription?.cancel();
    super.dispose();
  }
}
