// 📁 lib/screens/citizen/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'book_pickup_screen.dart';
import 'my_requests_screen.dart';
import 'qurbani_calculator_screen.dart';
import 'donate_screen.dart';
import 'qurbani_guide_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class CitizenHome extends StatefulWidget {
  const CitizenHome({super.key});

  @override
  State<CitizenHome> createState() => _CitizenHomeState();
}

class _CitizenHomeState extends State<CitizenHome> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _HomeContent(),
    MyRequestsScreen(),
    QurbaniCalculatorScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate),
            label: 'Calculator',
          ),
          BottomNavigationBarItem(
            icon: _NavIconWithBadge(icon: Icons.notifications_outlined),
            activeIcon: _NavIconWithBadge(icon: Icons.notifications),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _NavIconWithBadge extends StatelessWidget {
  final IconData icon;
  const _NavIconWithBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── HOME CONTENT ──────────────────────────────

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  String? _userName;
  Map<String, int> _stats = {'pending': 0, 'assigned': 0, 'completed': 0};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(auth.user!.uid)
        .get();
    setState(() {
      _userName = userDoc.data()?['name'] as String?;
    });

    final requestsSnap = await FirebaseFirestore.instance
        .collection('pickupRequests')
        .where('userId', isEqualTo: auth.user!.uid)
        .get();

    int pending = 0, assigned = 0, completed = 0;
    for (var doc in requestsSnap.docs) {
      final status = doc.data()['status'] as String? ?? '';
      if (status == 'pending') pending++;
      if (status == 'assigned') assigned++;
      if (status == 'completed') completed++;
    }

    if (mounted) {
      setState(() {
        _stats = {'pending': pending, 'assigned': assigned, 'completed': completed};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          sliver: SliverToBoxAdapter(
            child: _buildQuickActions(),
          ),
        ),
      ],
    );
  }

  // ─── HEADER ──────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16A34A), Color(0xFF15803D)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'السلام عليكم, ${_userName ?? 'Hifza'}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildCircleIconWithBadge(Icons.notifications_outlined, showBadge: true),
              const SizedBox(width: 10),
              _buildCircleIcon(Icons.person_outline),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Text(
                'Eid Mubarak! ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFBBF24),
                ),
              ),
              Text('🌙', style: TextStyle(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 20, color: Colors.grey[500]),
                const SizedBox(width: 10),
                Text(
                  'Search for pickup or guide...',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildCircleIconWithBadge(IconData icon, {bool showBadge = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildCircleIcon(icon),
        if (showBadge)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF16A34A), width: 2),
              ),
            ),
          ),
      ],
    );
  }

  // ─── QUICK ACTIONS ──────────────────────────

  Widget _buildQuickActions() {
    final actions = [
      {
        'emoji': '🐐',
        'label': 'Qurbani Guide',
        'subtitle': 'Meat Calculator',
        'colors': const [Color(0xFF22C55E), Color(0xFF15803D)],
        'screen': const QurbaniCalculatorScreen(),
      },
      {
        'icon': Icons.local_shipping,
        'label': 'Book Pickup',
        'subtitle': 'Schedule Waste Collection',
        'colors': const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        'screen': const BookPickupScreen(),
      },
      {
        'icon': Icons.favorite,
        'label': 'Donate to NGO',
        'subtitle': 'Support Verified Orgs',
        'colors': const [Color(0xFFF43F5E), Color(0xFFDC2626)],
        'screen': const DonateScreen(),
      },
      {
        'icon': Icons.menu_book,
        'label': 'Educational Guide',
        'subtitle': 'Hygiene & Islamic Rules',
        'colors': const [Color(0xFFA855F7), Color(0xFF7C3AED)],
        'screen': const QurbaniGuideScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.95,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => action['screen'] as Widget),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: action['colors'] as List<Color>,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: (action['colors'] as List<Color>)[0].withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (action['emoji'] != null)
                  Text(
                    action['emoji'] as String,
                    style: const TextStyle(fontSize: 30),
                  )
                else
                  Icon(
                    action['icon'] as IconData,
                    color: Colors.white,
                    size: 30,
                  ),
                const Spacer(),
                Text(
                  action['label'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  action['subtitle'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}