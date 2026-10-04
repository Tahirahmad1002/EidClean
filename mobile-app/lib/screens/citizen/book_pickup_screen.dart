// lib/screens/citizen/book_pickup_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';
import 'location_picker_screen.dart';

// ─── TINTS (same tones as the React dashboard) ──────────────

class _Tone {
  final Color bg;
  final Color bg2;
  final Color border;
  final Color from;
  final Color to;
  final Color fg;
  const _Tone({
    required this.bg,
    required this.bg2,
    required this.border,
    required this.from,
    required this.to,
    required this.fg,
  });
}

class _Tones {
  _Tones._();

  static const Color teal700 = Color(0xFF0F766E);
  static const Color amber300 = Color(0xFFFCD34D);
  static const Color amber200 = Color(0xFFFDE68A);

  // ✅ FIX 1: 'const' → 'final'
  static final _Tone emerald = _Tone(
    bg: AppColors.primaryBg,
    bg2: AppColors.primaryLight,
    border: AuthColors.emerald200,
    from: AuthColors.emerald400,
    to: AppColors.primaryDark,
    fg: AuthColors.emerald700,
  );

  static final _Tone amber = _Tone(
    bg: const Color(0xFFFFFBEB),
    bg2: const Color(0xFFFEF3C7),
    border: const Color(0xFFFDE68A),
    from: const Color(0xFFFCD34D),
    to: AppColors.accentDark,
    fg: const Color(0xFFB45309),
  );

  static final _Tone blue = _Tone(
    bg: const Color(0xFFEFF6FF),
    bg2: const Color(0xFFDBEAFE),
    border: const Color(0xFFBFDBFE),
    from: const Color(0xFF60A5FA),
    to: const Color(0xFF2563EB),
    fg: const Color(0xFF1D4ED8),
  );

  static final _Tone rose = _Tone(
    bg: const Color(0xFFFFF1F2),
    bg2: const Color(0xFFFFE4E6),
    border: const Color(0xFFFECDD3),
    from: const Color(0xFFFB7185),
    to: const Color(0xFFE11D48),
    fg: const Color(0xFFBE123C),
  );

  static final _Tone indigo = _Tone(
    bg: const Color(0xFFEEF2FF),
    bg2: const Color(0xFFE0E7FF),
    border: const Color(0xFFC7D2FE),
    from: const Color(0xFF818CF8),
    to: const Color(0xFF4F46E5),
    fg: const Color(0xFF4338CA),
  );
}

// ✅ FIX 2: 'const' → 'final' (kyunki _Tones ab final hain)
final List<_Tone> _slotTones = [_Tones.amber, _Tones.blue, _Tones.indigo];

