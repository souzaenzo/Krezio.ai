import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../../../../backend/services/money.dart';
import '../../../../theme/krezio_theme.dart';
import '../../../../widgets/krezio_components.dart';

class MonthSummaryCard extends StatelessWidget {
  final DateTime month;
  final DateTime now;
  final String monthName;
  final bool isCurrent;
  final double income;
  final double expense;
  final double balance;
  final double pendingBills;
  final bool hideAmounts;

  const MonthSummaryCard({
    super.key,
    required this.month,
    required this.now,
    required this.monthName,
    required this.isCurrent,
    required this.income,
    required this.expense,
    required this.balance,
    required this.pendingBills,
    required this.hideAmounts,
  });

  @override
  Widget build(BuildContext context) {
    final p = KrezioPalette.of(context);
    final result = income - expense;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final spent = income > 0 ? expense / income : 0.0;
    final pace = now.day / days;
    final abovePace = spent > pace + 0.03;
    final negative = result < 0;

    return KrezioCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isCurrent && (!negative || hideAmounts)
                ? 'Sobra de $monthName'
                : 'Resultado de $monthName',
            style: TextStyle(color: p.secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 4),
          _amount(
            result,
            TextStyle(
              fontFamily: KrezioTheme.displayFamily,
              fontSize: 38,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.9,
              height: 1.05,
              color: negative && !hideAmounts ? p.attention : p.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _metric(p, 'Entradas', income, p.income)),
              const SizedBox(width: 12),
              Expanded(child: _metric(p, 'Saídas', expense, p.primaryText)),
            ],
          ),
          if (isCurrent && income > 0 && !hideAmounts) ...[
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 2,
              children: [
                Text(
                  '${(spent * 100).round()}% do que entrou já foi gasto',
                  style: TextStyle(fontSize: 13, color: p.secondaryText),
                ),
                Text(
                  'dia ${now.day} de $days',
                  style: TextStyle(fontSize: 13, color: p.secondaryText),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Semantics(
              label:
                  '${(spent * 100).round()}% gasto, ritmo ideal para hoje ${(pace * 100).round()}%',
              child: LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  height: 18,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      LinearProgressIndicator(
                        value: spent.clamp(0.0, 1.0),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                        color: abovePace
                            ? KrezioColors.budgetWarning
                            : KrezioColors.budgetOk,
                        backgroundColor: p.progressTrack,
                        stopIndicatorRadius: 0,
                        trackGap: 0,
                        semanticsLabel: '',
                      ),
                      Positioned(
                        left: (constraints.maxWidth * pace - 1).clamp(
                          0.0,
                          constraints.maxWidth > 2
                              ? constraints.maxWidth - 2
                              : 0.0,
                        ),
                        child: Container(
                          width: 2,
                          height: 18,
                          decoration: BoxDecoration(
                            color: p.primaryText,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'A marca mostra o ritmo ideal para hoje (${(pace * 100).round()}%).',
              style: TextStyle(fontSize: 12, color: p.secondaryText),
            ),
          ],
          if (!hideAmounts) ...[
            const SizedBox(height: 16),
            _guidance(p, result, days),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: p.border),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  isCurrent
                      ? 'Saldo acumulado'
                      : 'Saldo dos lançamentos até o mês',
                  style: TextStyle(fontSize: 14, color: p.secondaryText),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _amount(
                  balance,
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  end: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(KrezioPalette p, String label, double value, Color color) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: p.secondaryText)),
          const SizedBox(height: 2),
          _amount(
            value,
            TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: hideAmounts ? p.primaryText : color,
            ),
          ),
        ],
      );

  Widget _amount(double value, TextStyle style, {bool end = false}) =>
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: end ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          hideAmounts ? '••••' : Money.brl(value),
          semanticsLabel: hideAmounts ? 'Valor oculto' : null,
          style: style.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );

  Widget _guidance(KrezioPalette p, double result, int days) {
    final available = isCurrent ? result - pendingBills : result;
    final negative = available < 0;
    final message = switch ((isCurrent, income > 0, negative)) {
      (false, _, true) => 'O mês fechou no vermelho em ${Money.brl(-result)}.',
      (false, _, false) =>
        'O mês fechou com resultado de ${Money.brl(result)}.',
      (true, false, _) =>
        'Registre o que entrou no mês para acompanhar o ritmo dos seus gastos.',
      (true, true, true) =>
        'As saídas e contas em aberto passam do que entrou em ${Money.brl(-available)}.',
      (true, true, false) =>
        'Estimativa de ${Money.brl(available / (days - now.day + 1))} por dia até o fim do mês'
            '${pendingBills > 0 ? ', separando ${Money.brl(pendingBills)} para contas em aberto' : ''}.',
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: negative ? p.attentionSoft : p.accentSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              negative ? Icons.speed_outlined : Icons.auto_awesome_outlined,
              color: negative ? p.attention : p.accentText,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 14, color: p.primaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
