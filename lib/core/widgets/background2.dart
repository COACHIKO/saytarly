import 'dart:ui';
import 'package:flutter/material.dart';

class BlurryBackgroundPage2 extends StatelessWidget {
  const BlurryBackgroundPage2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1️⃣ الصورة كخلفية
          SizedBox.expand(
            child: Image.asset(
              'assets/images/cafe.jpg', // مسار الصورة
              fit: BoxFit.cover,
            ),
          ),

          // 2️⃣ تأثير البلور
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // قوة البلور
            child: Container(
              color: Colors.black.withOpacity(0), // Layer شفافة لتطبيق البلور
            ),
          ),

          // 3️⃣ المحتوى فوق الخلفية
        ],
      ),
    );
  }
}
