// 📁 lib/screens/citizen/book_pickup_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'location_picker_screen.dart';

class BookPickupScreen extends StatefulWidget {
  const BookPickupScreen({super.key});

  @override
  State<BookPickupScreen> createState() => _BookPickupScreenState();
}

class _BookPickupScreenState extends State<BookPickupScreen> {
  final _notesCtrl = TextEditingController();

  String _locationText = '';
  double? _latitude;
  double? _longitude;

  String _wasteType = 'mixed';
  int _animals = 1;
  String _timeSlot = 'Morning (8AM - 12PM)';
  bool _loading = false;
  bool _submitted = false;

  final List<String> _timeSlots = [
    'Morning (8AM - 12PM)',
    'Afternoon (12PM - 4PM)',
    'Evening (4PM - 8PM)',
  ];

  final List<Map<String, String>> _wasteTypes = [
    {'value': 'mixed', 'label': 'Mixed Waste', 'icon': '🗑️'},
    {'value': 'bones', 'label': 'Bones & Skin', 'icon': '🦴'},
    {'value': 'blood', 'label': 'Blood & Fluid', 'icon': '🩸'},
    {'value': 'other', 'label': 'Other', 'icon': '📦'},
  ];

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerScreen(),
      ),
    );

    if (result != null && result is Map) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _locationText = result['address'] ?? '';
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_locationText.isEmpty || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your pickup location on map'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final auth = context.read<AuthProvider>();

      // ✅ FETCH USER DATA (name + phone) FROM FIRESTORE
      String userDisplayName = '';
      String userPhone = '';

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(auth.user!.uid)
            .get();

        if (userDoc.exists) {
          userDisplayName = userDoc.data()?['name'] ?? '';
          userPhone = userDoc.data()?['phone'] ?? '';
          print('✅ User data loaded - Name: $userDisplayName, Phone: $userPhone');
        } else {
          print('❌ User document not found');
        }
      } catch (e) {
        print('⚠️ Error fetching user data: $e');
      }

      // Fallback if name is empty
      if (userDisplayName.isEmpty) {
        userDisplayName = auth.user!.email ?? 'Citizen';
      }

      await FirebaseFirestore.instance.collection('pickupRequests').add({
        'userId': auth.user!.uid,
        'userName': userDisplayName,       // ✅ Real name (not email)
        'userEmail': auth.user!.email ?? '', // ✅ Store email separately
        'userPhone': userPhone,            // ✅ NEW: Phone number
        'location': _locationText,
        'latitude': _latitude,
        'longitude': _longitude,
        'geoPoint': GeoPoint(_latitude!, _longitude!),
        'wasteType': _wasteType,
        'animals': _animals,
        'timeSlot': _timeSlot,
        'notes': _notesCtrl.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _loading = false;
          _submitted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _successScreen();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        title: const Text(
          'Book Pickup',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // INFO CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Text('ℹ️', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select your location on map and fill other details below.',
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

            // LOCATION
            _sectionTitle('📍 Pickup Location'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _openLocationPicker,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _locationText.isEmpty
                        ? const Color(0xFFE5E7EB)
                        : const Color(0xFF10B981),
                    width: _locationText.isEmpty ? 1 : 2,
                  ),
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
                        Icons.location_on,
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
                            _locationText.isEmpty
                                ? 'Tap to select on map'
                                : 'Location Selected',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _locationText.isEmpty
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF10B981),
                            ),
                          ),
                          if (_locationText.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _locationText,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF111827),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF9CA3AF),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // WASTE TYPE
            _sectionTitle('🗑️ Waste Type'),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3,
              children: _wasteTypes.map((type) {
                final selected = _wasteType == type['value'];
                return GestureDetector(
                  onTap: () => setState(() => _wasteType = type['value']!),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF10B981)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF10B981)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(type['icon']!,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          type['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // ANIMALS
            _sectionTitle('🐄 Number of Animals'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Animals sacrificed',
                    style: TextStyle(
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_animals > 1) setState(() => _animals--);
                        },
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Color(0xFF10B981)),
                      ),
                      Text(
                        '$_animals',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _animals++),
                        icon: const Icon(Icons.add_circle_outline,
                            color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // TIME SLOT
            _sectionTitle('🕐 Preferred Time Slot'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _timeSlot,
                  isExpanded: true,
                  items: _timeSlots
                      .map((slot) => DropdownMenuItem(
                            value: slot,
                            child: Text(slot,
                                style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _timeSlot = val!),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // NOTES
            _sectionTitle('📝 Additional Notes (Optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: _inputDecoration(
                  'Any special instructions for the driver...'),
            ),

            const SizedBox(height: 32),

            // SUBMIT
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline),
                          SizedBox(width: 8),
                          Text(
                            'Submit Pickup Request',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _successScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.check_circle,
                      color: Color(0xFF10B981), size: 60),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Request Submitted!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your pickup request has been submitted successfully. A driver will be assigned to you shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Color(0xFF111827),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
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
    );
  }
}