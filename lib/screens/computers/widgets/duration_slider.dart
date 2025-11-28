import 'package:flutter/material.dart';
import 'package:qube/utils/date_utils.dart';

class DurationSlider extends StatelessWidget {
  final Duration value;
  final Duration max;
  final ValueChanged<Duration> onChanged;

  const DurationSlider({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const step = Duration(minutes: 30);
    final maxSteps = (max.inMinutes / step.inMinutes).floor().clamp(1, 24);
    final currentStep = (value.inMinutes / step.inMinutes).round().clamp(
      1,
      maxSteps,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Slider(
          min: 1,
          max: maxSteps.toDouble(),
          divisions: maxSteps - 1,
          value: currentStep.toDouble(),
          label: readableDuration(step * currentStep),
          onChanged: (v) => onChanged(step * v.round()),
        ),
        Center(
          child: Text(
            readableDuration(step * currentStep),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
