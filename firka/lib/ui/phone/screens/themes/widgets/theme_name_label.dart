import "package:flutter/material.dart";

import "package:firka/ui/theme/style.dart";

/// Plain-looking theme name that becomes an undecorated text field when tapped
/// (own themes only).
class ThemeNameLabel extends StatefulWidget {
  final String name;
  final bool editable;
  final ValueChanged<String>? onChanged;
  final TextStyle? style;

  const ThemeNameLabel({
    required this.name,
    required this.editable,
    this.onChanged,
    this.style,
    super.key,
  });

  @override
  State<ThemeNameLabel> createState() => _ThemeNameLabelState();
}

class _ThemeNameLabelState extends State<ThemeNameLabel> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _editing = false;
  late String _committed;

  @override
  void initState() {
    super.initState();
    _committed = widget.name;
    _controller = TextEditingController(text: widget.name);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant ThemeNameLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && widget.name != _committed) {
      _committed = widget.name;
      _controller.text = widget.name;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  TextStyle get _style =>
      widget.style ??
      appStyle.fonts.B_16SB.apply(color: appStyle.colors.textPrimary);

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _editing) {
      _commit();
    }
  }

  void _startEditing() {
    if (!widget.editable) return;
    setState(() {
      _editing = true;
      _controller.text = _committed;
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _commit() {
    final next = _controller.text.trim();
    final value = next.isEmpty ? _committed : next;
    _controller.text = value;
    if (value != _committed) {
      _committed = value;
      widget.onChanged?.call(value);
    }
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.editable) {
      return Text(widget.name, style: _style);
    }

    if (!_editing) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _startEditing,
        child: Text(_committed, style: _style),
      );
    }

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: _style,
      cursorColor: appStyle.colors.accent,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _commit(),
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
