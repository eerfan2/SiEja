import 'package:flutter/material.dart';

/// Generic stage badge untuk Stage 7 dan seterusnya (atau stage tanpa aset gambar khusus).
/// Mengadopsi estetika medallion 3D playful SiEja dengan font Fredoka,
/// efek kedalaman, dan indikator status (Terkunci, Terbuka, Selesai).
class GenericStageBadge extends StatelessWidget {
  final int stageNumber;
  final String status; // 'locked' | 'unlocked' | 'completed'
  final bool isTablet;
  final double? size;

  const GenericStageBadge({
    super.key,
    required this.stageNumber,
    required this.status,
    this.isTablet = false,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? (isTablet ? 110.0 : 78.0);
    final isLocked = status == 'locked';
    final isCompleted = status == 'completed';

    // Skema warna per status
    final Color outerBorderColor;
    final List<Color> ringGradient;
    final Color innerBgColor;
    final Color numberColor;
    final Color ribbonBgColor;
    final String ribbonText;
    final IconData statusIcon;

    if (isCompleted) {
      outerBorderColor = const Color(0xFFF57F17);
      ringGradient = const [Color(0xFFFFEE58), Color(0xFFFFA000)];
      innerBgColor = const Color(0xFFFFFDE7);
      numberColor = const Color(0xFFD84315);
      ribbonBgColor = const Color(0xFF43A047);
      ribbonText = 'SELESAI';
      statusIcon = Icons.star_rounded;
    } else if (isLocked) {
      outerBorderColor = const Color(0xFF78909C);
      ringGradient = const [Color(0xFFCFD8DC), Color(0xFF90A4AE)];
      innerBgColor = const Color(0xFFECEFF1);
      numberColor = const Color(0xFF607D8B);
      ribbonBgColor = const Color(0xFF78909C);
      ribbonText = 'Terkunci';
      statusIcon = Icons.lock_rounded;
    } else {
      // Unlocked
      outerBorderColor = const Color(0xFF7E57C2);
      ringGradient = const [Color(0xFFBA68C8), Color(0xFF7E57C2)];
      innerBgColor = const Color(0xFFFFF8E1);
      numberColor = const Color(0xFFF57C00);
      ribbonBgColor = const Color(0xFF5C6BC0);
      ribbonText = 'Buka';
      statusIcon = Icons.play_arrow_rounded;
    }

    return SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Cincin Luar (Medallion Ring)
          Container(
            width: effectiveSize * 0.90,
            height: effectiveSize * 0.90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: ringGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: outerBorderColor,
                width: isTablet ? 3.5 : 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isLocked ? 0.25 : 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              // 2. Lingkaran Dalam (Inner Dial)
              child: Container(
                width: effectiveSize * 0.68,
                height: effectiveSize * 0.68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: innerBgColor,
                  border: Border.all(
                    color: outerBorderColor.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  // 3. Nomor Stage
                  child: Text(
                    '$stageNumber',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: effectiveSize * 0.36,
                      fontWeight: FontWeight.w900,
                      color: numberColor,
                      shadows: [
                        Shadow(
                          color: Colors.white.withOpacity(0.9),
                          offset: const Offset(-1, -1),
                          blurRadius: 1,
                        ),
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(1.5, 2),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. Ikon Status di bagian atas
          Positioned(
            top: -effectiveSize * 0.04,
            child: Container(
              padding: EdgeInsets.all(isTablet ? 3 : 2),
              decoration: BoxDecoration(
                color: outerBorderColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 3,
                    offset: Offset(0, 1.5),
                  ),
                ],
              ),
              child: Icon(
                statusIcon,
                size: effectiveSize * 0.20,
                color: Colors.white,
              ),
            ),
          ),

          // 5. Pita teks status di bagian bawah
          Positioned(
            bottom: -effectiveSize * 0.05,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: effectiveSize * 0.12,
                vertical: effectiveSize * 0.02,
              ),
              decoration: BoxDecoration(
                color: ribbonBgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 3,
                    offset: Offset(0, 1.5),
                  ),
                ],
              ),
              child: Text(
                ribbonText,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: effectiveSize * 0.13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
