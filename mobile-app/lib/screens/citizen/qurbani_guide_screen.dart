// 📁 lib/screens/citizen/qurbani_guide_screen.dart

import 'package:flutter/material.dart';

class QurbaniGuideScreen extends StatelessWidget {
  const QurbaniGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text('Qurbani Guide'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search guides...',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Video Tutorials
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.play_circle, color: Color(0xFFEF4444), size: 30),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video Tutorials',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Watch step-by-step guides',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Islamic Rules
            const Text(
              'Islamic Rules of Qurbani',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),

            _guideCard(
              title: 'Who Must Perform Qurbani?',
              content:
                  'Every adult Muslim who possesses the Nisab (minimum wealth) should perform Qurbani. This is a Wajib (obligatory) act during the days of Eid-ul-Adha.',
            ),
            _guideCard(
              title: 'Time of Qurbani',
              content:
                  'Qurbani can be performed on 10th, 11th, or 12th of Dhul Hijjah, after the Eid prayer. It\'s preferable to do it on the first day.',
            ),
            _guideCard(
              title: 'Animals Eligible for Qurbani',
              content:
                  'Goats, sheep (1 year old), cows, bulls, buffalo (2 years old), and camels (5 years old) are eligible. They must be healthy and free from defects.',
            ),
            _guideCard(
              title: 'Distribution of Meat',
              content:
                  'Divide meat into three equal parts: one-third for family, one-third for relatives and friends, and one-third for the poor and needy.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideCard({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}