import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../navigation/krezio_routes.dart';
import '../../theme/krezio_theme.dart';
import '../../widgets/krezio_components.dart';
import '../../../backend/repositories/financial_repository.dart';
import '../../../backend/services/auth_service.dart';
import '../../../backend/services/notification_service.dart';
import '../../../ai/local_nlp_engine.dart';
import '../dashboard/presentation/screens/dashboard_screen.dart';
import '../transactions/presentation/screens/transactions_screen.dart';
import '../budgets/presentation/screens/budgets_screen.dart';
import '../settings/presentation/screens/settings_screen.dart';
import '../chat/presentation/screens/chat_screen.dart';

class MainNavigationWrapper extends StatefulWidget {
  final LocalFinancialNlpEngine engine;
  final FinancialRepository repository;
  final VoidCallback onToggleTheme;
  final bool isDark;
  final String? userEmail;
  final SignOutAction? onSignOut;
  final Future<void> Function()? onDeleteAccount;
  final Future<void> Function()? onClearData;
  final Future<void> Function()? onExportLegacy;
  final VoidCallback? onToggleDemo;
  final bool isDemo;

  /// Tab to open first (from the deep link / initial route).
  final int initialIndex;

  const MainNavigationWrapper({
    super.key,
    required this.engine,
    required this.repository,
    required this.onToggleTheme,
    required this.isDark,
    this.userEmail,
    this.onSignOut,
    this.onDeleteAccount,
    this.onClearData,
    this.onExportLegacy,
    this.onToggleDemo,
    this.isDemo = false,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  late int _currentIndex = widget.initialIndex;
  String? _focusedBudget;
  late bool _planningShowsGoals = widget.initialIndex == 3;
  int _planningJump = 0;
  int _statementJump = 0;

  @override
  void initState() {
    super.initState();
    KrezioRoutes.pendingLink.addListener(_onLink);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NotificationService(widget.repository).dispatchIfDue(context);
    });
  }

  @override
  void dispose() {
    KrezioRoutes.pendingLink.removeListener(_onLink);
    super.dispose();
  }

  /// A link opens its tab; the chat handles a sentence or the voice itself.
  void _onLink() {
    final link = KrezioRoutes.pendingLink.value;
    if (link == null) return;
    if (link.path == KrezioRoutes.metas) {
      setState(() {
        _planningShowsGoals = true;
        _focusedBudget = null;
        _planningJump++;
      });
    }
    _goTo(KrezioRoutes.tabFor(link.path));
    if (KrezioRoutes.phraseIn(link) == null && !KrezioRoutes.wantsVoice(link))
      KrezioRoutes.pendingLink.value = null;
  }

  void _goTo(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    // Keeps the browser URL in step with the tab (no-op off the web).
    SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(KrezioRoutes.tabs[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        repository: widget.repository,
        isDark: widget.isDark,
        onNavigateToChat: () => _goTo(2),
        onNavigateToTransactions: () {
          setState(() => _statementJump++);
          _goTo(1);
        },
        onNavigateToBudgets: (category) {
          setState(() {
            _planningShowsGoals = false;
            _focusedBudget = category;
            _planningJump++;
          });
          _goTo(3);
        },
      ),
      TransactionsScreen(
        key: ValueKey(('extrato', _statementJump)),
        repository: widget.repository,
        isDark: widget.isDark,
        showBudgetSwitcher: false,
      ),
      ChatScreen(
        engine: widget.engine,
        repository: widget.repository,
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDark,
      ),
      BudgetsScreen(
        key: ValueKey(('planejar', _planningJump)),
        repository: widget.repository,
        isDark: widget.isDark,
        showGoals: _planningShowsGoals,
        focusedCategory: _focusedBudget,
      ),
      SettingsScreen(
        repository: widget.repository,
        engine: widget.engine,
        isDark: widget.isDark,
        onToggleTheme: widget.onToggleTheme,
        userEmail: widget.isDemo ? null : widget.userEmail,
        onSignOut: widget.isDemo ? null : widget.onSignOut,
        onDeleteAccount: widget.isDemo ? null : widget.onDeleteAccount,
        onClearData: widget.isDemo ? null : widget.onClearData,
        onExportLegacy: widget.isDemo ? null : widget.onExportLegacy,
        onExploreDemo: widget.isDemo ? null : widget.onToggleDemo,
        isDemo: widget.isDemo,
      ),
    ];

    // Android back on any tab other than Início goes to Início instead of
    // closing the app; on Início it behaves normally (leaves the app).
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(0);
      },
      child: _AppFrame(
        child: Scaffold(
          body: Column(
            children: [
              if (widget.isDemo)
                SafeArea(
                  bottom: false,
                  child: ListTile(
                    dense: true,
                    title: const Text('Exemplo'),
                    trailing: TextButton(
                      onPressed: widget.onToggleDemo,
                      child: const Text('Sair dos exemplos'),
                    ),
                  ),
                ),
              Expanded(
                child: IndexedStack(index: _currentIndex, children: pages),
              ),
            ],
          ),
          bottomNavigationBar: _AppTabBar(
            selectedIndex: _currentIndex,
            onSelect: _goTo,
          ),
        ),
      ),
    );
  }
}

