import 'package:flutter/material.dart';
import '../../../../../ai/chat_action_history.dart';
import '../../../../../backend/services/money.dart';
import '../../../../widgets/ledger_undo.dart';
import '../../../../theme/krezio_theme.dart';
import '../../../../widgets/krezio_components.dart';
import '../../../../widgets/krezio_segmented_control.dart';
import '../../../../../backend/repositories/financial_repository.dart';
import '../../../../../backend/models/financial_goal.dart';
import '../widgets/budgets_view.dart';

/// Planning tab for monthly budgets and savings goals.
class BudgetsScreen extends StatefulWidget {
  final FinancialRepository repository;
  final bool isDark;
  final bool showGoals;
  final String? focusedCategory;

  const BudgetsScreen({
    super.key,
    required this.repository,
    required this.isDark,
    this.showGoals = false,
    this.focusedCategory,
  });

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

enum _PlanningTab { budgets, goals }

class _BudgetsScreenState extends State<BudgetsScreen> {
  FinancialRepository get repository => widget.repository;
  late _PlanningTab _tab = _requestedTab;

  _PlanningTab get _requestedTab =>
      widget.showGoals ? _PlanningTab.goals : _PlanningTab.budgets;

  @override
  void didUpdateWidget(covariant BudgetsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showGoals != widget.showGoals ||
        oldWidget.focusedCategory != widget.focusedCategory) {
      _tab = _requestedTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = KrezioPalette.of(context);
    final showGoals = _tab == _PlanningTab.goals;
    return AnimatedBuilder(
      animation: repository,
      builder: (context, _) {
        final hasEntries = showGoals
            ? repository.goals.isNotEmpty
            : repository.budgets.isNotEmpty;
        return Scaffold(
          appBar: AppBar(title: const Text('Planejar')),
          floatingActionButton: hasEntries
              ? FloatingActionButton.extended(
                  heroTag: null,
                  backgroundColor: palette.accent,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  onPressed: showGoals
                      ? () => _showAddGoalDialog(context)
                      : () => BudgetsView.showAddCategoryDialog(
                          context, repository),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(showGoals ? 'Nova meta' : 'Novo orçamento'),
                )
              : null,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: KrezioSegmentedControl<_PlanningTab>(
                  options: const {
                    _PlanningTab.budgets: 'Orçamentos',
                    _PlanningTab.goals: 'Metas'
                  },
                  selected: _tab,
                  onChanged: (tab) => setState(() => _tab = tab),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _tab.index,
                  children: [
                    BudgetsView(
                      repository: repository,
                      isDark: widget.isDark,
                      focusedCategory: widget.focusedCategory,
                    ),
                    _buildGoalsTab(context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Deleting a Cofrinho asks first (it was one tap away from the + button).
  Future<void> _removeGoal(BuildContext context, FinancialGoal goal) async {
    final ok = await showKrezioConfirmDialog(
      context,
      title: 'Apagar o cofrinho ${goal.title}?',
      message: goal.savedAmount > 0
          ? 'Ele tem ${Money.brl(goal.savedAmount)} guardados. Se quiser o dinheiro de volta no saldo, use "Resgatar" antes.'
          : 'Você pode desfazer logo em seguida.',
      confirmLabel: 'Apagar',
    );
    if (ok != true || !context.mounted) return;
    final undo = repository.deleteGoalWithUndo(goal.id);
    if (undo == null) return;
    showLedgerUndo(
      context,
      repository,
      ChatAction.restoration((_) => undo(), 'Cofrinho restaurado.'),
      'Cofrinho apagado.',
    );
  }

  // ── COFRINHOS (METAS COM DESCONTO DO SALDO LÍQUIDO COMO DESPESA) ──

  Widget _buildGoalsTab(BuildContext context) {
    final goals = repository.goals;
    final palette = KrezioPalette.of(context);
    final totalSaved =
        goals.fold<double>(0, (total, goal) => total + goal.savedAmount);
    final totalTarget =
        goals.fold<double>(0, (total, goal) => total + goal.targetAmount);

    return ListView(
      primary: false,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        if (goals.isEmpty)
          KrezioCard(
            padding: EdgeInsets.zero,
            child: KrezioEmptyState(
              icon: Icons.outlined_flag,
              title: 'Nenhuma meta ainda',
              message:
                  'Crie um cofrinho para uma viagem, uma reserva ou um sonho.',
              actionLabel: 'Criar meta',
              onAction: () => _showAddGoalDialog(context),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        '${Money.brl(totalSaved)} guardados de ${Money.brl(totalTarget)} em metas. ',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: palette.primaryText),
                  ),
                  const TextSpan(
                      text:
                          'Guardar desconta do seu saldo e resgatar devolve.'),
                ],
              ),
              style: TextStyle(fontSize: 13, color: palette.secondaryText),
            ),
          ),
          for (final (index, goal) in goals.indexed) ...[
            if (index > 0) const SizedBox(height: 12),
            _buildGoalCard(context, goal, goal.colorFor(index), palette),
          ],
        ],
      ],
    );
  }

  Widget _buildGoalCard(BuildContext context, FinancialGoal goal, Color color,
      KrezioPalette palette) {
    final monthly = goal.suggestedMonthlyContribution;
    final status = goal.isCompleted
        ? 'Meta concluída. Parabéns!'
        : monthly == null
            ? 'Faltam ${Money.brl(goal.remaining)}.'
            : 'Guarde ${Money.brl(monthly)} por mês para chegar a tempo.';
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: KrezioTheme.borderRadius,
        side: BorderSide(
          color: goal.isCompleted
              ? Color.lerp(palette.border, palette.income, 0.55)!
              : palette.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(KrezioSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    goal.isCompleted
                        ? Icons.check_circle_outline
                        : Icons.outlined_flag,
                    color: goal.isCompleted ? palette.income : color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: KrezioSpace.md),
                Expanded(
                  child: Text(
                    goal.title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: palette.primaryText),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: palette.secondaryText,
                  tooltip: 'Apagar cofrinho',
                  onPressed: () => _removeGoal(context, goal),
                ),
              ],
            ),
            const SizedBox(height: KrezioSpace.md),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: Money.brl(goal.savedAmount),
                    style: TextStyle(
                      fontFamily: KrezioTheme.displayFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: palette.primaryText,
                    ),
                  ),
                  TextSpan(
                      text:
                          '  de ${Money.brl(goal.targetAmount)} · ${(goal.progress * 100).round()}%'),
                ],
              ),
              style: TextStyle(fontSize: 13, color: palette.secondaryText),
            ),
            const SizedBox(height: KrezioSpace.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 5,
                backgroundColor: palette.progressTrack,
                color: goal.isCompleted ? palette.income : color,
                semanticsLabel: 'Progresso da meta',
              ),
            ),
            const SizedBox(height: KrezioSpace.sm),
            Text(
              status,
              style: TextStyle(
                fontSize: 13,
                color:
                    goal.isCompleted ? palette.income : palette.secondaryText,
              ),
            ),
            const SizedBox(height: KrezioSpace.md),
            Wrap(
              spacing: KrezioSpace.sm,
              runSpacing: KrezioSpace.xs,
              children: [
                FilledButton.icon(
                  onPressed: () => _showContributeDialog(context, goal),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Guardar'),
                ),
                if (goal.savedAmount > 0)
                  OutlinedButton(
                    onPressed: () => _showWithdrawDialog(context, goal),
                    child: const Text('Resgatar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showContributeDialog(BuildContext context, FinancialGoal goal) {
    final controller = TextEditingController();
    showKrezioFormDialog(
      context,
      title: 'Guardar no Cofrinho: ${goal.title}',
      confirmLabel: 'Aplicar',
      fields: [
        KrezioMoneyField(
            controller: controller,
            label: 'Valor para guardar (sai do saldo como despesa)',
            autofocus: true),
      ],
      onConfirm: () {
        final val = KrezioMoneyField.parse(controller.text);
        if (val == null) return false;
        repository.contributeToGoal(goal.id, val, recordExpense: true);
        return true;
      },
    );
  }

  void _showWithdrawDialog(BuildContext context, FinancialGoal goal) {
    final controller = TextEditingController();
    showKrezioFormDialog(
      context,
      title: 'Resgatar do Cofrinho: ${goal.title}',
      confirmLabel: 'Resgatar',
      fields: [
        KrezioMoneyField(
            controller: controller,
            label: 'Valor para devolver ao saldo',
            autofocus: true),
      ],
      onConfirm: () {
        final val = KrezioMoneyField.parse(controller.text);
        if (val == null) return false;
        repository.withdrawFromGoal(goal.id, val, recordIncome: true);
        return true;
      },
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final initialDepositController = TextEditingController();
    showKrezioFormDialog(
      context,
      title: 'Novo Cofrinho',
      confirmLabel: 'Criar Cofrinho',
      fields: [
        KrezioTextField(
            controller: titleController,
            label: 'Nome do Cofrinho (ex: Viagem, Reserva)',
            autofocus: true),
        KrezioMoneyField(
            controller: amountController, label: 'Meta do Cofrinho (R\$)'),
        KrezioMoneyField(
            controller: initialDepositController,
            label: 'Aplicação inicial opcional (sai do saldo)'),
      ],
      onConfirm: () {
        final title = titleController.text.trim();
        final amount = KrezioMoneyField.parse(amountController.text);
        final initialDeposit =
            KrezioMoneyField.parse(initialDepositController.text) ?? 0.0;
        if (title.isEmpty || amount == null) return false;
        repository.addGoal(
          FinancialGoal(
            id: 'goal-${DateTime.now().millisecondsSinceEpoch}',
            title: title,
            targetAmount: amount,
            savedAmount: initialDeposit,
            isCompleted: initialDeposit >= amount,
          ),
          recordExpense: initialDeposit > 0,
        );
        return true;
      },
    );
  }
}
