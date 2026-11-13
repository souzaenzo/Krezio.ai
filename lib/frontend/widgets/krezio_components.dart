import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../backend/services/money.dart';
import '../theme/krezio_theme.dart';

/// Shared building blocks for every screen: buttons, fields, cards, dialogs and
/// the empty / loading / error states. Colors come from the active theme's
/// brightness, so callers never pass `isDark` around.
class KrezioPalette {
  final bool isDark;
  const KrezioPalette._(this.isDark);

  factory KrezioPalette.of(BuildContext context) =>
      KrezioPalette._(Theme.of(context).brightness == Brightness.dark);

  Color get background =>
      isDark ? KrezioColors.darkBackground : KrezioColors.lightBackground;
  Color get surface =>
      isDark ? KrezioColors.darkSurface : KrezioColors.lightSurface;
  Color get surfaceVariant => isDark
      ? KrezioColors.darkSurfaceVariant
      : KrezioColors.lightSurfaceVariant;
  Color get primaryText =>
      isDark ? KrezioColors.darkPrimaryText : KrezioColors.lightPrimaryText;
  Color get secondaryText =>
      isDark ? KrezioColors.darkSecondaryText : KrezioColors.lightSecondaryText;
  Color get border =>
      isDark ? KrezioColors.darkBorder : KrezioColors.lightBorder;
  Color get borderStrong =>
      isDark ? KrezioColors.darkBorderStrong : KrezioColors.lightBorderStrong;
  Color get accent =>
      isDark ? KrezioColors.aiPurpleDark : KrezioColors.aiPurple;
  Color get accentText =>
      isDark ? KrezioColors.aiPurpleLight : KrezioColors.aiPurple;
  Color get accentSoft =>
      isDark ? KrezioColors.darkAccentSoft : KrezioColors.lightAccentSoft;
  Color get accentBorder =>
      isDark ? KrezioColors.darkAccentBorder : KrezioColors.lightAccentBorder;
  Color get income =>
      isDark ? KrezioColors.emeraldGreenLight : KrezioColors.emeraldGreen;
  Color get attention =>
      isDark ? KrezioColors.friendlyOrangeLight : KrezioColors.friendlyOrange;
  Color get attentionSoft =>
      isDark ? KrezioColors.darkAttentionSoft : KrezioColors.lightAttentionSoft;
  Color get warning =>
      isDark ? KrezioColors.darkWarning : KrezioColors.lightWarning;
  Color get warningSoft =>
      isDark ? KrezioColors.darkWarningSoft : KrezioColors.lightWarningSoft;
  Color get progressTrack =>
      isDark ? KrezioColors.darkTrack : KrezioColors.lightTrack;
}

// ── Buttons ─────────────────────────────────────────────────────────────────

enum KrezioButtonKind { primary, secondary, danger }

class KrezioButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final KrezioButtonKind kind;
  final IconData? icon;
  final bool loading;
  final bool expand;

  const KrezioButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = KrezioButtonKind.primary,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  const KrezioButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  }) : kind = KrezioButtonKind.secondary;

  const KrezioButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  }) : kind = KrezioButtonKind.danger;

  @override
  Widget build(BuildContext context) {
    final palette = KrezioPalette.of(context);
    final enabled = onPressed != null && !loading;
    final danger = kind == KrezioButtonKind.danger;
    final foreground = danger
        ? palette.attention
        : kind == KrezioButtonKind.secondary
            ? palette.primaryText
            : Colors.white;
    final child = loading
        ? SizedBox(
            width: KrezioSpace.lg,
            height: KrezioSpace.lg,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: KrezioFont.title),
                const SizedBox(width: KrezioSpace.sm),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: KrezioFont.body,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );

    const shape = RoundedRectangleBorder(borderRadius: KrezioTheme.inputRadius);
    const padding = EdgeInsets.symmetric(
      horizontal: KrezioSpace.lg,
      vertical: KrezioSpace.md,
    );
    final minimumSize = Size(44, expand ? 52 : 44);
    final Widget button = kind != KrezioButtonKind.primary
        ? OutlinedButton(
            onPressed: enabled ? onPressed : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: foreground,
              backgroundColor: danger ? palette.attentionSoft : null,
              side: BorderSide(
                color: danger ? palette.attention : palette.borderStrong,
              ),
              shape: shape,
              padding: padding,
              minimumSize: minimumSize,
            ),
            child: child,
          )
        : ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: foreground,
              shape: shape,
              padding: padding,
              elevation: 0,
              minimumSize: minimumSize,
            ),
            child: child,
          );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

// ── Fields ──────────────────────────────────────────────────────────────────

class KrezioTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? errorText;
  final bool autofocus;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const KrezioTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.autofocus = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final formSubmit = _KrezioFormSubmitScope.maybeOf(context);
    return TextField(
      controller: controller,
      autofocus: autofocus,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction ?? TextInputAction.done,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      onSubmitted:
          onSubmitted ?? (formSubmit != null ? (_) => formSubmit() : null),
      style: const TextStyle(fontSize: KrezioFont.bodyLarge),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// Money input in reais: numeric keyboard, "R$ " prefix and only digits plus one
/// decimal separator. Read the value with [KrezioMoneyField.parse].
class KrezioMoneyField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? errorText;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const KrezioMoneyField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
  });

  /// "1.234,56" → 1234.56 · "4000" → 4000.00 · "12,5" → 12.5 · invalid or ≤ 0 → null.
  static double? parse(String text) {
    final v = Money.parse(text);
    return (v == null || !v.isFinite || v <= 0) ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    final formSubmit = _KrezioFormSubmitScope.maybeOf(context);
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: textInputAction ?? TextInputAction.done,
      onSubmitted:
          onSubmitted ?? (formSubmit != null ? (_) => formSubmit() : null),
      inputFormatters: const [BrlCurrencyInputFormatter()],
      style: const TextStyle(fontSize: KrezioFont.bodyLarge),
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'R\$ ',
        hintText: '0,00',
        errorText: errorText,
      ),
    );
  }
}

