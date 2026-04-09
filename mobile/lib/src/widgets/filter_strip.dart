import 'package:flutter/material.dart';

class FilterOption {
  const FilterOption({required this.label, required this.value});

  final String label;
  final String? value;
}

class FilterStrip extends StatelessWidget {
  const FilterStrip({
    super.key,
    required this.label,
    required this.currentValue,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? currentValue;
  final List<FilterOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return ChoiceChip(
              label: Text(option.label),
              selected: currentValue == option.value,
              onSelected: (_) => onChanged(option.value),
            );
          }).toList(),
        ),
      ],
    );
  }
}
