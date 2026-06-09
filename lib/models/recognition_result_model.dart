enum ExerciseCategory {
  lowerBody,
  upperBody,
  core,
  cardio,
  unknown
}

class RecognitionResult {
  final String exerciseName;
  final double confidence;
  final ExerciseCategory category;

  RecognitionResult({
    required this.exerciseName,
    required this.confidence,
    required this.category,
  });

  factory RecognitionResult.unknown() {
    return RecognitionResult(
      exerciseName: 'Unknown',
      confidence: 0.0,
      category: ExerciseCategory.unknown,
    );
  }
}
