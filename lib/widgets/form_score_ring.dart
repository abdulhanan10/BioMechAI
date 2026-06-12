import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class FormScoreRing extends StatelessWidget {
  final double score;
  final double size;

  const FormScoreRing({
    Key? key,
    required this.score,
    this.size = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color ringColor;
    if (score >= 86) {
      ringColor = AppTheme.green;
    } else if (score >= 60) {
      ringColor = AppTheme.yellow;
    } else {
      ringColor = AppTheme.red;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100,
              color: ringColor,
              backgroundColor: AppTheme.border,
              strokeWidth: size * 0.1,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${score.toInt()}',
              style: TextStyle(
                color: ringColor,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
