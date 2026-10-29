import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RichtextButtonWidget extends StatelessWidget {
  const RichtextButtonWidget({this.text1, this.text2, this.onPressFunction});

  final Function()? onPressFunction;
  final String? text1, text2;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressFunction,
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
              text: "$text1",
              style: TextStyle(
                color: Colors.black,
              )),
          TextSpan(
              text: "$text2",
              style: TextStyle(color: Colors.black, fontSize: 10.sp)),
        ]),
      ),
    );
  }
}
