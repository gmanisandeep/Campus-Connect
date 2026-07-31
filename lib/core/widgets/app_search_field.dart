import 'package:flutter/material.dart';

class AppSearchField extends StatefulWidget {
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
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late TextEditingController _effectiveController;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _attach(widget.controller);
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    _detach();
    _attach(widget.controller);
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  void _attach(TextEditingController? controller) {
    _ownsController = controller == null;
    _effectiveController = controller ?? TextEditingController();
    _effectiveController.addListener(_controllerChanged);
  }

  void _detach() {
    _effectiveController.removeListener(_controllerChanged);
    if (_ownsController) _effectiveController.dispose();
  }

  void _controllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _effectiveController,
    onChanged: widget.onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      labelText: widget.hint,
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: _effectiveController.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'Clear search',
              onPressed: () {
                _effectiveController.clear();
                widget.onChanged('');
              },
              icon: const Icon(Icons.close_rounded),
            ),
    ),
  );
}
