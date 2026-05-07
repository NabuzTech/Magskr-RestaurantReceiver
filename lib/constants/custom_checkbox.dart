import 'package:flutter/material.dart';

class CustomCheckbox extends StatefulWidget {
  final bool value;
  final Function(bool) onChanged;

  const CustomCheckbox({super.key, required this.value, required this.onChanged});

  @override
  _CustomCheckboxState createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<CustomCheckbox> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onChanged(!widget.value);
      },
      child: SizedBox(
        width: 40.0,
        height: 40.0,
        child: widget.value
            ? const SizedBox(
                width: 40,
                height: 40,
                /*child: SvgPicture.asset('assets/images/ic_tick.svg')*/)
            : null,
      ),
    );
  }
}
