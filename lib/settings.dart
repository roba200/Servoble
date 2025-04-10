import 'package:Luftklappensteuerung/connectDevice.dart';
import 'package:Luftklappensteuerung/mainScreen.dart';
import 'package:Luftklappensteuerung/parameterSettings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sizer/sizer.dart';

import '../../utility/app_color.dart';
import '../../utility/app_icons.dart';
import 'customizeText.dart';

class Settting extends StatefulWidget {
  Settting({super.key});

  @override
  State<Settting> createState() => _SetttingState();
}

class _SetttingState extends State<Settting> {
  TextEditingController searchBarController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // bottomNavigationBar: MyBottomNavBar(),
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
                                  builder: (context) => MainScreen()),
                              (Route<dynamic> route) =>
                                  false, // This will remove all previous routes
                            );
                            //   Navigator.push(context,MaterialPageRoute(builder: (context)=>MainScreen()));
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
                          text: 'Settings',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          textColor: AppColours.primaryColor),
                    ],
                  ),

                  // SizedBox(height: 3.h,),
                  // Search_Bar(s),
                  SizedBox(
                    height: 5.h,
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 4.w, right: 4.w),
                    //   color: Colors.yellow,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ParameterSettings()));
                            },
                            child: buildContainer(
                              context,
                              "Parameter Settings",
                              AppIcons.params,
                              AppIcons.RighArrow,
                              AppColours.primaryColor,
                            )),
                        SizedBox(
                          height: 4.h,
                        ),
                        GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ConnectDevice()));
                            },
                            child: buildContainer(
                              context,
                              "Connect Device",
                              AppIcons.bluetooth,
                              AppIcons.RighArrow,
                              AppColours.primaryColor,
                            )),
                      ],
                    ),
                  )

                  //  CustomEventCard(),
                ],
              ),
            )),
      ),
    );
  }

  Widget buildContainer(
    BuildContext context,
    String title,
    String iconPath_one,
    String? iconPathTwo,
    Color? txtColor,
  ) {
    return Padding(
      padding: EdgeInsets.only(left: 0.w, right: 0.w),
      child: Container(
        child: Row(
          children: [
            SvgPicture.asset(
              iconPath_one,
              color: title == 'Log out' ? Colors.red : Colors.black,
            ),
            SizedBox(
              width: 7.w,
            ),
            Expanded(
                flex: 3,
                child: Container(
                    width: 25.w,
                    // color: Colors.yellow,
                    child: CustomizeText(
                        text: title,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        textColor: txtColor ?? AppColours.primaryColor))),
            SizedBox(
              width: 15.w,
            ),
            if (iconPathTwo != null)
              SvgPicture.asset(
                iconPathTwo,
                color: Colors.black,
              ),
          ],
        ),
      ),
    );
  }
}
