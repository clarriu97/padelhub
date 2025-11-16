import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:padelhub/colors.dart';
import 'package:padelhub/screens/home/feed_screen.dart';
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

  List<Widget> get _screens => [
    const FeedScreen(),
    if (_isAdmin) const ClubsAdminScreen(),
    const ProfileScreen(),
  ];

  List<String> get _titles => ['PadelHub', if (_isAdmin) 'Admin', 'Profile'];

  List<BottomNavigationBarItem> get _navItems => [
    const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    if (_isAdmin)
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
        title: Text(_titles[_currentIndex]),
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
