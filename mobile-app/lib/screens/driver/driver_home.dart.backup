// 📁 lib/screens/driver/driver_home.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'driver_task_detail.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: _currentIndex == 0
          ? const _DashboardTab()
          : const _ProfileTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── DASHBOARD TAB ──────────────────────────

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  String _filter = 'all';
  bool _isRouteOptimized = false;
  String? _driverName;

  @override
  void initState() {
    super.initState();
    _loadDriverName();
  }

  Future<void> _loadDriverName() async {
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(auth.user!.uid)
            .get();
        setState(() {
          _driverName = doc.data()?['name'] as String?;
        });
      } catch (e) {
        print('Error loading driver name: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${_driverName ?? 'Driver'} 👋',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              '📅 ${_getFormattedDate()}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: Colors.grey[600],
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── STATS CARDS ──────────────────
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pickupRequests')
                    .where('driverId', isEqualTo: auth.user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildStatsPlaceholder();
                  }

                  final docs = snapshot.data!.docs;
                  final total = docs.length;
                  final done = docs.where((d) =>
                      (d.data() as Map)['status'] == 'completed').length;

                  return Row(
                    children: [
                      _statCard('Total', '$total', Icons.list_alt, const Color(0xFF6366F1)),
                      const SizedBox(width: 12),
                      _statCard('Done', '$done', Icons.check_circle, const Color(0xFF10B981)),
                      const SizedBox(width: 12),
                      _statCard('Earned', 'Rating', Icons.rate_review_rounded, const Color(0xFFF59E0B)),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // ─── AI ROUTE OPTIMIZATION ────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF10B981), Color(0xFF0F766E)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.route, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'AI Route Optimization',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        if (_isRouteOptimized)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '✅ Optimized',
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Get the fastest route for all pickups today',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _generateRoute,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F766E),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Generate Optimized Route',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withOpacity(0.7),
                          ),
                          child: const Text('Skip'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── TODAY'S TASKS ────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Tasks Details",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  _buildFilterChips(),
                ],
              ),
              const SizedBox(height: 12),

              // ─── TASK LIST ────────────────────
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pickupRequests')
                    .where('driverId', isEqualTo: auth.user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF10B981),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading tasks: ${snapshot.error}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  // ─── FILTER ──────────────────
                  var filteredDocs = docs;
                  if (_filter == 'assigned') {
                    filteredDocs = docs.where((d) {
                      final status = (d.data() as Map)['status'] ?? '';
                      return status == 'assigned' || status == 'arrived';
                    }).toList();
                  } else if (_filter == 'completed') {
                    filteredDocs = docs.where((d) {
                      final status = (d.data() as Map)['status'] ?? '';
                      return status == 'completed';
                    }).toList();
                  }

                  // ─── SORT: PENDING FIRST ────
                  filteredDocs = filteredDocs.toList()..sort((a, b) {
                    final statusA = (a.data() as Map)['status'] ?? '';
                    final statusB = (b.data() as Map)['status'] ?? '';
                    
                    int getPriority(String status) {
                      if (status == 'assigned') return 0;
                      if (status == 'arrived') return 1;
                      if (status == 'completed') return 2;
                      return 3;
                    }
                    
                    return getPriority(statusA).compareTo(getPriority(statusB));
                  });

                  if (filteredDocs.isEmpty) {
                    String message = 'No tasks';
                    if (_filter == 'assigned') message = 'No pending tasks';
                    if (_filter == 'completed') message = 'No completed tasks';
                    
                    return Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          const Text('📋', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 8),
                          Text(
                            message,
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: filteredDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['status'] ?? 'pending';
                      final isCompleted = status == 'completed';

                      return _buildTaskCard(
                        docId: doc.id,
                        data: data,
                        isCompleted: isCompleted,
                        priority: _getPriority(data),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── STAT CARD ─────────────────────────────

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
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
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TASK CARD ─────────────────────────────

  Widget _buildTaskCard({
    required String docId,
    required Map<String, dynamic> data,
    required bool isCompleted,
    required int priority,
  }) {
    final location = data['location'] ?? 'No location';
    final userName = data['userName'] ?? 'Customer';
    final animals = data['animals'] ?? 1;
    final wasteType = data['wasteType'] ?? 'mixed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCompleted
            ? Border.all(color: const Color(0xFF10B981).withOpacity(0.3))
            : null,
        boxShadow: isCompleted
            ? null
            : [
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
          // Row: Priority + Status + Distance/ETA
          Row(
  children: [
    // Priority Badge
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getPriorityColor(priority),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'P$priority',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    ),
    const SizedBox(width: 8),
    // Status Dot
    Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
        shape: BoxShape.circle,
      ),
    ),
    const SizedBox(width: 6),
    // Status Text
    Text(
      isCompleted ? 'Completed' : 'Tap to view details',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[500],
      ),
    ),
    const Spacer(),
    // Time slot instead of random ETA
    if (!isCompleted && data['timeSlot'] != null)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          data['timeSlot'].toString().split(' ')[0], // Morning/Afternoon/Evening
          style: const TextStyle(
            color: Color(0xFF10B981),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
  ],
),
          const SizedBox(height: 10),

          // Customer Name
          Text(
            userName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),

          // Location
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Animals + Waste Chips
          Row(
            children: [
              Icon(Icons.pets, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                '$animals Animal${animals > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _getWasteChips(wasteType),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Button
          if (!isCompleted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DriverTaskDetail(
                        taskId: docId,
                        taskData: data,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Start Pickup',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Completed',
                    style: TextStyle(
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── HELPERS ───────────────────────────────

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  int _getPriority(Map<String, dynamic> data) {
    final animals = data['animals'] ?? 1;
    if (animals >= 3) return 1;
    if (animals >= 2) return 2;
    return 3;
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }


  List<Widget> _getWasteChips(String wasteType) {
    final types = wasteType.split(',').map((e) => e.trim()).toList();
    if (types.isEmpty || (types.length == 1 && types.first.isEmpty)) {
      return [
        _buildWasteChip(wasteType),
      ];
    }
    return types.map((type) => _buildWasteChip(type)).toList();
  }

  Widget _buildWasteChip(String type) {
    final colors = {
      'skin': const Color(0xFFF59E0B),
      'bones': const Color(0xFF3B82F6),
      'offal': const Color(0xFFEF4444),
    };
    final bgColors = {
      'skin': const Color(0xFFFEF3C7),
      'bones': const Color(0xFFE0E7FF),
      'offal': const Color(0xFFFCE4EC),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColors[type] ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: colors[type] ?? Colors.grey[700],
        ),
      ),
    );
  }

  // ─── FILTER CHIPS ───────────────────────────

  Widget _buildFilterChips() {
    return Row(
      children: [
        _filterChip('All', 'all'),
        const SizedBox(width: 4),
        _filterChip('Pending', 'assigned'),
        const SizedBox(width: 4),
        _filterChip('Done', 'completed'),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  void _generateRoute() {
    setState(() => _isRouteOptimized = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Route optimized! Follow the suggested order.'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildStatsPlaceholder() {
    return Row(
      children: [
        _statCard('Total', '--', Icons.list_alt, const Color(0xFF6366F1)),
        const SizedBox(width: 12),
        _statCard('Done', '--', Icons.check_circle, const Color(0xFF10B981)),
        const SizedBox(width: 12),
        _statCard('Earned', '--', Icons.attach_money, const Color(0xFFF59E0B)),
      ],
    );
  }
}

// ─── PROFILE TAB ──────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
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
              user?.displayName ?? 'Driver',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? 'driver@eidclean.com',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Driver',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 32),

            Container(
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
              child: Row(
                children: [
                  _profileStat('Total Tasks', '0'),
                  _profileDivider(),
                  _profileStat('Completed', '0'),
                  _profileDivider(),
                  _profileStat('Rating', '5.0'),
                ],
              ),
            ),

            const Spacer(),

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
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey[200],
    );
  }
}