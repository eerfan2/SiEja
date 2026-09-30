import 'package:flutter/material.dart';

// Export file konfigurasi layout khusus Guru & Siswa
export 'responsive_teacher.dart';
export 'responsive_student.dart';

class ResponsiveHelper {
  // Breakpoint
  static bool isTablet(double width) => width >= 600;
  static bool isPhone(double width) => width < 600;

  // Lebar dialog yang aman (tidak overflow, tidak terlalu kecil)
  // Menutup maksimal lebar dialog di 560 agar tidak membesar secara konyol di tablet lebar
  static double dialogWidth(double screenWidth) {
    return (screenWidth * 0.88).clamp(280.0, 560.0);
  }

  // Lebar konten utama jika tidak ingin dibiarkan lebar memenuhi layar (seperti form)
  static double contentMaxWidth(double screenWidth) {
    return screenWidth.clamp(0.0, 600.0);
  }

  // Padding dialog yang proporsional
  static EdgeInsets dialogPadding(double width) {
    if (isTablet(width)) {
      return const EdgeInsets.fromLTRB(48, 100, 48, 50);
    }
    return const EdgeInsets.fromLTRB(36, 80, 36, 36);
  }

  // Padding horizontal untuk form (contoh)
  static double horizontalPadding(double width) {
    if (isTablet(width)) {
      return width * 0.2;
    }
    // di phone
    return 16.0;
  }
}
