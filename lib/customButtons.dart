import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'customizeText.dart';

class CustomButtons extends StatefulWidget {
  final String text;
   Color? btnColor;
  final Color outlineColor;
  final Color textColor;
  final VoidCallback onPressed;
 final double width;
   double? height;
  double? radius;
  double? fontSize;
   FontWeight? fontWeight;
   CustomButtons({super.key,this.fontWeight,this.height,this.fontSize,this.radius,required this.width,  this.btnColor, required this.outlineColor, required this.textColor, required this.onPressed,required this.text});

  @override
  State<CustomButtons> createState() => _CustomButtonsState();
}

class _CustomButtonsState extends State<CustomButtons> {
  @override
  Widget build(BuildContext context) {
    return
      InkWell(
      onTap: widget.onPressed
      ,
      child: Container(
        height: widget.height??6.h,
        width: widget.width.w,
        decoration:BoxDecoration(
          color: widget.btnColor,
          borderRadius: BorderRadius.circular(widget.radius??25.0),
            border: Border.all(
        color: widget.outlineColor,
            style: BorderStyle.solid
        )
        )
        ,

        child: Center(
          child:

          CustomizeText( text: widget.text, fontSize: widget.fontSize??12.5, fontWeight:widget.fontWeight?? FontWeight.w600, textColor: widget.textColor,textAlignment: TextAlign.center,),

        ),
      ),
    );
  }
}
