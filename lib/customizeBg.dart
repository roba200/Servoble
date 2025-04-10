import 'package:Luftklappensteuerung/utility/app_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


class CustomBg extends StatelessWidget {
 final Widget? widgetOne;
 final Widget? widgetTwo;
 final Widget? widgetThree;
   CustomBg({super.key,required this.widgetOne,required this.widgetTwo, this.widgetThree});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Stack(
        children: [
          Container(
            color: AppColours.bgColor,
          ),
          if (widgetOne != null && widgetTwo != null && widgetThree != null  ) // Check if both widgets are provided

            Padding( padding: EdgeInsets.only(top: 7.5.h,left: 6.w),
            child: widgetOne
              ),

          Padding( padding: EdgeInsets.only(top: 5.h,left: 36.w),
            child:widgetTwo
          ),

          Padding( padding: EdgeInsets.only(top: 6.h,left: 82.w),
              child:widgetThree
          ),
        ],

      ),

    );
  }
}
