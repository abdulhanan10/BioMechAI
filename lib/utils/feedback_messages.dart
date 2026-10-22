/// Builds the posture feedback message shown to the user after each frame.
String buildFeedback(String exercise, double score, List<String> errors) {
  if (score >= 80) {
    return "Great $exercise form! \u{1F4AA}";
  } else if (score >= 45) {
    return errors.isNotEmpty ? errors.first : "Good form";
  }
  return errors.isNotEmpty ? "Fix: ${errors.first}" : "Improve form";
}
