import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import '../../../../theme/krezio_theme.dart';
import '../../../../widgets/krezio_components.dart';
import '../../../../../ai/cesar_text.dart';
import '../../../../../backend/repositories/financial_repository.dart';
import '../../../../../backend/models/budget_category.dart';
import '../../../../../backend/models/financial_transaction.dart';
import '../../../../../backend/services/statement_query.dart';
import '../widgets/transaction_list_tile.dart';
import '../../../../widgets/ledger_undo.dart';
import '../widgets/add_transaction_modal.dart';
import '../../../budgets/presentation/widgets/budgets_view.dart';

class TransactionsScreen extends StatefulWidget {
  final FinancialRepository repository;
  final bool isDark;

  /// Opens directly on the Orçamentos view (from the dashboard).
  final bool showBudgets;

  /// Shows the budget switch for callers outside the main tab bar.
  final bool showBudgetSwitcher;

  /// Budget category to highlight first in the Orçamentos view.
  final String? focusedBudget;

  const TransactionsScreen({
    super.key,
    required this.repository,
    required this.isDark,
    this.showBudgets = false,
    this.showBudgetSwitcher = true,
    this.focusedBudget,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  StatementFilter _filter = const StatementFilter();
  final _searchController = TextEditingController();
  late bool _showBudgets = widget.showBudgets;

  static const _payments = {
    'pix': 'Pix',
    'credit_card': 'Crédito',
    'debit_card': 'Débito',
    'cash': 'Dinheiro',
    'bank_slip': 'Boleto',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _categoryName(String code) =>
      CesarText.categoryName(code, widget.repository.budgets);

  @override
  Widget build(BuildContext context) {
    final palette = KrezioPalette.of(context);
    return AnimatedBuilder(
      animation: widget.repository,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            _showBudgets
                ? (widget.showBudgetSwitcher
                    ? 'Orçamentos da conta'
                    : 'Orçamentos')
                : (widget.showBudgetSwitcher
                    ? 'Extrato de Transações'
                    : 'Extrato'),
            style: TextStyle(
              fontFamily: KrezioTheme.displayFamily,
              fontSize: widget.showBudgetSwitcher ? 21 : 26,
              fontWeight: FontWeight.w700,
              color: palette.primaryText,
            ),
          ),
          actions: [
            if (!_showBudgets)
              IconButton(
                tooltip: 'Período: ${_periodLabel()}',
                onPressed: () => _openFilterSheet(context),
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
              ),
            Padding(
              padding: const EdgeInsets.only(right: KrezioSpace.lg),
              child: IconButton.outlined(
                tooltip: _showBudgets ? 'Nova categoria' : 'Novo lançamento',
                style: IconButton.styleFrom(
                  backgroundColor: palette.surface,
                  foregroundColor: palette.primaryText,
                  side: BorderSide(color: palette.border),
                  minimumSize: const Size.square(44),
                ),
                onPressed: _showBudgets
                    ? () => BudgetsView.showAddCategoryDialog(
                        context, widget.repository)
                    : () => AddTransactionModal.show(context, widget.repository,
                        isDark: widget.isDark),
                icon: const Icon(Icons.add_rounded, size: 22),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              if (widget.showBudgetSwitcher) _viewSwitcher(palette),
              Expanded(
                child: _showBudgets
                    ? BudgetsView(
                        repository: widget.repository,
                        isDark: widget.isDark,
                        focusedCategory: widget.focusedBudget,
                      )
                    : _buildStatement(context, palette),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewSwitcher(KrezioPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          KrezioSpace.lg, 0, KrezioSpace.lg, KrezioSpace.sm),
      child: KrezioCard(
        padding: const EdgeInsets.all(KrezioSpace.xs),
        child: Row(
          children: [
            for (final (label, isBudgets) in [
              ('Extrato', false),
              ('Orçamentos', true)
            ])
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor:
                        _showBudgets == isBudgets ? palette.accentSoft : null,
                    foregroundColor: _showBudgets == isBudgets
                        ? palette.accentText
                        : palette.secondaryText,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: () => setState(() => _showBudgets = isBudgets),
                  child: Text(label),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatement(BuildContext context, KrezioPalette palette) {
    final now = DateTime.now();
    final all = widget.repository.transactions;
    final filtered = StatementQuery.apply(all, _filter,
        now: now, categoryName: _categoryName);
    final periodTransactions =
        all.where((tx) => StatementQuery.inPeriod(tx, _filter, now)).toList();
    final days = StatementQuery.groupByDay(filtered);

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              KrezioSpace.lg, KrezioSpace.sm, KrezioSpace.lg, KrezioSpace.md),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.repository.isLoaded) ...[
                  _buildSummary(periodTransactions, palette),
                  const SizedBox(height: KrezioSpace.md),
                ],
                TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _filter = _filter.copyWith(text: value)),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou categoria',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _filter.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpar busca',
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(
                                  () => _filter = _filter.copyWith(text: ''));
                            },
                          ),
                    filled: true,
                    fillColor: palette.surface,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: palette.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: palette.accentBorder),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
                const SizedBox(height: KrezioSpace.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip(
                        _hasActiveModalFilters()
                            ? 'Filtros (${_activeFilterCount()})'
                            : 'Filtros',
                        _hasActiveModalFilters(),
                        () => _openFilterSheet(context),
                        icon: Icons.tune_rounded,
                      ),
                      ..._buildActiveFilterChips(),
                      if (!widget.showBudgetSwitcher)
                        ..._buildQuickFilters(periodTransactions),
                    ],
                  ),
                ),
                if (!_filter.isEmpty && filtered.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: KrezioSpace.sm),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: KrezioSpace.sm,
                      runSpacing: KrezioSpace.xs,
                      children: [
                        Text(
                            '${filtered.length} lançamento${filtered.length == 1 ? '' : 's'}'),
                        Text(
                            'Total: ${_signedMoney(StatementQuery.net(filtered))}'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!widget.repository.isLoaded)
          const SliverFillRemaining(child: KrezioSkeletonList())
        else if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KrezioEmptyState(
                    icon: _filter.isEmpty
                        ? Icons.receipt_long_outlined
                        : Icons.search_off,
                    title: _filter.isEmpty
                        ? 'Nenhum lançamento ainda'
                        : 'Nenhum lançamento encontrado',
                    message: _filter.isEmpty
                        ? 'Fale com o César: "gastei 50 no mercado no pix"'
                        : 'Tente outra palavra ou limpe os filtros.',
                  ),
                  if (!_filter.isEmpty)
                    TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Limpar filtros')),
                ],
              ),
            ),
          )
        else
          _buildGroupedList(days, now, palette),
      ],
    );
  }

  Widget _buildSummary(
      List<FinancialTransaction> transactions, KrezioPalette palette) {
    double income = 0;
    double expenses = 0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.income) income += tx.amount;
      if (tx.type == TransactionType.expense) expenses += tx.amount;
    }
    final net = income - expenses;
    return KrezioCard(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: KrezioSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, amount, color) in [
            ('Entradas', income, palette.income),
            ('Saídas', expenses, palette.primaryText),
            (
              'Resultado',
              net,
              net < 0 ? palette.attention : palette.primaryText
            ),
          ])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: KrezioSpace.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: KrezioFont.small,
                            color: palette.secondaryText)),
                    const SizedBox(height: KrezioSpace.xs),
                    Text(
                      CesarText.money(amount),
                      style: TextStyle(
                        color: color,
                        fontFamily: KrezioTheme.displayFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(
      List<StatementDay> days, DateTime now, KrezioPalette palette) {
    // Keep the individual transactions lazy, even if many belong to one day.
    final rows = <Object>[];
    for (final day in days) {
      rows.add(day);
      rows.addAll(day.transactions);
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          KrezioSpace.lg, 0, KrezioSpace.lg, KrezioSpace.lg),
      sliver: SliverList.builder(
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          if (row is StatementDay) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  2, index == 0 ? 0 : KrezioSpace.lg, 2, KrezioSpace.sm),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: KrezioSpace.sm,
                children: [
                  Text(
                    StatementQuery.dayHeader(row.day, now),
                    style: TextStyle(
                        fontSize: KrezioFont.body,
                        fontWeight: FontWeight.w700,
                        color: palette.primaryText),
                  ),
                  Text(
                    _signedMoney(row.total),
                    style: TextStyle(
                      fontSize: KrezioFont.body,
                      color: palette.secondaryText,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            );
          }
          final tx = row as FinancialTransaction;
          final first = rows[index - 1] is StatementDay;
          final last =
              index + 1 == rows.length || rows[index + 1] is StatementDay;
          final radius = BorderRadius.vertical(
            top: first ? const Radius.circular(18) : Radius.zero,
            bottom: last ? const Radius.circular(18) : Radius.zero,
          );
          final border = BorderSide(color: palette.border);
          return ClipRRect(
            key: ValueKey(tx.id),
            borderRadius: radius,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: first && last ? radius : null,
                border: Border(
                  top: border,
                  bottom: last ? border : BorderSide.none,
                  left: border,
                  right: border,
                ),
              ),
              child: Material(
                color: palette.surface,
                child: TransactionListTile(
                  transaction: tx,
                  isDark: widget.isDark,
                  grouped: true,
                  onDelete: () => deleteLedgerTransaction(
                      context, widget.repository, tx.id),
                  onTap: () => AddTransactionModal.show(
                    context,
                    widget.repository,
                    isDark: widget.isDark,
                    transaction: tx,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildQuickFilters(List<FinancialTransaction> transactions) {
    final options = <(String, int, bool, VoidCallback)>[
      (
        'Todos',
        transactions.length,
        _filter.type == null &&
            !_filter.onlyInstallments &&
            !_filter.onlyRecurrent,
        _clearQuickFilters
      ),
      for (final (label, type) in [
        ('Despesas', TransactionType.expense),
        ('Receitas', TransactionType.income),
        ('Transferências', TransactionType.transfer),
      ])
        (
          label,
          transactions.where((tx) => tx.type == type).length,
          _filter.type == type,
          () => _toggleType(type)
        ),
      (
        'Parceladas',
        transactions.where((tx) => (tx.installments ?? 1) > 1).length,
        _filter.onlyInstallments,
        () => setState(() => _filter =
            _filter.copyWith(onlyInstallments: !_filter.onlyInstallments)),
      ),
      (
        'Recorrentes',
        transactions.where((tx) => tx.isRecurrent).length,
        _filter.onlyRecurrent,
        () => setState(() =>
            _filter = _filter.copyWith(onlyRecurrent: !_filter.onlyRecurrent)),
      ),
    ];
    return [
      for (final (label, count, selected, onTap) in options)
        if (count > 0)
          Padding(
            padding: const EdgeInsets.only(left: KrezioSpace.sm),
            child: _chip('$label $count', selected, onTap),
          ),
    ];
  }

  void _clearQuickFilters() {
    setState(() => _filter = _filter.copyWith(
          clearType: true,
          onlyInstallments: false,
          onlyRecurrent: false,
        ));
  }

  String _signedMoney(double value) =>
      value > 0 ? '+${CesarText.money(value)}' : CesarText.money(value);

  Widget _chip(String label, bool selected, VoidCallback onTap,
      {IconData? icon}) {
    final palette = KrezioPalette.of(context);
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: KrezioFont.bodySmall,
        fontWeight: FontWeight.w600,
        color: selected ? palette.accentText : palette.primaryText,
      ),
      avatar: icon == null
          ? null
          : Icon(icon,
              size: 16,
              color: selected ? palette.accentText : palette.secondaryText),
      selected: selected,
      showCheckmark: false,
      selectedColor: palette.accentSoft,
      backgroundColor: palette.surface,
      side: BorderSide(color: selected ? palette.accentBorder : palette.border),
      shape: const StadiumBorder(),
      onSelected: (_) => onTap(),
    );
  }

  bool _hasActiveModalFilters() =>
      _filter.period != StatementPeriod.all ||
      _filter.type != null ||
      _filter.onlyInstallments ||
      _filter.onlyRecurrent ||
      _filter.category != null ||
      _filter.paymentMethod != null;

  int _activeFilterCount() {
    var count = 0;
    if (_filter.period != StatementPeriod.all) count++;
    if (_filter.type != null) count++;
    if (_filter.onlyInstallments) count++;
    if (_filter.onlyRecurrent) count++;
    if (_filter.category != null) count++;
    if (_filter.paymentMethod != null) count++;
    return count;
  }

  List<Widget> _buildActiveFilterChips() {
    final chips = <Widget>[];
    if (_filter.period != StatementPeriod.all) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: KrezioSpace.xs),
        child: _chip(
            '${_periodLabel()} ✕', true, () => _setPeriod(StatementPeriod.all)),
      ));
    }
    if (_filter.type == TransactionType.transfer) {
      chips.add(Padding(
        padding: const EdgeInsets.only(left: KrezioSpace.sm),
        child: _chip('Transferências ✕', true,
            () => _toggleType(TransactionType.transfer)),
      ));
    } else if (_filter.type == TransactionType.expense) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: KrezioSpace.xs),
        child: _chip('Despesas ✕', true,
            () => setState(() => _filter = _filter.copyWith(clearType: true))),
      ));
    } else if (_filter.type == TransactionType.income) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: KrezioSpace.xs),
        child: _chip('Receitas ✕', true,
            () => setState(() => _filter = _filter.copyWith(clearType: true))),
      ));
    }
    if (_filter.onlyInstallments) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: KrezioSpace.xs),
        child: _chip(
            'Parceladas ✕',
            true,
            () => setState(
                () => _filter = _filter.copyWith(onlyInstallments: false))),
      ));
    }
    if (_filter.onlyRecurrent) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: KrezioSpace.xs),
        child: _chip(
            'Recorrentes ✕',
            true,
            () => setState(
                () => _filter = _filter.copyWith(onlyRecurrent: false))),
      ));
    }
    if (_filter.category != null) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: KrezioSpace.xs),
        child: _chip(
            '${_categoryName(_filter.category!)} ✕',
            true,
            () => setState(
                () => _filter = _filter.copyWith(clearCategory: true))),
      ));
    }
    if (_filter.paymentMethod != null) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: KrezioSpace.xs),
        child: _chip(
            '${_payments[_filter.paymentMethod] ?? _filter.paymentMethod} ✕',
            true,
            () =>
                setState(() => _filter = _filter.copyWith(clearPayment: true))),
      ));
    }
    return chips;
  }

  String _periodLabel() {
    switch (_filter.period) {
      case StatementPeriod.all:
        return 'Todo o histórico';
      case StatementPeriod.thisMonth:
        return 'Este mês';
      case StatementPeriod.lastMonth:
        return 'Mês passado';
      case StatementPeriod.custom:
        if (_filter.from != null && _filter.to != null) {
          return '${CesarText.ddmm(_filter.from!)} – ${CesarText.ddmm(_filter.to!)}';
        }
        return 'Personalizado';
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() => _filter = const StatementFilter());
  }

  void _setPeriod(StatementPeriod p) =>
      setState(() => _filter = _filter.copyWith(period: p));

  void _toggleType(TransactionType t) =>
      setState(() => _filter = _filter.type == t
          ? _filter.copyWith(clearType: true)
          : _filter.copyWith(type: t));

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _filter.from != null && _filter.to != null
          ? DateTimeRange(start: _filter.from!, end: _filter.to!)
          : DateTimeRange(start: DateTime(now.year, now.month), end: now),
    );
    if (range == null || !mounted) return;
    setState(() => _filter = _filter.copyWith(
        period: StatementPeriod.custom, from: range.start, to: range.end));
  }

  void _openFilterSheet(BuildContext context) {
    final categories = {
      for (final b in widget.repository.budgets) b.category,
      for (final t in widget.repository.transactions) t.category,
    }.toList()
      ..sort((a, b) => _categoryName(a).compareTo(_categoryName(b)));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final secondary = widget.isDark
              ? KrezioColors.darkSecondaryText
              : KrezioColors.lightSecondaryText;

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.88),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  KrezioSpace.lg,
                  0,
                  KrezioSpace.lg,
                  MediaQuery.of(ctx).viewInsets.bottom + KrezioSpace.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filtros',
                          style: TextStyle(
                              fontSize: KrezioFont.title,
                              fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            _clearFilters();
                            setModalState(() {});
                          },
                          child: const Text('Limpar tudo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: KrezioSpace.md),

                    // Section 1: Período / Data
                    KrezioCard(
                      padding: const EdgeInsets.all(KrezioSpace.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 18, color: KrezioColors.aiPurple),
                              const SizedBox(width: 8),
                              const Text('Período',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              if (_filter.period != StatementPeriod.all)
                                Text(
                                  _periodLabel(),
                                  style: TextStyle(
                                      fontSize: KrezioFont.caption,
                                      color: secondary),
                                ),
                            ],
                          ),
                          const SizedBox(height: KrezioSpace.sm),
                          Wrap(
                            spacing: KrezioSpace.sm,
                            runSpacing: KrezioSpace.sm,
                            children: [
                              ChoiceChip(
                                label: const Text('Este mês',
                                    style:
                                        TextStyle(fontSize: KrezioFont.small)),
                                selected:
                                    _filter.period == StatementPeriod.thisMonth,
                                selectedColor: KrezioColors.aiPurple,
                                onSelected: (_) {
                                  _setPeriod(StatementPeriod.thisMonth);
                                  setModalState(() {});
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Mês passado',
                                    style:
                                        TextStyle(fontSize: KrezioFont.small)),
                                selected:
                                    _filter.period == StatementPeriod.lastMonth,
                                selectedColor: KrezioColors.aiPurple,
                                onSelected: (_) {
                                  _setPeriod(StatementPeriod.lastMonth);
                                  setModalState(() {});
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Todo o histórico',
                                    style:
                                        TextStyle(fontSize: KrezioFont.small)),
                                selected: _filter.period == StatementPeriod.all,
                                selectedColor: KrezioColors.aiPurple,
                                onSelected: (_) {
                                  _setPeriod(StatementPeriod.all);
                                  setModalState(() {});
                                },
                              ),
                              ChoiceChip(
                                avatar: const Icon(Icons.date_range, size: 14),
                                label: Text(
                                  _filter.period == StatementPeriod.custom
                                      ? _periodLabel()
                                      : 'Personalizado...',
                                  style: const TextStyle(
                                      fontSize: KrezioFont.small),
                                ),
                                selected:
                                    _filter.period == StatementPeriod.custom,
                                selectedColor: KrezioColors.aiPurple,
                                onSelected: (_) async {
                                  await _pickRange(context);
                                  if (ctx.mounted) setModalState(() {});
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: KrezioSpace.md),

                    // Section 2: Tipo de Lançamento
                    KrezioCard(
                      padding: const EdgeInsets.all(KrezioSpace.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.swap_vert_circle_outlined,
                                  size: 18, color: KrezioColors.friendlyOrange),
                              SizedBox(width: 8),
                              Text('Tipo de Lançamento',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: KrezioSpace.sm),
                          Wrap(
                            spacing: KrezioSpace.sm,
                            runSpacing: KrezioSpace.sm,
                            children: [
                              _chip('Despesas',
                                  _filter.type == TransactionType.expense, () {
                                _toggleType(TransactionType.expense);
                                setModalState(() {});
                              }),
                              _chip('Receitas',
                                  _filter.type == TransactionType.income, () {
                                _toggleType(TransactionType.income);
                                setModalState(() {});
                              }),
                              _chip('Transferências',
                                  _filter.type == TransactionType.transfer, () {
                                _toggleType(TransactionType.transfer);
                                setModalState(() {});
                              }),
                              _chip('Parceladas', _filter.onlyInstallments, () {
                                setState(() => _filter = _filter.copyWith(
                                    onlyInstallments:
                                        !_filter.onlyInstallments));
                                setModalState(() {});
                              }),
                              _chip('Recorrentes', _filter.onlyRecurrent, () {
                                setState(() => _filter = _filter.copyWith(
                                    onlyRecurrent: !_filter.onlyRecurrent));
                                setModalState(() {});
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: KrezioSpace.md),

                    // Section 3: Categorias com ícones
                    KrezioCard(
                      padding: const EdgeInsets.all(KrezioSpace.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.category_outlined,
                                  size: 18, color: KrezioColors.aiPurple),
                              const SizedBox(width: 8),
                              const Text('Categorias',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              if (_filter.category != null)
                                Text(
                                  _categoryName(_filter.category!),
                                  style: TextStyle(
                                      fontSize: KrezioFont.caption,
                                      color: secondary),
                                ),
                            ],
                          ),
                          const SizedBox(height: KrezioSpace.sm),
                          Wrap(
                            spacing: KrezioSpace.sm,
                            runSpacing: KrezioSpace.sm,
                            children: [
                              for (final c in categories)
                                ChoiceChip(
                                  avatar: Icon(
                                    BudgetCategory.getIconForCategory(c),
                                    size: 14,
                                    color: _filter.category == c
                                        ? Colors.white
                                        : BudgetCategory.getColorForCategory(c),
                                  ),
                                  label: Text(_categoryName(c),
                                      style: const TextStyle(
                                          fontSize: KrezioFont.small)),
                                  selected: _filter.category == c,
                                  selectedColor: KrezioColors.aiPurple,
                                  onSelected: (_) {
                                    setState(() => _filter = _filter.category ==
                                            c
                                        ? _filter.copyWith(clearCategory: true)
                                        : _filter.copyWith(category: c));
                                    setModalState(() {});
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: KrezioSpace.md),

                    // Section 4: Forma de Pagamento
                    KrezioCard(
                      padding: const EdgeInsets.all(KrezioSpace.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.credit_card_outlined,
                                  size: 18, color: KrezioColors.emeraldGreen),
                              SizedBox(width: 8),
                              Text('Forma de Pagamento',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: KrezioSpace.sm),
                          Wrap(
                            spacing: KrezioSpace.sm,
                            runSpacing: KrezioSpace.sm,
                            children: [
                              for (final p in _payments.entries)
                                _chip(p.value, _filter.paymentMethod == p.key,
                                    () {
                                  setState(() => _filter =
                                      _filter.paymentMethod == p.key
                                          ? _filter.copyWith(clearPayment: true)
                                          : _filter.copyWith(
                                              paymentMethod: p.key));
                                  setModalState(() {});
                                }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: KrezioSpace.lg),

                    KrezioButton(
                      label: 'Aplicar Filtros',
                      expand: true,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
