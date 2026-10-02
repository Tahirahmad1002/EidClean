// 📁 lib/screens/citizen/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
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
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? 'User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    user?.email ?? 'user@email.com',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+92 321 8765432',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📍 Gulberg, Lahore',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Member since May 2026',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Menu Items
            _menuItem(
              icon: Icons.favorite_border,
              title: 'Donation History',
              onTap: () {},
            ),
            _menuItem(
              icon: Icons.bookmark_border,
              title: 'Saved Guides',
              onTap: () {},
            ),
            _menuItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {},
            ),
            _menuItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {},
            ),
            _menuItem(
              icon: Icons.star_border,
              title: 'Rate App',
              onTap: () {},
            ),

            const SizedBox(height: 16),

            // Logout
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF10B981)),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}