class Validators {
  static const double minHeightCm = 100;
  static const double maxHeightCm = 250;
  static const double minWeightKg = 30;
  static const double maxWeightKg = 300;
  static const int minAge = 13;
  static const int maxAge = 100;

  static String? validateHeight(String value) {
    final h = double.tryParse(value.trim());
    if (h == null) return 'Enter a valid height in cm';
    if (h < minHeightCm || h > maxHeightCm) {
      return 'Height must be between 100 and 250 cm';
    }
    return null;
  }

  static String? validateWeight(String value) {
    final w = double.tryParse(value.trim());
    if (w == null) return 'Enter a valid weight in kg';
    if (w < minWeightKg || w > maxWeightKg) {
      return 'Weight must be between 30 and 300 kg';
    }
    return null;
  }

  static String? validateAge(String value) {
    final a = int.tryParse(value.trim());
    if (a == null) return 'Enter a valid age';
    if (a < minAge || a > maxAge) {
      return 'Age must be between 13 and 100';
    }
    return null;
  }

  static String? validateBodyDetails({
    required String height,
    required String weight,
    required String age,
  }) {
    return validateHeight(height) ??
        validateWeight(weight) ??
        validateAge(age);
  }
}
