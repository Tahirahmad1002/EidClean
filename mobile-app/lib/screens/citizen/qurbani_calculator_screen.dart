import 'package:flutter/material.dart';

class QurbaniDistribution {
  final double totalWeightKg;
  final double householdShareKg;
  final double relativesShareKg;
  final double needyShareKg;
  final String guidance;

  const QurbaniDistribution({
    required this.totalWeightKg,
    required this.householdShareKg,
    required this.relativesShareKg,
    required this.needyShareKg,
    required this.guidance,
  });
}

QurbaniDistribution calculateQurbaniDistribution({required double weightKg}) {
  if (weightKg <= 0) {
    return const QurbaniDistribution(
      totalWeightKg: 0,
      householdShareKg: 0,
      relativesShareKg: 0,
      needyShareKg: 0,
      guidance: 'Please enter a valid animal weight to calculate the shares.',
    );
  }

  final share = weightKg / 3;
  return QurbaniDistribution(
    totalWeightKg: weightKg,
    householdShareKg: share,
    relativesShareKg: share,
    needyShareKg: share,
    guidance:
        'A common Islamic guidance is to divide the meat into three equal shares: one-third for your household, one-third for relatives/friends, and one-third for the needy.',
  );
}

QurbaniDistribution calculateQurbaniRecommendation({
  required int adults,
  required int children,
  required String animalType,
}) {
  final weightKg = adults * 20 + children * 10;
  return calculateQurbaniDistribution(weightKg: weightKg.toDouble());
}

class QurbaniCalculatorScreen extends StatefulWidget {
  const QurbaniCalculatorScreen({super.key});

  @override
  State<QurbaniCalculatorScreen> createState() => _QurbaniCalculatorScreenState();
}

class _QurbaniCalculatorScreenState extends State<QurbaniCalculatorScreen> {
  final _weightController = TextEditingController(text: '30');
  QurbaniDistribution? _result;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _calculate() {
    final weight = double.tryParse(_weightController.text.trim()) ?? 0;
    setState(() {
      _result = calculateQurbaniDistribution(weightKg: weight);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Qurbani Meat Guide'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.favorite_outline, color: Color(0xFF065F46)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Estimate how the meat can be divided into three equal shares for household, relatives, and the needy.',
                        style: TextStyle(
                          color: Color(0xFF065F46),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Animal Weight (kg)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Example: 60',
                  suffixText: 'kg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Calculate Shares',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_result != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Meat Distribution',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _shareTile('Total meat weight', '${_result!.totalWeightKg.toStringAsFixed(1)} kg'),
                      _shareTile('Household share', '${_result!.householdShareKg.toStringAsFixed(1)} kg'),
                      _shareTile('Relatives share', '${_result!.relativesShareKg.toStringAsFixed(1)} kg'),
                      _shareTile('Needy share', '${_result!.needyShareKg.toStringAsFixed(1)} kg'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _result!.guidance,
                          style: const TextStyle(
                            color: Color(0xFF374151),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('NGO donation coordination will be added in the next module step.'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.handshake_outlined),
                        label: const Text('Request charity support'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF374151))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        ],
      ),
    );
  }
}