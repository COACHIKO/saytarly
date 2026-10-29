import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../routing/app_router.dart';

class ShowToast {
  ShowToast._();

  static showCustomSnackBar({required String message, required bool dark}) {
    ScaffoldMessenger.of(
            NavigationService.instance.navigationKey.currentContext!)
        .showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.close, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message.toString(),
                style: TextStyle(color: dark ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static showSuccessSnackBar({required String message, required bool dark}) {
    ScaffoldMessenger.of(
            NavigationService.instance.navigationKey.currentContext!)
        .showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.close, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message.toString(),
                style: TextStyle(color: dark ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showToastErrorTop({
    required String message,
    int? seconds,
  }) =>
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: seconds ?? 3,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16,
      );

  static void showToastSuccessTop({
    required String message,
    int? seconds,
  }) =>
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: seconds ?? 3,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16,
      );
}
