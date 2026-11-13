import 'package:flutter/material.dart';
import '../../../../../ai/chat_action_history.dart';
import '../../../../../backend/models/budget_category.dart';
import '../../../../../backend/repositories/financial_repository.dart';
import '../../../../../backend/services/money.dart';
import '../../../../theme/krezio_theme.dart';
import '../../../../widgets/krezio_components.dart';
import '../../../../widgets/ledger_undo.dart';

/// Status filter of the budgets list.
enum BudgetStatusFilter { all, ok, warning, over }

/// Sort order of the budgets list.
enum BudgetSort { usage, name, limit }

/// Monthly category limits for Planejar and the Extrato shortcut.
class BudgetsView extends StatefulWidget {
  final FinancialRepository repository;
  final bool isDark;
  final String? focusedCategory;

  const BudgetsView(
      {super.key,
      required this.repository,
      required this.isDark,
      this.focusedCategory});

  /// "Nova Categoria" dialog, also used by the Lançamentos app bar.
  static void showAddCategoryDialog(
      BuildContext context, FinancialRepository repository) {
    final nameController = TextEditingController();
    final limitController = TextEditingController();
    showKrezioFormDialog(
      context,
      title: 'Nova Categoria',
      confirmLabel: 'Criar',
      fields: [
        KrezioTextField(
            controller: nameController,
            label: 'Nome (ex: Pets, Presentes)',
            autofocus: true),
        KrezioMoneyField(controller: limitController, label: 'Limite mensal'),
      ],
      onConfirm: () {
        final name = nameController.text.trim();
        final limit = KrezioMoneyField.parse(limitController.text);
        if (name.isEmpty || limit == null) return false;
        final existing = repository.existingCategoryNamed(name);
        if (existing != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(
              content: Text('Essa categoria já existe: ${existing.name}')));
          return false;
        }
        repository.addBudgetCategory(name, limit);
        return true;
      },
    );
  }

  @override
  State<BudgetsView> createState() => _BudgetsViewState();
}

class _BudgetsViewState extends State<BudgetsView> {
  BudgetStatusFilter _status = BudgetStatusFilter.all;
  BudgetSort _sort = BudgetSort.usage;

  FinancialRepository get repository => widget.repository;
  static Color _levelColor(BudgetLevel level, KrezioPalette palette) =>
      switch (level) {
        BudgetLevel.ok => palette.income,
        BudgetLevel.warning => palette.warning,
        BudgetLevel.over => palette.attention,
      };

  bool _matches(BudgetCategory b) => switch (_status) {
        BudgetStatusFilter.all => true,
        BudgetStatusFilter.ok => b.level == BudgetLevel.ok,
        BudgetStatusFilter.warning => b.level == BudgetLevel.warning,
        BudgetStatusFilter.over => b.level == BudgetLevel.over,
      };

