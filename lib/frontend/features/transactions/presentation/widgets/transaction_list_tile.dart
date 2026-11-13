import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import '../../../../../backend/services/currency_service.dart';
import '../../../../../backend/services/money.dart';
import '../../../../theme/krezio_theme.dart';
import '../../../../../ai/transaction_code.dart';
import '../../../../../backend/models/financial_transaction.dart';
import '../../../../widgets/krezio_components.dart';

class TransactionListTile extends StatelessWidget {
  final FinancialTransaction transaction;
  final bool isDark;
  final bool hideAmount;
  final bool grouped;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionListTile({
    super.key,
    required this.transaction,
    required this.isDark,
    this.hideAmount = false,
    this.grouped = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = KrezioPalette.of(context);

    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final amountColor = isIncome
        ? palette.income
        : isTransfer
            ? palette.accentText
            : palette.primaryText;

    final amountFormatted = hideAmount
        ? '••••'
        : transaction.isInternalTransfer
            ? Money.brl(transaction.amount)
            : isIncome
                ? '+${Money.brl(transaction.amount)}'
                : Money.brl(-transaction.amount);

    final dateStr =
        '${transaction.date.day.toString().padLeft(2, '0')}/${transaction.date.month.toString().padLeft(2, '0')}';

    return Dismissible(
      key: Key(transaction.id),
      direction: onDelete == null
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: KrezioSpace.xl),
        decoration: BoxDecoration(
          color: palette.attentionSoft,
          borderRadius: grouped ? null : KrezioTheme.borderRadius,
        ),
        child: Icon(Icons.delete_outline, color: palette.attention),
      ),
      // Swiping asks first: an accidental swipe used to delete silently.
      confirmDismiss: (_) async =>
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Apagar lançamento?'),
              content: Text('"${transaction.title}" será apagado.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Apagar')),
              ],
            ),
          ) ==
          true,
      onDismissed: (_) {
        onDelete?.call();
      },
      child: Container(
        margin: grouped ? null : const EdgeInsets.only(bottom: KrezioSpace.sm),
        padding: EdgeInsets.fromLTRB(
          KrezioSpace.md,
          KrezioSpace.sm,
          onTap != null || onDelete != null ? KrezioSpace.xs : KrezioSpace.md,
          KrezioSpace.sm,
        ),
        decoration: grouped
            ? null
            : BoxDecoration(
                color: palette.surface,
                borderRadius: KrezioTheme.borderRadius,
                border: Border.all(color: palette.border),
              ),
        child: InkWell(
          onTap: onTap,
          borderRadius: KrezioTheme.borderRadius,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: transaction.categoryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  transaction.categoryIcon,
                  color: transaction.categoryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: KrezioSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: TextStyle(
                        fontSize: KrezioFont.body,
                        fontWeight: FontWeight.w600,
                        color: palette.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: KrezioSpace.xs),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${transaction.categoryLabel} • $dateStr • ${transaction.paymentMethodLabel}'
                            '${!hideAmount && transaction.originalCurrency != null && transaction.originalAmount != null ? ' • ${Currencies.format(transaction.originalCurrency!, transaction.originalAmount!)}' : ''}'
                            '${transaction.bankSource == null ? '' : ' • ${transaction.bankSource}'}'
                            ' • ${TransactionCode.label(transaction.id)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: KrezioFont.caption,
                              color: palette.secondaryText,
                            ),
                          ),
                        ),
                        if (transaction.isRecurrent) ...[
                          const SizedBox(width: KrezioSpace.xs),
                          Icon(Icons.repeat, size: 12, color: palette.income),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KrezioSpace.sm),
              // Not Flexible: a loose Flexible next to the Expanded column
              // left a gap after the value and pushed the "⋮" to the middle.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  amountFormatted,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  semanticsLabel: hideAmount ? 'Valor oculto' : null,
                  style: TextStyle(
                    fontFamily: KrezioTheme.displayFamily,
                    fontSize: KrezioFont.body,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: amountColor,
                  ),
                ),
              ),
              if (onTap != null || onDelete != null)
                PopupMenuButton<VoidCallback>(
                  tooltip: 'Mais ações',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.more_vert, size: 20),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(32, 40),
                    padding: const EdgeInsets.only(left: KrezioSpace.xs),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onSelected: (action) => action(),
                  itemBuilder: (context) => [
                    if (onTap != null)
                      PopupMenuItem(value: onTap, child: const Text('Editar')),
                    if (onDelete != null)
                      PopupMenuItem(
                          value: onDelete, child: const Text('Apagar')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
