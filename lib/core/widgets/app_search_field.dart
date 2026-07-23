import 'package:flutter/material.dart';

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    required this.hint,
    required this.onChanged,
    this.controller,
    super.key,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      labelText: hint,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: IconButton(
        tooltip: 'Clear search',
        onPressed: () {
          controller?.clear();
          onChanged('');
        },
        icon: const Icon(Icons.clear),
      ),
    ),
  );
}