  List<BudgetCategory> _visibleBudgets() {
    final list = repository.budgets.where(_matches).toList();
    switch (_sort) {
      case BudgetSort.usage:
        list.sort((a, b) => b.percentage.compareTo(a.percentage));
        break;
      case BudgetSort.name:
        list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case BudgetSort.limit:
        list.sort((a, b) => b.monthlyLimit.compareTo(a.monthlyLimit));
        break;
    }
    // The category the user came from (dashboard) always shows first.
    final focus = widget.focusedCategory;
    if (focus != null) {
      final i = list.indexWhere((b) => b.category == focus);
      if (i > 0) list.insert(0, list.removeAt(i));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final all = repository.budgets;
    final budgets = _visibleBudgets();
    final totalBudget = all.fold(0.0, (acc, b) => acc + b.monthlyLimit);
    final totalSpent = all.fold(0.0, (acc, b) => acc + b.currentSpent);
    final overallProgress = totalBudget > 0 ? totalSpent / totalBudget : 0.0;
    final overallLevel = overallProgress >= 1
        ? BudgetLevel.over
        : overallProgress >= 0.8
            ? BudgetLevel.warning
            : BudgetLevel.ok;
    final now = DateTime.now();
    final days = DateUtils.getDaysInMonth(now.year, now.month);
    final pace = now.day / days;

    final palette = KrezioPalette.of(context);

    int count(BudgetLevel l) => all.where((b) => b.level == l).length;

    return ListView(
      primary: false,
      padding: const EdgeInsets.fromLTRB(
          KrezioSpace.lg, KrezioSpace.sm, KrezioSpace.lg, 96),
      children: [
        if (all.isEmpty)
          KrezioCard(
            padding: EdgeInsets.zero,
            child: KrezioEmptyState(
              icon: Icons.track_changes,
              title: 'Nenhum orçamento ainda',
              message: 'Defina um limite mensal para cada categoria de gasto.',
              actionLabel: 'Criar orçamento',
              onAction: () =>
                  BudgetsView.showAddCategoryDialog(context, repository),
            ),
          )
        else ...[
          // Overall Monthly Budget Hero Card
          KrezioCard(
            padding: const EdgeInsets.all(KrezioSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Teto de Gastos Mensal',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: KrezioFont.bodySmall,
                          fontWeight: FontWeight.w700,
                          color: palette.secondaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: KrezioSpace.sm),
                    Text(
                      'Dia ${now.day} de $days',
                      style: TextStyle(
                          fontSize: KrezioFont.small,
                          color: palette.secondaryText),
                    ),
                  ],
                ),
                const SizedBox(height: KrezioSpace.md),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: Money.brl(totalSpent),
                        style: TextStyle(
                          fontFamily: KrezioTheme.displayFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: palette.primaryText,
                        ),
                      ),
                      TextSpan(text: '  de ${Money.brl(totalBudget)}'),
                    ],
                  ),
                  style: TextStyle(fontSize: 13, color: palette.secondaryText),
                ),
                const SizedBox(height: KrezioSpace.md),
                _progressBar(overallProgress, pace, overallLevel, palette,
                    height: 8),
              ],
            ),
          ),
          const SizedBox(height: KrezioSpace.md),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _legendItem('Ritmo ideal hoje', palette.secondaryText, palette,
                  marker: true),
              _legendItem('Até 79%', palette.income, palette),
              _legendItem('80 a 99%', palette.warning, palette),
              _legendItem('No limite ou acima', palette.attention, palette),
            ],
          ),
          const SizedBox(height: KrezioSpace.lg),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Limites por Categoria',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: KrezioTheme.displayFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: palette.primaryText,
                  ),
                ),
              ),
              const SizedBox(width: KrezioSpace.sm),
              PopupMenuButton<BudgetSort>(
                tooltip: 'Ordenar',
                initialValue: _sort,
                onSelected: (s) => setState(() => _sort = s),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: BudgetSort.usage,
                      child: Text('Mais usados primeiro')),
                  PopupMenuItem(
                      value: BudgetSort.name, child: Text('Nome (A–Z)')),
                  PopupMenuItem(
                      value: BudgetSort.limit, child: Text('Maior limite')),
                ],
                child: SizedBox(
                  height: 44,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sort, size: 18, color: palette.secondaryText),
                      const SizedBox(width: 4),
                      Text(
                          switch (_sort) {
                            BudgetSort.usage => 'Uso',
                            BudgetSort.name => 'Nome',
                            BudgetSort.limit => 'Limite',
                          },
                          style: TextStyle(
                              fontSize: KrezioFont.small,
                              color: palette.secondaryText)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KrezioSpace.sm),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _statusTile(BudgetStatusFilter.all, 'Todos', all.length, palette),
              _statusTile(BudgetStatusFilter.ok, 'No controle',
                  count(BudgetLevel.ok), palette),
              _statusTile(BudgetStatusFilter.warning, 'Atenção',
                  count(BudgetLevel.warning), palette),
              _statusTile(BudgetStatusFilter.over, 'Estourados',
                  count(BudgetLevel.over), palette),
            ],
          ),
          const SizedBox(height: KrezioSpace.md),

          if (budgets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: KrezioSpace.xl),
              child: Text(
                'Nenhuma categoria neste filtro.',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.secondaryText),
              ),
            ),
          if (budgets.isNotEmpty)
            KrezioCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (index, budget) in budgets.indexed) ...[
                    if (index > 0) Divider(height: 1, color: palette.border),
                    _buildBudgetRow(context, budget, pace, palette),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _legendItem(String label, Color color, KrezioPalette palette,
      {bool marker = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: marker ? 2 : 14,
          height: marker ? 12 : 6,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(fontSize: 12, color: palette.secondaryText)),
      ],
    );
  }

  Widget _statusTile(BudgetStatusFilter value, String label, int count,
      KrezioPalette palette) {
    final selected = _status == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
      labelStyle: TextStyle(
          fontSize: 12,
          color: selected ? palette.accentText : palette.secondaryText),
      showCheckmark: false,
      selected: selected,
      backgroundColor: palette.surface,
      selectedColor: palette.accentSoft,
      shape: const StadiumBorder(),
      side: BorderSide(color: selected ? palette.accentBorder : palette.border),
      onSelected: (_) => setState(() => _status = value),
    );
  }

  Widget _progressBar(
    double progress,
    double pace,
    BudgetLevel level,
    KrezioPalette palette, {
    double height = 5,
  }) {
    return Semantics(
      label: '${(progress * 100).round()}% do orçamento usado. '
          'Ritmo ideal hoje ${(pace * 100).round()}%.',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: height + 4,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: height,
                  borderRadius: BorderRadius.circular(height / 2),
                  backgroundColor: palette.progressTrack,
                  color: _levelColor(level, palette),
                ),
                Positioned(
                  left: (constraints.maxWidth - 2).clamp(0.0, double.infinity) *
                      pace,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: palette.secondaryText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetRow(BuildContext context, BudgetCategory budget,
      double pace, KrezioPalette palette) {
    final progress = budget.monthlyLimit > 0
        ? budget.currentSpent / budget.monthlyLimit
        : 0.0;
    final status = budget.monthlyLimit <= 0
        ? 'Sem limite definido'
        : budget.currentSpent == 0
            ? 'Nada gasto ainda neste mês'
            : budget.statusText;
    return InkWell(
      onTap: () => _showEditBudgetDialog(context, budget),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: budget.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(budget.icon, size: 17, color: budget.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    budget.name,
                    style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                if (budget.isCustom)
                  PopupMenuButton<bool>(
                    tooltip: 'Opções da categoria',
                    onSelected: (remove) {
                      if (remove) {
                        _confirmRemoveCategory(context, budget);
                      } else {
                        _showEditBudgetDialog(context, budget);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: false, child: Text('Editar limite')),
                      PopupMenuItem(
                          value: true, child: Text('Remover categoria')),
                    ],
                    icon: Icon(Icons.more_horiz,
                        size: 20, color: palette.secondaryText),
                  )
                else
                  IconButton(
                    tooltip: 'Editar limite',
                    onPressed: () => _showEditBudgetDialog(context, budget),
                    icon:
                        Icon(Icons.chevron_right, color: palette.secondaryText),
                  ),
              ],
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: Money.brl(budget.currentSpent),
                    style: TextStyle(
                        color: palette.primaryText,
                        fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: ' / ${Money.brl(budget.monthlyLimit)}'),
                ],
              ),
              style: TextStyle(color: palette.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 8),
            _progressBar(progress, pace, budget.level, palette),
            const SizedBox(height: 6),
            Text(
              status,
              style: TextStyle(
                fontSize: 13,
                color: budget.level == BudgetLevel.ok
                    ? palette.secondaryText
                    : _levelColor(budget.level, palette),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Removing a category asks where its transactions go, so none is left
  /// without a category.
  Future<void> _confirmRemoveCategory(
      BuildContext context, BudgetCategory b) async {
    final count =
        repository.transactions.where((t) => t.category == b.category).length;
    if (count == 0) {
      _removeCategory(context, b);
      return;
    }
    final targets =
        repository.budgets.where((x) => x.category != b.category).toList();
    final moveTo = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Apagar ${b.name}?'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                KrezioSpace.xxl, 0, KrezioSpace.xxl, KrezioSpace.sm),
            child: Text(
                '$count ${count == 1 ? 'lançamento está' : 'lançamentos estão'} nesta categoria. Mover para:'),
          ),
          for (final t in targets)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t.category),
              child: Row(children: [
                Icon(t.icon, size: 18, color: t.color),
                const SizedBox(width: KrezioSpace.sm),
                Text(t.name)
              ]),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'expense_other'),
            child: const Row(children: [
              Icon(Icons.more_horiz, size: 18),
              SizedBox(width: KrezioSpace.sm),
              Text('Outras despesas')
            ]),
          ),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
        ],
      ),
    );
    if (moveTo == null || !context.mounted) return;
    _removeCategory(context, b, moveTo: moveTo);
  }

  void _removeCategory(BuildContext context, BudgetCategory budget,
      {String? moveTo}) {
    final undo = repository.deleteBudgetCategoryWithUndo(budget.category,
        moveTo: moveTo);
    if (undo == null) return;
    showLedgerUndo(
        context,
        repository,
        ChatAction.restoration((_) => undo(), 'Categoria restaurada.'),
        'Categoria apagada.');
  }

  void _showEditBudgetDialog(BuildContext context, BudgetCategory b) {
    final controller =
        TextEditingController(text: Money.groupedDecimal(b.monthlyLimit));
    final nameController = TextEditingController(text: b.name);
    showKrezioFormDialog(
      context,
      title: b.isCustom ? 'Editar Categoria' : 'Ajustar Limite: ${b.name}',
      fields: [
        if (b.isCustom)
          KrezioTextField(
            controller: nameController,
            label: 'Nome da categoria',
            textCapitalization: TextCapitalization.sentences,
          ),
        KrezioMoneyField(controller: controller, label: 'Novo Limite Mensal'),
      ],
      onConfirm: () {
        final val = KrezioMoneyField.parse(controller.text);
        if (val == null) return false;
        final newName = nameController.text.trim();
        if (b.isCustom &&
            newName != b.name &&
            !repository.renameBudgetCategory(b.category, newName)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newName.isEmpty
                  ? 'O nome da categoria não pode ficar vazio.'
                  : 'Já existe uma categoria chamada "$newName".'),
            ),
          );
          return false;
        }
        repository.setBudgetLimit(b.category, val);
        return true;
      },
    );
  }
}
