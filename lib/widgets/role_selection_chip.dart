import 'package:flutter/material.dart';

class RoleSelectionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Function(bool) onSelected;

  const RoleSelectionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }
}