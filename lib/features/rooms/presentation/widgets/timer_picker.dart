import 'package:flutter/material.dart';

class TimerPicker extends StatelessWidget {
  final Duration selectedDuration;
  final ValueChanged<Duration> onChanged;

  const TimerPicker({
    super.key,
    required this.selectedDuration,
    required this.onChanged,
  });

  static const _options = <Duration>[
    Duration(minutes: 2),
    Duration(minutes: 3),
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 20),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Swipe Timer', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _options.map((duration) {
            final minutes = duration.inMinutes;
            final isSelected = selectedDuration == duration;
            return ChoiceChip(
              label: Text('$minutes min'),
              selected: isSelected,
              onSelected: (_) => onChanged(duration),
            );
          }).toList(),
        ),
      ],
    );
  }
}