const List<IconData> _slotIcons = [
  Icons.wb_twilight_rounded,
  Icons.light_mode_rounded,
  Icons.dark_mode_rounded,
];

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

  final List<Map<String, dynamic>> _wasteTypes = [
    {
      'value': 'mixed',
      'label': 'Mixed Waste',
      'icon': Icons.delete_outline_rounded,
      'tone': _Tones.emerald,
    },
    {
      'value': 'bones',
      'label': 'Bones & Skin',
      'icon': Icons.set_meal_rounded,
      'tone': _Tones.amber,
    },
    {
      'value': 'blood',
      'label': 'Blood & Fluid',
      'icon': Icons.water_drop_rounded,
      'tone': _Tones.rose,
    },
    {
      'value': 'other',
      'label': 'Other',
      'icon': Icons.inventory_2_rounded,
      'tone': _Tones.blue,
    },
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
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final auth = context.read<AuthProvider>();

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
          debugPrint(
              'User data loaded - Name: $userDisplayName, Phone: $userPhone');
        } else {
          debugPrint('User document not found');
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
      }

      if (userDisplayName.isEmpty) {
        userDisplayName = auth.user!.email ?? 'Citizen';
      }

      await FirebaseFirestore.instance.collection('pickupRequests').add({
        'userId': auth.user!.uid,
        'userName': userDisplayName,
        'userEmail': auth.user!.email ?? '',
        'userPhone': userPhone,
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
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  String _slotName(String slot) {
    final i = slot.indexOf('(');
    return i == -1 ? slot : slot.substring(0, i).trim();
  }

  String _slotRange(String slot) {
    final i = slot.indexOf('(');
    final j = slot.lastIndexOf(')');
    if (i == -1 || j <= i) return '';
    return slot.substring(i + 1, j).trim();
  }

  String _wasteLabel() {
    for (final t in _wasteTypes) {
      if (t['value'] == _wasteType) return t['label'] as String;
    }
    return _wasteType;
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _successScreen();

    return AuthSystemUi(
      child: Scaffold(
        backgroundColor: AppColors.primaryBg,
        body: Stack(
          children: [
            Positioned.fill(child: _buildBackdrop()),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                children: [
                  _buildHero(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: 26),
                        _sectionTitle(
                          'Pickup Location',
                          Icons.location_on_rounded,
                          _Tones.emerald,
                        ),
                        const SizedBox(height: 12),
                        _buildLocationCard(),
                        const SizedBox(height: 26),
                        _sectionTitle(
                          'Waste Type',
                          Icons.delete_outline_rounded,
                          _Tones.rose,
                        ),
                        const SizedBox(height: 12),
                        _buildWasteGrid(),
                        const SizedBox(height: 26),
                        _sectionTitle(
                          'Number of Animals',
                          Icons.pets_rounded,
                          _Tones.amber,
                        ),
                        const SizedBox(height: 12),
                        _buildAnimalsCard(),
                        const SizedBox(height: 26),
                        _sectionTitle(
                          'Preferred Time Slot',
                          Icons.schedule_rounded,
                          _Tones.blue,
                        ),
                        const SizedBox(height: 12),
                        _buildTimeSlots(),
                        const SizedBox(height: 26),
                        _sectionTitle(
                          'Additional Notes',
                          Icons.edit_note_rounded,
                          _Tones.indigo,
                          badge: 'Optional',
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notesCtrl,
                          maxLines: 3,
                          cursorColor: AppColors.primary,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: _inputDecoration(
                              'Any special instructions for the driver...'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildSubmitBar(),
      ),
    );
  }

  Widget _buildBackdrop() {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryBg,
                  AppColors.slate50,
                  Color(0xFFEFF6F3),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -140,
          right: -120,
          child: GlowCircle(
            size: 380,
            color: AuthColors.emerald400.withValues(alpha: 0.14),
          ),
        ),
        Positioned(
          bottom: 200,
          left: -150,
          child: GlowCircle(
            size: 320,
            color: AppColors.accent.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AuthColors.emerald900,
            AuthColors.emerald700,
            _Tones.teal700,
          ],
          stops: [0.0, 0.52, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        border: Border.all(color: AuthColors.emerald950.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AuthColors.emerald950.withValues(alpha: 0.38),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _MaskedLattice()),
          Positioned(
            top: -90,
            right: -60,
            child: GlowCircle(
              size: 300,
              color: AppColors.accent.withValues(alpha: 0.50),
            ),
          ),
          Positioned(
            bottom: -110,
            left: 40,
            child: GlowCircle(
              size: 280,
              color: const Color(0xFF5EEAD4).withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            top: top + 50,
            right: -34,
            child: Icon(
              Icons.nightlight_round,
              size: 190,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            top: top + 14,
            right: 28,
            child: Transform.rotate(
              angle: 0.32,
              child: Icon(
                Icons.nightlight_round,
                size: 50,
                color: _Tones.amber200.withValues(alpha: 0.92),
                shadows: [
                  Shadow(
                    color: _Tones.amber300.withValues(alpha: 0.65),
                    blurRadius: 28,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: top + 70,
            right: 96,
            child: Icon(
              Icons.star_rounded,
              size: 12,
              color: _Tones.amber300.withValues(alpha: 0.9),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 10, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackButton(),
                const SizedBox(height: 18),
                const AuthHeroChip(
                  icon: Icons.local_shipping_rounded,
                  label: 'WASTE COLLECTION',
                ),
                const SizedBox(height: 12),
                Text(
                  'Book Pickup',
                  style: AppTextStyles.h1.copyWith(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(right: 56),
                  child: Text(
                    'Schedule waste collection from your doorstep',
                    style: AppTextStyles.body.copyWith(
                      color: AuthColors.emerald200.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildHeroStrip(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStrip() {
    final hasLocation = _locationText.isNotEmpty;

    Widget item(IconData icon, String label, String value, {bool ok = false}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    ok ? Icons.check_circle_rounded : icon,
                    size: 14,
                    color: ok
                        ? AuthColors.emerald300
                        : AuthColors.emerald200.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AuthColors.emerald200.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget divider() => Container(
        width: 1, height: 36, color: Colors.white.withValues(alpha: 0.15));

    return Container(
      decoration: BoxDecoration(
        color: AuthColors.emerald950.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          item(
            Icons.location_on_rounded,
            'Location',
            hasLocation ? 'Selected' : 'Not set',
            ok: hasLocation,
          ),
          divider(),
          item(
            Icons.pets_rounded,
            'Animals',
            '$_animals',
          ),
          divider(),
          item(
            Icons.schedule_rounded,
            'Slot',
            _slotName(_timeSlot),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 21,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryBg, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AuthColors.emerald200),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _gradientTile(Icons.info_outline_rounded, _Tones.emerald, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Select your location on map and fill other details below.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AuthColors.emerald900,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final hasLocation = _locationText.isNotEmpty;
    final tone = hasLocation ? _Tones.emerald : _Tones.blue;

    return GestureDetector(
      onTap: _openLocationPicker,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tone.bg, tone.bg2],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasLocation ? AppColors.primary : tone.border,
            width: hasLocation ? 1.8 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: tone.to.withValues(alpha: hasLocation ? 0.24 : 0.16),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: 112,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MapPreviewPainter(
                        tint: tone.to,
                        road: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -30,
                    right: -24,
                    child: GlowCircle(
                      size: 130,
                      color: tone.from.withValues(alpha: 0.45),
                    ),
                  ),
                  _buildMapPin(hasLocation),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                border: Border(top: BorderSide(color: tone.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasLocation
                              ? 'Location Selected'
                              : 'Tap to select on map',
                          style: AppTextStyles.label.copyWith(
                            fontWeight: FontWeight.w800,
                            color: tone.fg,
                          ),
                        ),
                        if (hasLocation) ...[
                          const SizedBox(height: 4),
                          Text(
                            _locationText,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.slate700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [tone.from, tone.to],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: tone.to.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      hasLocation
                          ? Icons.edit_location_alt_rounded
                          : Icons.arrow_forward_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPin(bool active) {
    final base = active ? AppColors.primary : AppColors.accent;
    final colors = active
        ? const [AuthColors.emerald400, AppColors.primaryDark]
        : const [Color(0xFFFCD34D), AppColors.accent];

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: base.withValues(alpha: 0.16),
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: base.withValues(alpha: 0.5),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
      ],
    );
  }

  Widget _buildWasteGrid() {
    return GridView.count(
      crossAxisCount: 2,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: _wasteTypes.map((type) {
        final selected = _wasteType == type['value'];
        final tone = type['tone'] as _Tone;

        return GestureDetector(
          onTap: () => setState(() => _wasteType = type['value'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: selected ? [tone.from, tone.to] : [tone.bg, tone.bg2],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? tone.to : tone.border,
                width: selected ? 1.6 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: tone.to.withValues(alpha: selected ? 0.38 : 0.10),
                  blurRadius: selected ? 18 : 12,
                  offset: Offset(0, selected ? 8 : 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.24)
                        : Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.3)
                          : tone.border,
                    ),
                  ),
                  child: Icon(
                    type['icon'] as IconData,
                    size: 19,
                    color: selected ? Colors.white : tone.to,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    type['label'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : tone.fg,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnimalsCard() {
    final tone = _Tones.amber;

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone.bg, tone.bg2],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tone.border, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: tone.to.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _gradientTile(Icons.pets_rounded, tone, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Animals sacrificed',
              maxLines: 2,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: tone.fg,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tone.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _stepButton(
                  icon: Icons.remove_rounded,
                  enabled: _animals > 1,
                  onPressed: () {
                    if (_animals > 1) setState(() => _animals--);
                  },
                ),
                SizedBox(
                  width: 36,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Text(
                      '$_animals',
                      key: ValueKey(_animals),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.stat.copyWith(
                        fontSize: 22,
                        color: tone.fg,
                      ),
                    ),
                  ),
                ),
                _stepButton(
                  icon: Icons.add_rounded,
                  enabled: true,
                  onPressed: () => setState(() => _animals++),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      style: IconButton.styleFrom(
        backgroundColor: enabled ? AppColors.primaryLight : AppColors.slate100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(
        icon,
        size: 20,
        color: enabled ? AppColors.primaryDark : AppColors.slate300,
      ),
    );
  }

  // ✅ FIX 3: IntrinsicHeight wrapper
  Widget _buildTimeSlots() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < _timeSlots.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _timeSlotTile(_timeSlots[i], i)),
          ],
        ],
      ),
    );
  }

  Widget _timeSlotTile(String slot, int i) {
    final selected = _timeSlot == slot;
    final tone = _slotTones[i % _slotTones.length];
    final icon = _slotIcons[i % _slotIcons.length];

    return GestureDetector(
      onTap: () => setState(() => _timeSlot = slot),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected ? [tone.from, tone.to] : [tone.bg, tone.bg2],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? tone.to : tone.border,
            width: selected ? 1.6 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: tone.to.withValues(alpha: selected ? 0.38 : 0.10),
              blurRadius: selected ? 18 : 12,
              offset: Offset(0, selected ? 8 : 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.24)
                    : Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.35)
                      : tone.border,
                ),
              ),
              child: Icon(
                icon,
                size: 21,
                color: selected ? Colors.white : tone.to,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _slotName(slot),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : tone.fg,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _slotRange(slot),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                color: selected
                    ? Colors.white.withValues(alpha: 0.9)
                    : tone.fg.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitBar() {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottom),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF0FDF4)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.primaryLight.withValues(alpha: 0.9)),
        ),
        boxShadow: [
          BoxShadow(
            color: AuthColors.emerald900.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _summaryPill(
                Icons.pets_rounded,
                '$_animals ${_animals == 1 ? 'animal' : 'animals'}',
                _Tones.amber,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _summaryPill(
                  Icons.schedule_rounded,
                  _slotName(_timeSlot),
                  _Tones.blue,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _summaryPill(
                  Icons.delete_outline_rounded,
                  _wasteLabel(),
                  _Tones.emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _GradientCta(
            label: 'Submit Pickup Request',
            icon: Icons.check_rounded,
            loading: _loading,
            onPressed: _loading ? null : _submitRequest,
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(IconData icon, String text, _Tone tone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tone.bg2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tone.to),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: tone.fg,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successScreen() {
    final media = MediaQuery.of(context);
    final top = media.padding.top;
    final bottom = media.padding.bottom;

    return AuthSystemUi(
      child: Scaffold(
        backgroundColor: AuthColors.emerald900,
        body: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AuthColors.emerald900,
                      AuthColors.emerald700,
                      _Tones.teal700,
                    ],
                    stops: [0.0, 0.52, 1.0],
                  ),
                ),
              ),
            ),
            const Positioned.fill(child: _MaskedLattice(alpha: 0.10)),
            Positioned(
              top: -110,
              right: -80,
              child: GlowCircle(
                size: 340,
                color: AppColors.accent.withValues(alpha: 0.50),
              ),
            ),
            Positioned(
              bottom: -140,
              left: -100,
              child: GlowCircle(
                size: 340,
                color: const Color(0xFF5EEAD4).withValues(alpha: 0.24),
              ),
            ),
            Positioned(
              top: top + 40,
              right: -20,
              child: Icon(
                Icons.nightlight_round,
                size: 170,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Positioned(
              top: top + 30,
              right: 40,
              child: Transform.rotate(
                angle: 0.32,
                child: Icon(
                  Icons.nightlight_round,
                  size: 52,
                  color: _Tones.amber200.withValues(alpha: 0.92),
                  shadows: [
                    Shadow(
                      color: _Tones.amber300.withValues(alpha: 0.65),
                      blurRadius: 28,
                    ),
                  ],
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, c) {
                final minH = (c.maxHeight - (top + 24) - (bottom + 24))
                    .clamp(0.0, double.infinity)
                    .toDouble();

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, top + 24, 20, bottom + 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minH),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.4, end: 1),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.elasticOut,
                              builder: (context, v, child) =>
                                  Transform.scale(scale: v, child: child),
                              child: const AuthLogoTile(
                                icon: Icons.check_rounded,
                                size: 96,
                                radius: 32,
                                iconSize: 52,
                                ringColor: AuthColors.emerald900,
                                crescentBadge: true,
                              ),
                            ),
                            const SizedBox(height: 26),
                            Text(
                              'Request Submitted!',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.h1.copyWith(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Your pickup request has been submitted successfully. A driver will be assigned to you shortly.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body.copyWith(
                                color: AuthColors.emerald200
                                    .withValues(alpha: 0.9),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 26),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 650),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, child) => Opacity(
                                opacity: v,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - v) * 24),
                                  child: child,
                                ),
                              ),
                              child: Container(
                                width: double.infinity,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primaryBg,
                                      AppColors.primaryLight,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AuthColors.emerald950
                                          .withValues(alpha: 0.35),
                                      blurRadius: 40,
                                      offset: const Offset(0, 18),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      height: 3,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AuthColors.emerald400,
                                            AppColors.primary,
                                            AppColors.accent,
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _summaryRow(
                                            Icons.location_on_rounded,
                                            'PICKUP LOCATION',
                                            _locationText,
                                            _Tones.emerald,
                                          ),
                                          const SizedBox(height: 10),
                                          _summaryRow(
                                            Icons.delete_outline_rounded,
                                            'WASTE TYPE',
                                            _wasteLabel(),
                                            _Tones.rose,
                                          ),
                                          const SizedBox(height: 10),
                                          _summaryRow(
                                            Icons.pets_rounded,
                                            'ANIMALS',
                                            '$_animals',
                                            _Tones.amber,
                                          ),
                                          const SizedBox(height: 10),
                                          _summaryRow(
                                            Icons.schedule_rounded,
                                            'TIME SLOT',
                                            _timeSlot,
                                            _Tones.blue,
                                          ),
                                          const SizedBox(height: 18),
                                          _GradientCta(
                                            label: 'Back to Home',
                                            icon: Icons.home_rounded,
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value, _Tone tone) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone.bg, tone.bg2],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _gradientTile(icon, tone, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.overline.copyWith(
                    fontSize: 10,
                    color: tone.fg.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientTile(IconData icon, _Tone tone, {double size = 36}) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone.from, tone.to],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: tone.to.withValues(alpha: 0.38),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size * 0.5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.38),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Icon(icon, color: Colors.white, size: size * 0.52),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, _Tone tone,
      {String? badge}) {
    return Row(
      children: [
        _gradientTile(icon, tone, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
            ),
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tone.bg2,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tone.border),
            ),
            child: Text(
              badge,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: tone.fg,
              ),
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.slate400),
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: _Tones.indigo.border, width: 1.3),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: _Tones.indigo.border, width: 1.3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      filled: true,
      fillColor: _Tones.indigo.bg,
    );
  }
}

// ─── REUSABLE VISUAL PIECES ────────────────────

class _MaskedLattice extends StatelessWidget {
  final double alpha;
  const _MaskedLattice({this.alpha = 0.13});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Colors.black, Colors.transparent],
          stops: [0.0, 0.9],
        ).createShader(rect),
        child: CustomPaint(
          painter: StarPatternPainter(alpha: alpha, tile: 44),
        ),
      ),
    );
  }
}

class _GradientCta extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  const _GradientCta({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  @override
  State<_GradientCta> createState() => _GradientCtaState();
}

class _GradientCtaState extends State<_GradientCta> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 56,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AuthColors.emerald400, AppColors.primaryDark],
            ),
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: AuthColors.emerald400
                    .withValues(alpha: _pressed ? 0.28 : 0.52),
                blurRadius: _pressed ? 10 : 24,
                offset: Offset(0, _pressed ? 3 : 12),
              ),
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.35),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 28,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.28),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: widget.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.label,
                            style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPreviewPainter extends CustomPainter {
  final Color tint;
  final Color road;
  const _MapPreviewPainter({required this.tint, required this.road});

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = tint.withValues(alpha: 0.14)
      ..strokeWidth = 1;

    const step = 26.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final path = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.30,
        size.height * 0.15,
        size.width * 0.58,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.80,
        size.height * 0.85,
        size.width,
        size.height * 0.30,
      );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 12
        ..color = road,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2
        ..color = tint.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant _MapPreviewPainter old) =>
      old.tint != tint || old.road != road;
}
