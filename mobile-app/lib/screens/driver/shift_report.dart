// 📁 lib/screens/driver/shift_report.dart

import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';

class ShiftReport extends StatefulWidget {
  const ShiftReport({super.key});

  @override
  State<ShiftReport> createState() => _ShiftReportState();
}

class _ShiftReportState extends State<ShiftReport> {
  int _selectedRating = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        title: const Text(
          'Shift Report',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── STATS CARDS ────────────────
            Row(
              children: [
                _statCard('3', 'Pickups', Icons.list_alt),
                const SizedBox(width: 12),
                _statCard('120', 'kg Waste', Icons.delete_outline),
                const SizedBox(width: 12),
                _statCard('4.5', 'Hours', Icons.access_time),
              ],
            ),

            const SizedBox(height: 24),

            // ─── COMPLETED PICKUPS ──────────
            const Text(
              'Completed Pickups',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),

            _pickupItem('Ahmed Khan', '3 animals • skin, bones, offal', 'Rs300'),
            _pickupItem('Fatima Ali', '1 animals • skin, bones', 'Rs300'),
            _pickupItem('Hassan Malik', '2 animals • skin, offal', 'Rs300'),

            const SizedBox(height: 24),

            // ─── RATE YOUR DAY ──────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Rate Your Day',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'How was your experience today?',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedRating = starIndex;
                          });
                        },
                        icon: Icon(
                          starIndex <= _selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: const Color(0xFFF59E0B),
                          size: 36,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRatingText(_selectedRating),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Thanks for your feedback! 🥰',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── SUBMIT BUTTON ──────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Shift report submitted successfully!'),
                      backgroundColor: Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  // Navigate to home after delay
                  Future.delayed(const Duration(seconds: 1), () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Submit Shift Report',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ─── BACK TO DASHBOARD ──────────
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Back to Dashboard',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF10B981), size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickupItem(String name, String details, String amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF10B981),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 5:
        return '🌟 Excellent!';
      case 4:
        return '👍 Good!';
      case 3:
        return '👌 Average';
      case 2:
        return '😕 Below Average';
      case 1:
        return '😞 Poor';
      default:
        return '';
    }
  }
}