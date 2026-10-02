// 📁 lib/screens/citizen/my_requests_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'track_driver_screen.dart';    // ✅ NEW: Import tracking screen

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('My Requests'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: auth.loading
          ? const Center(child: CircularProgressIndicator())
          : auth.user == null
              ? const Center(child: Text('Please sign in to view your requests.'))
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('pickupRequests')
                      .where('userId', isEqualTo: auth.user!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Unable to load your requests right now.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? [];
                    final requests = docs.toList()
                      ..sort((a, b) {
                        final aTime = a.data()['createdAt'];
                        final bTime = b.data()['createdAt'];
                        if (aTime is Timestamp && bTime is Timestamp) {
                          return bTime.compareTo(aTime);
                        }
                        return 0;
                      });

                    if (requests.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('📋', style: TextStyle(fontSize: 60)),
                            SizedBox(height: 12),
                            Text(
                              'No pickup requests yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final doc = requests[index];
                        final item = doc.data();
                        final docId = doc.id;
                        final status = item['status'] ?? 'pending';
                        final timeSlot = item['timeSlot'] ?? 'Not set';
                        final location = item['location'] ?? 'No location';
                        final wasteType = item['wasteType'] ?? 'mixed';
                        final driverName = item['driverName'] ?? '';
                        final driverLocation = item['driverLocation'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
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
                              // Status badge + Location
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF111827),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _statusLabel(status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Waste type
                              Row(
                                children: [
                                  const Icon(Icons.delete_outline,
                                      size: 14, color: Color(0xFF6B7280)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Waste type: ${_formatWasteType(wasteType)}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B7280)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // Time slot
                              Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      size: 14, color: Color(0xFF6B7280)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Time slot: $timeSlot',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B7280)),
                                  ),
                                ],
                              ),

                              // Driver info (if assigned)
                              if (driverName.isNotEmpty && status != 'completed') ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person,
                                          size: 16, color: Color(0xFF10B981)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Driver: $driverName',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF10B981),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      // ✅ Live tracking indicator
                                      if (driverLocation != null && driverLocation['isTracking'] == true)
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF10B981),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Live',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF10B981),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],

                              // Notes
                              if (item['notes'] != null &&
                                  item['notes'].toString().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Notes: ${item['notes']}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280)),
                                ),
                              ],

                              // ✅ NEW: Track Driver Button
                              if (status == 'assigned' ||
                                  status == 'on_the_way' ||
                                  status == 'arrived') ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TrackDriverScreen(
                                            requestId: docId,
                                            requestData: item,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.location_on,
                                        size: 18),
                                    label: const Text(
                                      'Track Driver',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }

  // ─── HELPERS ───

  Color _statusColor(String status) {
    switch (status) {
      case 'assigned':
      case 'on_the_way':
      case 'arrived':
        return const Color(0xFF2563EB);
      case 'completed':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFFD97706);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'assigned':
        return 'ASSIGNED';
      case 'on_the_way':
        return 'ON THE WAY';
      case 'arrived':
        return 'ARRIVED';
      case 'completed':
        return 'COMPLETED';
      default:
        return 'PENDING';
    }
  }

  String _formatWasteType(String value) {
    switch (value) {
      case 'bones':
        return 'Bones & Skin';
      case 'blood':
        return 'Blood & Fluid';
      case 'other':
        return 'Other';
      default:
        return 'Mixed Waste';
    }
  }
}