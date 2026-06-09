class FormError {
  final String type;
  final String message;
  final int severity;

  FormError({
    required this.type,
    required this.message,
    required this.severity,
  });
}

class FormResult {
  final bool valid;
  final double score;
  final List<FormError> errors;
  final String feedback;
  final double primaryAngle;

  FormResult({
    required this.valid,
    required this.score,
    required this.errors,
    required this.feedback,
    required this.primaryAngle,
  });
}
