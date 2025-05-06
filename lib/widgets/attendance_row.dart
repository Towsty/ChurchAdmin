import 'package:flutter/material.dart';

class AttendanceRow extends StatelessWidget {
  final String label;
  final int count;
  final ValueChanged<int> onChanged;

  const AttendanceRow({
    super.key,
    required this.label,
    required this.count,
    required this.onChanged,
  });

  void _adjust(int delta) {
    final newValue = count + delta;
    onChanged(newValue < 0 ? 0 : newValue);
  }

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: count.toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _adjust(-5),
                    child: const Text('-5'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _adjust(-1),
                    child: const Text('-1'),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: controller,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null) onChanged(parsed < 0 ? 0 : parsed);
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _adjust(1),
                    child: const Text('+1'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _adjust(5),
                    child: const Text('+5'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
