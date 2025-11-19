import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:padelhub/colors.dart';
import 'package:padelhub/screens/booking/booking_screen.dart';
import 'package:padelhub/screens/home/profile_screen.dart';
import 'package:padelhub/screens/admin/clubs_admin_screen.dart';
import 'package:padelhub/services/club_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isAdmin = false;
  bool _isLoadingAdmin = true;
  bool _adminModeActivated = false;
  int _tapCount = 0;
  DateTime? _lastTapTime;
  final ClubService _clubService = ClubService();

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final isAdmin = await _clubService.isUserAdmin(user.uid);
      setState(() {
        _isAdmin = isAdmin;
        _isLoadingAdmin = false;
      });
    } else {
      setState(() {
        _isLoadingAdmin = false;
      });
    }
  }

  void _onTitleTap() {
    final now = DateTime.now();

    // Reset if more than 3 seconds since last tap
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) > const Duration(seconds: 3)) {
      _tapCount = 0;
    }

    _tapCount++;
    _lastTapTime = now;

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Activate admin mode on 7th tap (only if user is admin)
    if (_tapCount >= 7 && _isAdmin && !_adminModeActivated) {
      _activateAdminMode();
    }
  }

  void _activateAdminMode() {
    setState(() {
      _adminModeActivated = true;
      _tapCount = 0;
    });

    // Provide strong haptic feedback for activation
    HapticFeedback.mediumImpact();

    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.white),
            SizedBox(width: 12),
            Text('Admin mode activated'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<Widget> get _screens => [
    const BookingScreen(),
    if (_isAdmin && _adminModeActivated) const ClubsAdminScreen(),
    const ProfileScreen(),
  ];

  List<String> get _titles => [
    'Home',
    if (_isAdmin && _adminModeActivated) 'Admin',
    'Profile',
  ];

  List<BottomNavigationBarItem> get _navItems => [
    const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    if (_isAdmin && _adminModeActivated)
      const BottomNavigationBarItem(
        icon: Icon(Icons.admin_panel_settings),
        label: 'Admin',
      ),
    const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAdmin) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        title: GestureDetector(
          onTap: _onTitleTap,
          child: Text(_titles[_currentIndex]),
        ),
        centerTitle: true,
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: _navItems,
      ),
    );
  }
}
