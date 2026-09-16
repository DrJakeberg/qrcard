import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Der QR-Code auf weissem Grund.
///
/// Weisser Hintergrund und schwarze Module sind Absicht: So erkennt ihn jeder
/// Standard-Scanner zuverlaessig, auch wenn die App im Dunkelmodus laeuft.
class QrPanel extends StatelessWidget {
  const QrPanel({
    required this.data,
    required this.size,
    this.onTap,
    super.key,
  });

  final String data;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(size * 0.05),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: QrImageView(
          data: data,
          size: size,
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          // Mittlere Fehlerkorrektur: robust beim Scannen, ohne den Code
          // unnoetig gross werden zu lassen.
          errorCorrectionLevel: QrErrorCorrectLevel.M,
          semanticsLabel: 'QR-Code mit den Kontaktdaten',
        ),
      ),
    );
  }
}
