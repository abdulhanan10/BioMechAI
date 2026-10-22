/// Number of frames kept in the landmark buffer for movement analysis.
const int kLandmarkBufferSize = 90;

/// Minimum landmark likelihood for a joint to be drawn in the skeleton overlay.
const double kMinLandmarkConfidence = 0.5;

/// Returns true when a detected landmark is reliable enough to display.
bool isLandmarkReliable(double likelihood) {
  return likelihood >= kMinLandmarkConfidence;
}
