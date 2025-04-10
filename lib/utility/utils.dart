import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import 'app_color.dart';

class Utils{
  void toastMsg(String msg){
    Fluttertoast.showToast(

      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColours.GreyColor,
      textColor: AppColours.primaryColor,
      fontSize: 14.sp,
    );
  }
}