class _AppFrame extends StatelessWidget {
  final Widget child;

  const _AppFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = KrezioPalette.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final framed =
            constraints.maxWidth >= 560 && constraints.maxHeight >= 420;
        final radius = framed ? BorderRadius.circular(30) : BorderRadius.zero;
        return ColoredBox(
          color:
              palette.isDark ? KrezioColors.darkFrame : KrezioColors.lightFrame,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: framed ? 24 : 0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: KrezioTheme.contentWidth,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    boxShadow: [
                      if (framed)
                        BoxShadow(
                          color: palette.isDark
                              ? const Color(0x8C000000)
                              : const Color(0x29281850),
                          offset: const Offset(0, 18),
                          blurRadius: 48,
                        ),
                    ],
                  ),
                  child: DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: framed ? Border.all(color: palette.border) : null,
                    ),
                    child: ClipRRect(borderRadius: radius, child: child),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AppTabBar extends StatelessWidget {
  static const _tabs = [
    (label: 'Início', icon: Icons.home_outlined),
    (label: 'Extrato', icon: Icons.receipt_long_outlined),
    (label: 'César', icon: Icons.auto_awesome_outlined),
    (label: 'Planejar', icon: Icons.track_changes_outlined),
    (label: 'Ajustes', icon: Icons.settings_outlined),
  ];

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _AppTabBar({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final palette = KrezioPalette.of(context);
    return Stack(
      children: [
        Positioned.fill(
          top: 18,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border(top: BorderSide(color: palette.border)),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Material(
            type: MaterialType.transparency,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (index, tab) in _tabs.indexed)
                  Expanded(
                    child: Semantics(
                      label: tab.label,
                      button: true,
                      selected: index == selectedIndex,
                      onTap: () => onSelect(index),
                      excludeSemantics: true,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: index == 2 ? 0 : 24,
                          bottom: 4,
                        ),
                        child: InkWell(
                          onTap: () => onSelect(index),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _tabIcon(palette, index, tab.icon),
                                const SizedBox(height: 3),
                                Text(
                                  tab.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: KrezioFont.small,
                                    fontWeight: index == selectedIndex
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: index == selectedIndex
                                        ? palette.primaryText
                                        : palette.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabIcon(KrezioPalette palette, int index, IconData icon) {
    final selected = index == selectedIndex;
    if (index == 2) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.accent,
          border: Border.all(color: palette.surface, width: 4),
          boxShadow: [
            if (selected)
              BoxShadow(color: palette.accentBorder, spreadRadius: 2),
            const BoxShadow(
              color: Color(0x4D3C148C),
              offset: Offset(0, 6),
              blurRadius: 18,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      );
    }
    return Container(
      width: 58,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? palette.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: selected ? palette.accentText : palette.secondaryText,
        size: 20,
      ),
    );
  }
}
