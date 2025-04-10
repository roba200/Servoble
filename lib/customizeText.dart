import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:sizer/sizer.dart';

class CustomizeText extends StatelessWidget {

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color textColor;
   TextDecoration? textDecoration;
   TextAlign? textAlignment;
   Color? decorationColor;

  CustomizeText({super.key,  required this.text, required this.fontSize, required this.fontWeight, required this.textColor, this.textDecoration,this.textAlignment,this.decorationColor});

  @override
  Widget build(BuildContext context) {
    return  Text(
text,
style:TextStyle(fontFamily: 'SF Pro Text',fontSize:fontSize.sp,fontWeight: fontWeight,color: textColor,decoration: textDecoration,decorationColor: decorationColor??Colors.transparent ),
textAlign: textAlignment,
// style: GoogleFonts.getFont('Open Sans').color()

);
  }
}
