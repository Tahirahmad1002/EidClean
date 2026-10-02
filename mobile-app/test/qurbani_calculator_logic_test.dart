import 'package:flutter_test/flutter_test.dart';
import 'package:eidclean_app/screens/citizen/qurbani_calculator_screen.dart';

void main() {
  group('Qurbani calculator logic', () {
    test('divides meat into three equal shares', () {
      final result = calculateQurbaniDistribution(weightKg: 60);

      expect(result.totalWeightKg, 60.0);
      expect(result.householdShareKg, 20.0);
      expect(result.relativesShareKg, 20.0);
      expect(result.needyShareKg, 20.0);
    });

    test('returns zero shares for invalid weight', () {
      final result = calculateQurbaniDistribution(weightKg: 0);

      expect(result.totalWeightKg, 0.0);
      expect(result.householdShareKg, 0.0);
      expect(result.relativesShareKg, 0.0);
      expect(result.needyShareKg, 0.0);
    });
  });
}
