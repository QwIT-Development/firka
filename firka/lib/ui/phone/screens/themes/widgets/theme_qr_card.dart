import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:firka/ui/phone/screens/themes/user_theme.dart';
import 'package:firka/ui/shared/dave_mascot.dart';
import 'package:firka/ui/theme/style.dart';

class ThemeQrCard extends StatelessWidget {
  final UserTheme theme;
  final String shareData;
  final double qrSize;

  const ThemeQrCard({
    super.key,
    required this.theme,
    required this.shareData,
    this.qrSize = 180,
  });

  @override
  Widget build(BuildContext context) {
    // Theme colors extracted from swatch or current active theme
    final accentColor = theme.swatch.isNotEmpty
        ? theme.swatch[0]
        : appStyle.colors.accent;
    final textColor = theme.swatch.length > 1
        ? theme.swatch[1]
        : appStyle.colors.textPrimary;
    final cardBgColor = theme.swatch.length > 2
        ? theme.swatch[2]
        : appStyle.colors.card;

    // Determine contrast: if cardBgColor is dark, use light for QR dots; if light, use dark
    final brightness = ThemeData.estimateBrightnessForColor(cardBgColor);
    final qrDotColor = brightness == Brightness.dark
        ? (textColor.computeLuminance() > 0.4 ? textColor : Colors.white)
        : (textColor.computeLuminance() < 0.6 ? textColor : Colors.black87);

    return Container(
      width: 270,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // QR Code with Dave Mascot in the Center
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: SizedBox(
              width: qrSize,
              height: qrSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  QrImageView(
                    data: shareData,
                    version: QrVersions.auto,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    size: qrSize,
                    padding: EdgeInsets.zero,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.circle,
                      color: accentColor,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: qrDotColor,
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                  // Dave Mascot Badge in center of QR
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Center(
                      child: DaveMascot(
                        width: 28,
                        height: 28,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Theme Name Label
          Text(
            theme.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Figtree',
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // https://firka.app below theme name
          Text(
            "https://firka.app",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Figtree',
              color: accentColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
