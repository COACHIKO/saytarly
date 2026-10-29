import 'package:flutter/material.dart';

import 'package:pinput/pinput.dart';

import '../utils/constants/colors.dart';
import '../utils/helpers/helper_functions.dart';

class PinInputWidget extends StatelessWidget {
  const PinInputWidget({
    this.controller,
  });

  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Pinput(
      length: 4,
      keyboardType: TextInputType.number,
      cursor: Container(
          width: 2,
          height: MediaQuery.of(context).size.height * .02,
          color: CColors.buttonPrimary),
      defaultPinTheme: PinTheme(
        width: MediaQuery.of(context).size.width * .1,
        height: MediaQuery.of(context).size.height * .045,
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            color: dark ? CColors.secondary : CColors.softGrey),
      ),
      focusedPinTheme: PinTheme(
        width: MediaQuery.of(context).size.width * .15,
        height: MediaQuery.of(context).size.height * .045,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border: Border.all(color: CColors.buttonPrimary),
        ),
      ),
      controller: controller,
    );
  }
}
