import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../../../../backend/models/financial_transaction.dart';
import '../../../../../backend/services/money.dart';
import '../../../../widgets/krezio_components.dart';

class SpendingByCategory extends StatelessWidget {
  final List<FinancialTransaction> transactions;
  final Map<String, String> categoryNames;
  final bool hideAmounts;
  final ValueChanged<String>? onCategoryPressed;

  const SpendingByCategory({
    super.key,
    required this.transactions,
    required this.categoryNames,
    required this.hideAmounts,
    this.onCategoryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final p = KrezioPalette.of(context);
    if (hideAmounts) {
      return Text(
        'Valores do gráfico ocultos',
        style: TextStyle(fontSize: 13, color: p.secondaryText),
      );
    }

    final totals = <String, double>{};
    final samples = <String, FinancialTransaction>{};
    for (final tx in transactions.where(
      (tx) => tx.type == TransactionType.expense,
    )) {
      totals.update(
        tx.category,
        (value) => value + tx.amount,
        ifAbsent: () => tx.amount,
      );
      samples[tx.category] = tx;
    }

    final ordered = totals.entries.where((entry) => entry.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (ordered.isEmpty) {
      return Text(
        'Nenhuma despesa neste mês.',
        style: TextStyle(fontSize: 13, color: p.secondaryText),
      );
    }

    final total = ordered.fold<double>(0, (sum, entry) => sum + entry.value);
    final top = ordered.take(5);
    final remaining = ordered.skip(5);
    final rows = [
      for (final entry in top)
        (
          label: categoryNames[entry.key] ?? samples[entry.key]!.categoryLabel,
          color: samples[entry.key]!.categoryColor,
          value: entry.value,
          onPressed:
              onCategoryPressed != null && categoryNames.containsKey(entry.key)
                  ? () => onCategoryPressed!(entry.key)
                  : null,
        ),
      if (remaining.isNotEmpty)
        (
          label: 'Outras (${remaining.length})',
          color: p.secondaryText,
          value: remaining.fold<double>(0, (sum, entry) => sum + entry.value),
          onPressed: null,
        ),
    ];

    return KrezioCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          for (final row in rows)
            InkWell(
              onTap: row.onPressed,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: row.color,
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox.square(dimension: 9),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            row.label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text.rich(
                              TextSpan(
                                text: Money.brl(row.value),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        ' · ${(row.value / total * 100).round()}%',
                                    style: TextStyle(
                                      color: p.secondaryText,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    LinearProgressIndicator(
                      value: (row.value / ordered.first.value).clamp(0.02, 1.0),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                      color: row.color,
                      backgroundColor: p.progressTrack,
                      stopIndicatorRadius: 0,
                      trackGap: 0,
                      semanticsLabel: row.label,
                      semanticsValue:
                          '${(row.value / total * 100).round()}% das despesas',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
