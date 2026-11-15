import 'package:flutter/material.dart';

/// A dropdown menu fixes its position the moment it opens. Inside a bottom
/// sheet with the keyboard up, opening it closes the keyboard, the sheet
/// slides down, and the menu stays stuck where the button used to be.
/// So when the keyboard is open, close it first, let the sheet settle,
/// then open the menu.
class KeyboardSafeDropdown extends StatefulWidget {
  /// Build the dropdown, passing [FocusNode] as its `focusNode`.
  final Widget Function(FocusNode focusNode) builder;

  const KeyboardSafeDropdown({super.key, required this.builder});

  @override
  State<KeyboardSafeDropdown> createState() => _KeyboardSafeDropdownState();
}

class _KeyboardSafeDropdownState extends State<KeyboardSafeDropdown> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _openAfterKeyboardCloses() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final view = View.of(context);
    for (var i = 0; i < 20 && view.viewInsets.bottom > 0; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    // Let the sheet's padding animation finish before measuring the button
    await Future.delayed(const Duration(milliseconds: 150));

    final ctx = _focusNode.context;
    if (!mounted || ctx == null || !ctx.mounted) return;
    Actions.maybeInvoke(ctx, const ActivateIntent());
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Stack(
      children: [
        widget.builder(_focusNode),
        if (keyboardOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openAfterKeyboardCloses,
            ),
          ),
      ],
    );
  }
}
