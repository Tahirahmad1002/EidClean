// 📁 lib/screens/citizen/notifications_screen.dart

import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Mark all read',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _notificationItem(
            icon: Icons.check_circle,
            color: Colors.green,
            title: 'Pickup Confirmed',
            subtitle: 'Your pickup is scheduled for tomorrow at 9 AM',
            time: '2 hours ago',
          ),
          _notificationItem(
            icon: Icons.local_shipping,
            color: Colors.blue,
            title: 'Driver Assigned',
            subtitle: 'Ali has been assigned to your pickup #EID-12345',
            time: '5 hours ago',
          ),
          _notificationItem(
            icon: Icons.done_all,
            color: Colors.green,
            title: 'Pickup Completed',
            subtitle: 'Thank you for using EidClean. Your feedback helps us improve!',
            time: '1 day ago',
          ),
          _notificationItem(
            icon: Icons.favorite,
            color: Colors.red,
            title: 'Donation Accepted',
            subtitle: 'Edhi Foundation accepted your donation of 10 kg meat',
            time: '2 days ago',
          ),
          _notificationItem(
            icon: Icons.new_releases,
            color: Colors.orange,
            title: 'New Feature Available',
            subtitle: 'Check out our new Meat Calculator for better planning',
            time: '3 days ago',
          ),
        ],
      ),
    );
  }

  Widget _notificationItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String time,
  }) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}