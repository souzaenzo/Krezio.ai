import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../../../../backend/models/financial_reminder.dart';
import '../../../../../backend/models/financial_transaction.dart';
import '../../../../../backend/repositories/financial_repository.dart';
import '../../../../../backend/services/money.dart';
import '../../../../theme/krezio_theme.dart';
import '../../../../widgets/krezio_components.dart';
import '../../../../widgets/ledger_undo.dart';
import '../../../reminders/presentation/screens/open_items_screen.dart';
import '../../../transactions/presentation/widgets/add_transaction_modal.dart';
import '../../../transactions/presentation/widgets/transaction_list_tile.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/month_summary_card.dart';
import '../widgets/spending_by_category.dart';

const _months = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

class DashboardScreen extends StatefulWidget {
  static const hideAmountsPreference = 'dashboard_hide_amounts';

  final FinancialRepository repository;
  final bool isDark;
  final VoidCallback onNavigateToChat;
  final VoidCallback onNavigateToTransactions;
  final ValueChanged<String>? onNavigateToBudgets;

  const DashboardScreen({
    super.key,
    required this.repository,
    required this.isDark,
    required this.onNavigateToChat,
    required this.onNavigateToTransactions,
    this.onNavigateToBudgets,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dismissedAlerts = <String>{};
  DateTime? _selectedMonth;
  FinancialRepository get _repository => widget.repository;

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != _repository) {
      _selectedMonth = null;
      _dismissedAlerts.clear();
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _repository,
        builder: (context, _) {
          final p = KrezioPalette.of(context);
          final now = DateTime.now();
          final currentMonth = DateTime(now.year, now.month);
          final month = _selectedMonth ?? currentMonth;
          final isCurrent = month == currentMonth;
          final monthName = _months[month.month - 1];
          final hide =
              _repository.preference(DashboardScreen.hideAmountsPreference) ==
                  'true';
          final monthTxs = _repository.transactions
              .where(
                (tx) =>
                    tx.date.year == month.year && tx.date.month == month.month,
              )
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          final income = isCurrent
              ? _repository.monthIncome
              : _repository.incomeForMonth(month.year, month.month);
          final expense = isCurrent
              ? _repository.monthExpense
              : _repository.expenseForMonth(month.year, month.month);
          final hasLedgerActivity = _repository.transactions.isNotEmpty ||
              income != 0 ||
              expense != 0;
          final alerts = isCurrent
              ? _repository
                  .getProactiveAlerts()
                  .where((a) => !_dismissedAlerts.contains(a.id))
                  .toList()
              : const <ProactiveAlert>[];

          return Scaffold(
            body: SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                children: [
                  _header(p, now, month, monthName, isCurrent, hide),
                  const SizedBox(height: 18),
                  if (isCurrent && !hasLedgerActivity) ...[
                    _gettingStarted(p),
                    const SizedBox(height: 18),
                  ] else ...[
                    MonthSummaryCard(
                      month: month,
                      now: now,
                      monthName: monthName.toLowerCase(),
                      isCurrent: isCurrent,
                      income: income,
                      expense: expense,
                      balance: isCurrent
                          ? _repository.totalBalance
                          : _historicalBalance(month),
                      pendingBills: isCurrent ? _pendingBillsThisMonth(now) : 0,
                      hideAmounts: hide,
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (alerts.isNotEmpty) ...[
                    _group(p, alerts.map((a) => _alert(p, a, hide))),
                    const SizedBox(height: 18),
                  ],
                  if (isCurrent && hasLedgerActivity) ...[
                    AiInsightCard(
                      insightText: hide
                          ? 'Valores ocultos no Início.'
                          : _repository.generateAiInsight(),
                      onAskAi: widget.onNavigateToChat,
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (isCurrent) ...[
                    ..._upcoming(p, now, hide),
                    const SizedBox(height: 18),
                  ],
                  _section(
                    p,
                    title: 'Para onde foi o dinheiro',
                    child: SpendingByCategory(
                      transactions: monthTxs,
                      categoryNames: {
                        for (final b in _repository.budgets) b.category: b.name,
                      },
                      hideAmounts: hide,
                      onCategoryPressed: widget.onNavigateToBudgets,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _section(
                    p,
                    title: 'Últimos lançamentos',
                    action: TextButton(
                      onPressed: widget.onNavigateToTransactions,
                      child: const Text('Ver extrato'),
                    ),
                    child: monthTxs.isEmpty
                        ? Text(
                            'Nenhum lançamento em ${monthName.toLowerCase()}.',
                            style:
                                TextStyle(color: p.secondaryText, fontSize: 13),
                          )
                        : _group(
                            p,
                            monthTxs.take(6).map((tx) {
                              return TransactionListTile(
                                key: ValueKey(tx.id),
                                transaction: tx,
                                isDark: widget.isDark,
                                hideAmount: hide,
                                grouped: true,
                                onDelete: () => deleteLedgerTransaction(
                                  context,
                                  _repository,
                                  tx.id,
                                ),
                                onTap: () => _editTransaction(tx),
                              );
                            }),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );

  Widget _header(
    KrezioPalette p,
    DateTime now,
    DateTime month,
    String monthName,
    bool isCurrent,
    bool hide,
  ) {
    final greeting =
        now.hour < 12 ? 'Bom dia' : (now.hour < 18 ? 'Boa tarde' : 'Boa noite');
    final monthLabel =
        month.year == now.year ? monthName : '$monthName ${month.year}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(fontSize: 13, color: p.secondaryText),
              ),
              Row(
                children: [
                  _monthButton(
                    tooltip: 'Mês anterior',
                    icon: Icons.chevron_left,
                    onPressed: () => setState(
                      () => _selectedMonth = DateTime(
                        month.year,
                        month.month - 1,
                      ),
                    ),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        monthLabel,
                        style: const TextStyle(
                          fontFamily: KrezioTheme.displayFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  _monthButton(
                    tooltip: 'Próximo mês',
                    icon: Icons.chevron_right,
                    onPressed: isCurrent
                        ? null
                        : () => setState(() {
                              final next =
                                  DateTime(month.year, month.month + 1);
                              _selectedMonth =
                                  next == DateTime(now.year, now.month)
                                      ? null
                                      : next;
                            }),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _headerAction(
          p,
          tooltip: 'Novo Lançamento',
          icon: Icons.add,
          onPressed: _editTransaction,
        ),
        const SizedBox(width: 6),
        _headerAction(
          p,
          tooltip: hide ? 'Mostrar valores' : 'Ocultar valores',
          icon:
              hide ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          onPressed: () => _repository.setPreference(
            DashboardScreen.hideAmountsPreference,
            (!hide).toString(),
            notify: true,
          ),
        ),
      ],
    );
  }

  Widget _monthButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(40),
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _headerAction(
    KrezioPalette p, {
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton.outlined(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(44),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: p.surface,
        foregroundColor: p.primaryText,
        side: BorderSide(color: p.border),
      ),
    );
  }

  Widget _gettingStarted(KrezioPalette p) => KrezioCard(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: p.accentSoft,
              foregroundColor: p.accentText,
              child: const Icon(Icons.auto_awesome_outlined),
            ),
            const SizedBox(height: 10),
            const Text('Seu mês começa aqui', style: _sectionStyle),
            const SizedBox(height: 6),
            Text(
              'Registre o primeiro gasto ou receita. Pelo César é só escrever “gastei 30 no almoço no Pix”.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: p.secondaryText),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(
                  onPressed: widget.onNavigateToChat,
                  child: const Text('Falar com o César'),
                ),
                OutlinedButton(
                  onPressed: _editTransaction,
                  child: const Text('Novo lançamento'),
                ),
              ],
            ),
          ],
        ),
      );

  static const _sectionStyle = TextStyle(
    fontFamily: KrezioTheme.displayFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  Widget _section(
    KrezioPalette p, {
    required String title,
    required Widget child,
    Widget? action,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: _sectionStyle.copyWith(color: p.primaryText),
                ),
              ),
              if (action != null) ...[const SizedBox(width: 4), action],
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _group(KrezioPalette p, Iterable<Widget> children) => KrezioCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: children.indexed
              .expand(
                (entry) => [
                  if (entry.$1 > 0)
                    Divider(height: 1, thickness: 1, color: p.border),
                  entry.$2,
                ],
              )
              .toList(),
        ),
      );

  Widget _alert(KrezioPalette p, ProactiveAlert alert, bool hide) {
    final (accent, background, icon) = switch (alert.severity) {
      ProactiveAlertSeverity.critical => (
          p.attention,
          p.attentionSoft,
          Icons.warning_amber_rounded,
        ),
      ProactiveAlertSeverity.warning => (
          p.warning,
          p.warningSoft,
          Icons.notifications_none_outlined,
        ),
      ProactiveAlertSeverity.info => (
          p.accentText,
          p.accentSoft,
          Icons.lightbulb_outline,
        ),
    };
    final (title, label) = switch (alert.target) {
      ProactiveAlertTarget.budget => ('Alerta de orçamento', 'Ver orçamento'),
      ProactiveAlertTarget.bill ||
      ProactiveAlertTarget.recurringTransaction =>
        ('Conta perto do vencimento', 'Ver conta'),
      ProactiveAlertTarget.debt => ('Pendência em atraso', 'Ver pendência'),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: background,
            foregroundColor: accent,
            child: Icon(icon, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (!hide)
                  Text(
                    alert.message,
                    style: TextStyle(fontSize: 14, color: p.secondaryText),
                  ),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: alert.target != ProactiveAlertTarget.budget ||
                          widget.onNavigateToBudgets != null
                      ? () => _openAlert(alert)
                      : null,
                  child: Text(label),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Dispensar alerta',
            onPressed: () => setState(() => _dismissedAlerts.add(alert.id)),
            icon: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }

  List<Widget> _upcoming(KrezioPalette p, DateTime now, bool hide) {
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day + 7);
    final bills = _repository
        .getUpcomingBills(
          start: start,
          end: end.subtract(const Duration(milliseconds: 1)),
        )
        .where((bill) => bill['source'] == 'transaction')
        .toList();
    final reminders = _repository.reminders;
    final due = <({DateTime date, Widget row})>[
      for (final bill in bills)
        (
          date: bill['dueDate'] as DateTime,
          row: _dueRow(
            p,
            date: bill['dueDate'] as DateTime,
            title: bill['title'] as String,
            subtitle: 'Conta a pagar',
            amount: bill['amount'] as double,
            hide: hide,
            onOpen: () => _editById(bill['id'] as String),
          ),
        ),
      for (final reminder in reminders)
        if (!reminder.isCompleted &&
            !reminder.targetDate.isBefore(start) &&
            reminder.targetDate.isBefore(end))
          (date: reminder.targetDate, row: _reminderRow(p, reminder, hide)),
    ]..sort((a, b) => a.date.compareTo(b.date));

    final visibleBillIds = bills.map((bill) => bill['id']).toSet();
    final recurrences = _repository.upcomingRecurrences.where(
      (tx) => !visibleBillIds.contains(tx.id),
    );
    final otherReminders = reminders
        .where(
          (r) =>
              r.isCompleted ||
              r.targetDate.isBefore(start) ||
              !r.targetDate.isBefore(end),
        )
        .take(4);

    return [
      _section(
        p,
        title: 'Próximos 7 dias',
        action: TextButton(
          onPressed: () => _openItems(),
          child: const Text('Ver lembretes'),
        ),
        child: due.isEmpty
            ? Text(
                'Nenhuma conta ou recebimento nos próximos 7 dias.',
                style: TextStyle(fontSize: 13, color: p.secondaryText),
              )
            : _group(p, due.map((item) => item.row)),
      ),
      if (recurrences.isNotEmpty) ...[
        const SizedBox(height: 18),
        _section(
          p,
          title: 'Contas fixas e recorrências',
          child: _group(
            p,
            recurrences.map(
              (tx) => _dueRow(
                p,
                title: tx.title,
                subtitle: tx.dueLabel,
                amount: tx.amount,
                income: tx.type == TransactionType.income,
                hide: hide,
                onOpen: () => _editTransaction(tx),
              ),
            ),
          ),
        ),
      ],
      if (otherReminders.isNotEmpty) ...[
        const SizedBox(height: 18),
        _section(
          p,
          title: 'Outros lembretes',
          child: _group(
            p,
            otherReminders.map((reminder) => _reminderRow(p, reminder, hide)),
          ),
        ),
      ],
    ];
  }

  Widget _reminderRow(KrezioPalette p, FinancialReminder reminder, bool hide) =>
      _dueRow(
        p,
        date: reminder.targetDate,
        title: reminder.title,
        subtitle: reminder.notes ?? reminder.typeLabel,
        amount: reminder.amount,
        income: reminder.isReceivable,
        hide: hide,
        completed: reminder.isCompleted,
        onOpen: () =>
            _openItems(focusId: reminder.id, debtsFirst: reminder.isReceivable),
        onComplete: () => _repository.toggleReminderCompleted(reminder.id),
      );

  Widget _dueRow(
    KrezioPalette p, {
    DateTime? date,
    required String title,
    required String subtitle,
    required double? amount,
    required bool hide,
    required VoidCallback onOpen,
    bool income = false,
    bool completed = false,
    VoidCallback? onComplete,
  }) {
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 46),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: date == null
                    ? Icon(
                        Icons.event_repeat_outlined,
                        size: 20,
                        color: p.secondaryText,
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            date.day.toString().padLeft(2, '0'),
                            style: _sectionStyle,
                          ),
                          Text(
                            _months[date.month - 1]
                                .substring(0, 3)
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: p.secondaryText,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration:
                            completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: p.secondaryText),
                    ),
                  ],
                ),
              ),
              if (amount != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      hide
                          ? '••••'
                          : '${income ? '+' : ''}${Money.brl(amount)}',
                      semanticsLabel: hide ? 'Valor oculto' : null,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: income ? p.income : p.primaryText,
                      ),
                    ),
                  ),
                ),
              ],
              if (onComplete != null)
                IconButton(
                  tooltip: completed ? 'Reabrir $title' : 'Concluir $title',
                  onPressed: onComplete,
                  icon: Icon(
                    completed ? Icons.check_circle_outline : Icons.check,
                    size: 19,
                  ),
                  color: completed ? p.income : p.secondaryText,
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _historicalBalance(DateTime month) {
    final end = DateTime(month.year, month.month + 1);
    var balance = 0.0;
    for (final tx in _repository.transactions) {
      if (!tx.date.isBefore(end) || tx.isInternalTransfer) continue;
      balance += tx.type == TransactionType.income ? tx.amount : -tx.amount;
    }
    return balance;
  }

  double _pendingBillsThisMonth(DateTime now) {
    final nextMonth = DateTime(now.year, now.month + 1);
    // Recurring transaction amounts already contribute to the monthly totals.
    return _repository.reminders
        .where(
          (item) =>
              item.type == ReminderType.billPayment &&
              !item.isCompleted &&
              item.targetDate.isBefore(nextMonth),
        )
        .fold(0.0, (sum, item) => sum + (item.amount ?? 0));
  }

  void _openAlert(ProactiveAlert alert) {
    switch (alert.target) {
      case ProactiveAlertTarget.budget:
        widget.onNavigateToBudgets?.call(alert.recordId);
      case ProactiveAlertTarget.recurringTransaction:
        _editById(alert.recordId);
      case ProactiveAlertTarget.bill:
      case ProactiveAlertTarget.debt:
        _openItems(
          focusId: alert.recordId,
          debtsFirst: alert.target == ProactiveAlertTarget.debt,
        );
    }
  }

  void _editById(String id) {
    for (final transaction in _repository.transactions) {
      if (transaction.id != id) continue;
      _editTransaction(transaction);
      return;
    }
  }

  void _openItems({String? focusId, bool debtsFirst = false}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OpenItemsScreen(
          repository: _repository,
          isDark: widget.isDark,
          focusId: focusId,
          showDebtsFirst: debtsFirst,
        ),
      ),
    );
  }

  void _editTransaction([FinancialTransaction? transaction]) {
    AddTransactionModal.show(
      context,
      _repository,
      isDark: widget.isDark,
      transaction: transaction,
    );
  }
}
