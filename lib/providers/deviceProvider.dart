

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothProvider extends ChangeNotifier {
  BluetoothCharacteristic? _readCharacteristic;
  BluetoothCharacteristic? _writeCharacteristic;

  // Getter method for readCharacteristic
  BluetoothCharacteristic? get readCharacteristic => _readCharacteristic;

  // Getter method for writeCharacteristic
  BluetoothCharacteristic? get writeCharacteristic => _writeCharacteristic;

  void setCharacteristics({
    BluetoothCharacteristic? readCharacteristic,
    BluetoothCharacteristic? writeCharacteristic,
  }) {
    _readCharacteristic = readCharacteristic;
    _writeCharacteristic = writeCharacteristic;
    // Save characteristics to SharedPreferences
    _saveCharacteristicsToSharedPreferences();
    notifyListeners();
  }



  Future<void> _saveCharacteristicsToSharedPreferences() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (_readCharacteristic != null && _writeCharacteristic != null) {
      // Save the UUIDs and properties
      await prefs.setString('readCharacteristicUUID', _readCharacteristic.toString());
      await prefs.setString('writeCharacteristicUUID', _writeCharacteristic.toString());
    }
}



}
