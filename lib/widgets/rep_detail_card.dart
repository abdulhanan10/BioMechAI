import 'package:flutter/material.dart';
import '../models/rep_record.dart';
import '../utils/app_theme.dart';

class RepDetailCard extends StatelessWidget {
  final RepRecord rep;

  const RepDetailCard({
    Key? key,
    required this.rep,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              '${rep.repNumber}',
              style: const TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      rep.isValid ? Icons.check_circle : Icons.cancel,
                      color: rep.isValid ? AppTheme.green : AppTheme.red,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Score: ${rep.formScore.toInt()}',
                      style: const TextStyle(color: AppTheme.text, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (!rep.isValid && rep.errorsDetected.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    rep.errorsDetected.join(', '),
                    style: const TextStyle(color: AppTheme.red, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${rep.primaryAngle.toInt()}°',
            style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
