import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class WeightInputSheet extends StatefulWidget {
  final Function(double) onSubmit;
  final String title;

  const WeightInputSheet({
    Key? key,
    required this.onSubmit,
    this.title = "Enter weight for next exercise",
  }) : super(key: key);

  @override
  State<WeightInputSheet> createState() => _WeightInputSheetState();
}

class _WeightInputSheetState extends State<WeightInputSheet> {
  final TextEditingController _controller = TextEditingController();

  void _submitBodyweight() {
    widget.onSubmit(0.0);
    Navigator.pop(context);
  }

  void _submitWeight() {
    double? weight = double.tryParse(_controller.text);
    if (weight != null) {
      widget.onSubmit(weight);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              color: AppTheme.text,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppTheme.text),
                  decoration: const InputDecoration(
                    hintText: 'Weight in kg',
                    suffixText: 'kg',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _submitWeight,
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('OR', style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _submitBodyweight,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.text,
                side: const BorderSide(color: AppTheme.border),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Bodyweight Only'),
            ),
          ),
        ],
      ),
    );
  }
}
