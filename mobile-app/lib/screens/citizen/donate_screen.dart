// 📁 lib/screens/citizen/donate_screen.dart

import 'package:flutter/material.dart';

class DonateScreen extends StatelessWidget {
  const DonateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text('Donate to NGOs'),
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
                  hintText: 'Search NGOs...',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Filter chips
            Row(
              children: [
                _filterChip('All', true),
                _filterChip('Verified', false),
                _filterChip('Near Me', false),
                _filterChip('Urgent', false),
              ],
            ),
            const SizedBox(height: 16),

            // Impact stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF0F766E)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Impact This Eid',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const Text(
                    '2,500 kg',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Meat donated to families in need',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // NGO List
            const Text(
              'Featured NGOs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),

            _ngoCard(
              name: 'Edhi Foundation',
              rating: '4.9',
              distance: '2.5 km',
              urgent: true,
              meatNeeded: '500 kg',
            ),
            _ngoCard(
              name: 'Saylani Welfare',
              rating: '4.8',
              distance: '3.2 km',
              urgent: true,
              meatNeeded: '300 kg',
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF10B981) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF10B981) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _ngoCard({
    required String name,
    required String rating,
    required String distance,
    required bool urgent,
    required String meatNeeded,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.volunteer_activism, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (urgent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Urgent',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                        const SizedBox(width: 2),
                        Text(rating, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(distance, style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Meat Needed', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(meatNeeded, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Donate Now'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}