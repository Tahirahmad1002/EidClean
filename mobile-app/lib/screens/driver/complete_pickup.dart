// 📁 lib/screens/driver/complete_pickup.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';           // ✅ NEW: for base64Encode
import 'dart:io';
import 'dart:typed_data';
import 'customer_review.dart';

class CompletePickup extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> taskData;
  final double? distanceKm;
  final String? etaText;

  const CompletePickup({
    super.key,
    required this.taskId,
    required this.taskData,
    this.distanceKm,
    this.etaText,
  });

  @override
  State<CompletePickup> createState() => _CompletePickupState();
}

class _CompletePickupState extends State<CompletePickup> {
  bool _loading = false;
  File? _photo;
  Uint8List? _webPhotoBytes;
  final TextEditingController _notesController = TextEditingController();

  static const Color tealColor = Color(0xFF14897A);
  static const Color darkTeal = Color(0xFF0D6B5E);

  // ✅ NEW: Also store compressed bytes for mobile
  Uint8List? _mobilePhotoBytes;

  Future<void> _capturePhoto() async {
    print('📸 Opening camera...');
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 600,          // ✅ Reduced from 800 → smaller photo
      maxHeight: 600,         // ✅ Reduced from 800
      imageQuality: 60,       // ✅ Reduced from 80 → smaller file
    );

    if (photo != null) {
      print('✅ Photo captured successfully');

      if (kIsWeb) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _webPhotoBytes = bytes;
          _photo = null;
          _mobilePhotoBytes = null;
        });
      } else {
        // ✅ Read bytes for mobile too (for Base64)
        final bytes = await photo.readAsBytes();
        setState(() {
          _photo = File(photo.path);
          _mobilePhotoBytes = bytes;
          _webPhotoBytes = null;
        });
      }
    }
  }

  Future<void> _submitPickup() async {
    if (_photo == null && _webPhotoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📸 Please take a photo before submitting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // ✅ STEP 1: Get photo bytes (web or mobile)
      Uint8List? photoBytes;
      if (kIsWeb && _webPhotoBytes != null) {
        photoBytes = _webPhotoBytes;
      } else if (_mobilePhotoBytes != null) {
        photoBytes = _mobilePhotoBytes;
      } else if (_photo != null) {
        photoBytes = await _photo!.readAsBytes();
      }

      // ✅ STEP 2: Convert to Base64
      String? photoBase64;
      if (photoBytes != null) {
        photoBase64 = 'data:image/jpeg;base64,${base64Encode(photoBytes)}';
        print('📸 Photo size: ${photoBytes.length} bytes');
        print('📸 Base64 size: ${photoBase64.length} chars');

        // ✅ STEP 3: Check if under 1MB (Firestore limit)
        if (photoBase64.length > 950000) {
          // ~950KB limit to be safe
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '📸 Photo too large. Please retake with lower quality.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // ✅ STEP 4: Save to Firestore
      await FirebaseFirestore.instance
          .collection('pickupRequests')
          .doc(widget.taskId)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'notes': _notesController.text.trim(),
        'photoBase64': photoBase64,        // ✅ NEW: Base64 photo
        'photoSize': photoBytes?.length ?? 0,  // ✅ NEW: Photo size in bytes
      });

      print('✅ Firestore updated with photo');

      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pickup completed successfully!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 1),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerReview(
                taskData: widget.taskData,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.taskData;
    final location = data['location'] ?? 'No location';
    final userName = data['userName'] ?? 'Customer';
    final animals = data['animals'] ?? 1;
    final wasteType = data['wasteType'] ?? 'mixed';
    final timeSlot = data['timeSlot'] ?? '';

    final hasPhoto = _photo != null || _webPhotoBytes != null;
    final photoWidget = _photo != null
        ? Image.file(_photo!, fit: BoxFit.cover, width: double.infinity)
        : _webPhotoBytes != null
            ? Image.memory(_webPhotoBytes!,
                fit: BoxFit.cover, width: double.infinity)
            : null;

    final distanceDisplay = widget.distanceKm != null
        ? '${widget.distanceKm!.toStringAsFixed(1)} km away'
        : '—';
    final etaDisplay = widget.etaText ?? '—';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: tealColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Complete Pickup',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ETA: $etaDisplay',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MAP AREA (placeholder)
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 40, color: Colors.grey),
                        SizedBox(height: 4),
                        Text(
                          'Live Location',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Destination',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // NEXT PICKUP
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next Pickup',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.route,
                          size: 16, color: Color(0xFF14897A)),
                      const SizedBox(width: 4),
                      Text(
                        distanceDisplay,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.timer,
                          size: 16, color: Color(0xFF14897A)),
                      const SizedBox(width: 4),
                      Text(
                        'ETA: $etaDisplay',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF14897A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // PICKUP DETAILS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pickup Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.pets, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '$animals Animals: $wasteType',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (timeSlot.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          timeSlot,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // PHOTO REQUIRED
            const Text(
              'Photo Required *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _capturePhoto,
              child: Container(
                width: double.infinity,
                height: hasPhoto ? 180 : 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: hasPhoto && photoWidget != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: photoWidget,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 36,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap to open camera',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (hasPhoto)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: _capturePhoto,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retake Photo'),
                  style: TextButton.styleFrom(
                    foregroundColor: tealColor,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // NOTES
            const Text(
              'Notes (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Any issues, extra items, or special notes...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F6F8),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // SUBMIT
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitPickup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasPhoto ? tealColor : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        hasPhoto ? 'Complete Pickup' : '📸 Take Photo First',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}