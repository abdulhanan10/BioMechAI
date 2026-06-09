import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exercise_block.dart';
import '../utils/app_theme.dart';
import 'form_score_ring.dart';

class ExerciseTimelineCard extends StatelessWidget {
  final ExerciseBlock block;

  const ExerciseTimelineCard({
    Key? key,
    required this.block,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          FormScoreRing(score: block.avgFormScore, size: 45),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      block.exerciseName,
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      DateFormat('hh:mm a').format(block.startTimestamp),
                      style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${block.totalReps} reps • ${block.weightUsed > 0 ? '${block.weightUsed} kg' : 'Bodyweight'}',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