class _KrezioFormSubmitScope extends InheritedWidget {
  final VoidCallback onSubmit;

  const _KrezioFormSubmitScope({required this.onSubmit, required super.child});

  static VoidCallback? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_KrezioFormSubmitScope>()
        ?.onSubmit;
  }

  @override
  bool updateShouldNotify(_KrezioFormSubmitScope oldWidget) =>
      onSubmit != oldWidget.onSubmit;
}

// ── Card ────────────────────────────────────────────────────────────────────

class KrezioCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const KrezioCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(KrezioSpace.lg),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = KrezioPalette.of(context);
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: KrezioTheme.borderRadius,
        side: BorderSide(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

// ── Dialogs ─────────────────────────────────────────────────────────────────

/// Yes/no confirmation. Resolves to `true` only when the user confirms.
Future<bool> showKrezioConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () =>
            Navigator.of(ctx).pop(true),
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
            Navigator.of(ctx).pop(true),
      },
      child: Focus(
        autofocus: true,
        child: AlertDialog(
          scrollable: true,
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(cancelLabel),
            ),
            danger
                ? KrezioButton.danger(
                    label: confirmLabel,
                    onPressed: () => Navigator.of(ctx).pop(true),
                  )
                : KrezioButton(
                    label: confirmLabel,
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

/// Small form in a bottom sheet. [onConfirm] returns `true` when the input
/// is valid and the sheet can close.
Future<void> showKrezioFormDialog(
  BuildContext context, {
  required String title,
  required List<Widget> fields,
  required bool Function() onConfirm,
  String confirmLabel = 'Salvar',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: KrezioTheme.contentWidth),
    builder: (ctx) {
      void submit() {
        if (onConfirm()) Navigator.of(ctx).pop();
      }

      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter): submit,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): submit,
        },
        child: _KrezioFormSubmitScope(
          onSubmit: submit,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(ctx).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fechar',
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    for (final field in fields) ...[
                      const SizedBox(height: KrezioSpace.md),
                      field,
                    ],
                    const SizedBox(height: KrezioSpace.lg),
                    KrezioButton(
                      label: confirmLabel,
                      onPressed: submit,
                      expand: true,
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

// ── Empty / loading / error states ──────────────────────────────────────────

class KrezioEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  const KrezioEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = KrezioPalette.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? KrezioSpace.lg : KrezioSpace.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: compact ? 32 : 48,
              color: p.secondaryText.withValues(alpha: 0.6),
            ),
            const SizedBox(height: KrezioSpace.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: KrezioFont.bodyLarge,
                fontWeight: FontWeight.bold,
                color: p.primaryText,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: KrezioSpace.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: KrezioFont.small,
                  color: p.secondaryText,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: KrezioSpace.lg),
              KrezioButton.secondary(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// Placeholder rows shown while a list loads.
class KrezioSkeletonList extends StatefulWidget {
  final int rows;
  const KrezioSkeletonList({super.key, this.rows = 6});

  @override
  State<KrezioSkeletonList> createState() => _KrezioSkeletonListState();
}

class _KrezioSkeletonListState extends State<KrezioSkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = KrezioPalette.of(context);
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: p.border,
            borderRadius: BorderRadius.circular(KrezioSpace.xs),
          ),
        );
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_pulse),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(KrezioSpace.lg),
        itemCount: widget.rows,
        separatorBuilder: (_, __) => const SizedBox(height: KrezioSpace.lg),
        itemBuilder: (_, __) => Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.border,
                borderRadius: BorderRadius.circular(KrezioSpace.md),
              ),
            ),
            const SizedBox(width: KrezioSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(160, KrezioSpace.md),
                  const SizedBox(height: KrezioSpace.sm),
                  bar(100, KrezioSpace.sm),
                ],
              ),
            ),
            bar(60, KrezioSpace.md),
          ],
        ),
      ),
    );
  }
}

class KrezioErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const KrezioErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return KrezioEmptyState(
      icon: Icons.error_outline,
      title: 'Algo deu errado',
      message: message,
      actionLabel: onRetry == null ? null : 'Tentar de novo',
      onAction: onRetry,
    );
  }
}

// ── Splash ──────────────────────────────────────────────────────────────────

/// Shown while the César engine and the saved data load. Brand mark only, no
/// small text (criterion of card 1.2).
class KrezioSplash extends StatelessWidget {
  const KrezioSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KrezioPalette.of(context).background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(KrezioSpace.xl),
              decoration: BoxDecoration(
                color: KrezioColors.aiPurple.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: KrezioColors.aiPurple,
                size: 48,
              ),
            ),
            const SizedBox(height: KrezioSpace.xxl),
            const Text(
              'Krezio.ai',
              style: TextStyle(
                fontSize: KrezioFont.headline,
                fontWeight: FontWeight.bold,
                color: KrezioColors.aiPurple,
              ),
            ),
            const SizedBox(height: KrezioSpace.xxl),
            const SizedBox(
              width: KrezioSpace.xxl,
              height: KrezioSpace.xxl,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: KrezioColors.aiPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
