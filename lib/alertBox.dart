
import 'package:Luftklappensteuerung/utility/app_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';



class AlertBox extends StatelessWidget {
  double? height;
  double? width;
  EdgeInsets? titlePadding;
  Widget? titleWidget;
  Widget? contentWidget;

   AlertBox({super.key,this.height,this.width,this.titlePadding,this.titleWidget,this.contentWidget});

  @override
  Widget build(BuildContext context) {
    return
      AlertDialog(

        surfaceTintColor: AppColours.white,
      backgroundColor: AppColours.white,
titlePadding: titlePadding??EdgeInsets.only(top: 4.h),

      title:
    titleWidget,
      content:
     contentWidget
    );
  }
}
// AlertDialog(
// backgroundColor: AppColours.whiteColor,
// titlePadding: EdgeInsets.only(top: 4.h),
// title: Column(
// children: [
// Center(child: CustomizeText(text: "Successfully",fontSize: 12,fontWeight: FontWeight.bold, textColor: AppColours.primaryColor,)),
//
// Center(child: CustomizeText(text: "Completed",fontSize: 12,fontWeight: FontWeight.bold, textColor: AppColours.primaryColor,)),
// ],
// ),
// content: Container(
// height: 10.h,
// width: 80.w,
// child: Center(
// child: Container(
// //color: Colors.yellow,
// child: Image.asset(AppIcons.sucessGif,height: 10.h,width: 25.w,))
// // Icon(
// //   Icons.check_circle,
// //   size: 50,
// //   color: AppColours.primaryColor,
// // ),
// ),
// ),
// );


