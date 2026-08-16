import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:majesticons_flutter/majesticons_flutter.dart";

import "package:firka/l10n/app_localizations.dart";
import "package:firka/ui/shared/firka_icon.dart";
import "package:firka/ui/theme/style.dart";
import "package:firka_common/ui/components/firka_card.dart";

Future<String?> showThemeNameSheet(
  BuildContext context,
  AppLocalizations l10n,
) {
  return _showCenteredInputSheet(
    context: context,
    l10n: l10n,
    icon: Majesticon.plusLine,
    title: l10n.s_c_themes_create_title,
    subtitle: l10n.s_c_themes_create_subtitle,
    placeholder: l10n.s_c_themes_create_placeholder,
    confirmLabel: l10n.s_c_themes_continue,
  );
}

Future<bool> showThemeDeleteSheet(
  BuildContext context,
  AppLocalizations l10n,
) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
    builder: (context) {
      return _ThemeConfirmSheet(
        icon: Majesticon.deleteBinLine,
        title: l10n.s_c_themes_delete_title,
        subtitle: l10n.s_c_themes_delete_subtitle,
        confirmLabel: l10n.s_c_themes_delete_confirm,
        cancelLabel: l10n.cancel,
        confirmColor: appStyle.colors.accent,
        onConfirm: () => context.pop(true),
        onCancel: () => context.pop(false),
      );
    },
  );
  return result ?? false;
}

Future<String?> _showCenteredInputSheet({
  required BuildContext context,
  required AppLocalizations l10n,
  required Object icon,
  required String title,
  required String subtitle,
  required String placeholder,
  required String confirmLabel,
}) {
  return showModalBottomSheet<String>(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _ThemeNameInputSheet(
          icon: icon,
          title: title,
          subtitle: subtitle,
          placeholder: placeholder,
          confirmLabel: confirmLabel,
          cancelLabel: l10n.cancel,
        ),
      );
    },
  );
}

class _ThemeNameInputSheet extends StatefulWidget {
  final Object icon;
  final String title;
  final String subtitle;
  final String placeholder;
  final String confirmLabel;
  final String cancelLabel;

  const _ThemeNameInputSheet({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.placeholder,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  @override
  State<_ThemeNameInputSheet> createState() => _ThemeNameInputSheetState();
}

class _ThemeNameInputSheetState extends State<_ThemeNameInputSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    context.pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return _ThemeSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetIcon(widget.icon),
          const SizedBox(height: 16),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: appStyle.fonts.H_H2.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: appStyle.fonts.B_16R.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: appStyle.colors.card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textAlign: TextAlign.center,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              cursorColor: appStyle.colors.accent,
              style: appStyle.fonts.B_16R.apply(
                color: appStyle.colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: appStyle.fonts.B_16R.apply(
                  color: appStyle.colors.textTertiary,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _sheetButton(
            label: widget.confirmLabel,
            color: appStyle.colors.accent,
            onTap: _submit,
          ),
          const SizedBox(height: 8),
          _sheetButton(
            label: widget.cancelLabel,
            color: appStyle.colors.buttonSecondaryFill,
            onTap: () => context.pop(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ThemeConfirmSheet extends StatelessWidget {
  final Object icon;
  final String title;
  final String subtitle;
  final String confirmLabel;
  final String cancelLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ThemeConfirmSheet({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.confirmColor,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return _ThemeSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetIcon(icon),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: appStyle.fonts.H_H2.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: appStyle.fonts.B_16R.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _sheetButton(
            label: confirmLabel,
            color: confirmColor,
            onTap: onConfirm,
          ),
          const SizedBox(height: 8),
          _sheetButton(
            label: cancelLabel,
            color: appStyle.colors.buttonSecondaryFill,
            onTap: onCancel,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ThemeSheetShell extends StatelessWidget {
  final Widget child;

  const _ThemeSheetShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => context.pop(),
            behavior: HitTestBehavior.opaque,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: BoxDecoration(
              color: appStyle.colors.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  heightFactor: 0,
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 18),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: appStyle.colors.shadowColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                child,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Widget _sheetIcon(Object icon) {
  return Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: appStyle.colors.accent.withValues(alpha: 0.25),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: appStyle.colors.accent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: FirkaIconWidget(
            FirkaIconType.majesticons,
            icon,
            size: 20,
            color: appStyle.colors.textPrimaryLight,
          ),
        ),
      ),
    ),
  );
}

Widget _sheetButton({
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return SizedBox(
    width: double.infinity,
    child: GestureDetector(
      onTap: onTap,
      child: FirkaCard(
        color: color,
        left: const [],
        center: [
          Text(
            label,
            style: appStyle.fonts.B_16SB.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}
