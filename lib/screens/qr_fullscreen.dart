import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/contact_card.dart';
import '../services/vcard.dart';
import '../widgets/qr_panel.dart';

/// Grosse Ansicht des QR-Codes zum Abscannen durch das Gegenueber.
class QrFullscreenScreen extends StatelessWidget {
  const QrFullscreenScreen({required this.card, super.key});

  final ContactCard card;

  @override
  Widget build(BuildContext context) {
    final vCard = buildVCard(card);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text('Zum Scannen'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final qrSize = math.min(
              constraints.maxWidth * 0.82,
              constraints.maxHeight * 0.68,
            );

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QrPanel(data: vCard, size: qrSize),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    card.fullName.isEmpty ? 'Visitenkarte' : card.fullName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Mit der Kamera scannen - der Kontakt kann direkt '
                    'gespeichert werden.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
