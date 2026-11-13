import 'package:flutter/material.dart';

import '../../../../widgets/krezio_components.dart';

class AiInsightCard extends StatelessWidget {
  final String insightText;
  final VoidCallback? onAskAi;

  const AiInsightCard({super.key, required this.insightText, this.onAskAi});

  @override
  Widget build(BuildContext context) {
    final p = KrezioPalette.of(context);
    return Material(
      color: p.accentSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.accentBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: p.accent,
              foregroundColor: Colors.white,
              child: const Icon(Icons.auto_awesome_outlined, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'César: ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: insightText),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: p.primaryText,
                    ),
                  ),
                  if (onAskAi != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: onAskAi,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.accentText,
                        side: BorderSide(color: p.accentBorder),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Conversar com o César'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
