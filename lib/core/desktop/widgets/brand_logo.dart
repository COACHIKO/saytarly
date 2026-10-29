import 'dart:io';

import 'package:flutter/material.dart';

import 'package:saytarly/core/services/business_profile.dart';

/// لوجو البراند — بيجيب صورة السوبر ادمن (لو محددة من شاشة الملف التجاري)
/// وإلا يرجع للوجو الافتراضي المدمج، ولو اتشال بالغلط يظهر أيقونة.
///
/// بيتستخدم في سايدبار سطح المكتب وشاشة الملف التجاري.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 40,
    this.fit = BoxFit.cover,
    this.errorChild,
  });

  /// الحجم المنطقي للصورة المربعة.
  final double size;
  final BoxFit fit;

  /// ويدجت بديلة عند فشل تحميل أي صورة — افتراضيًا أيقونة كافيه.
  final Widget? errorChild;

  Future<Widget> _resolve(BuildContext context, IconData fallbackIcon) async {
    final path = await BusinessProfile.getLogoPath();

    if (path != null) {
      try {
        return Image.file(
          File(path),
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (_, __, ___) => _fallback(fallbackIcon),
        );
      } catch (_) {
        // الملف مش قابل للقراءة — نكمبل الافتراضي
      }
    }

    return Image.asset(
      BusinessProfile.defaultLogoAsset,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, __, ___) => _fallback(fallbackIcon),
    );
  }

  Widget _fallback(IconData icon) =>
      errorChild ??
      SizedBox(
        width: size,
        height: size,
        child: Icon(icon, size: size * 0.5),
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _resolve(context, Icons.local_cafe_rounded),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return snapshot.data ?? _fallback(Icons.local_cafe_rounded);
      },
    );
  }
}
