import 'package:flutter/material.dart';
import 'package:padelhub/colors.dart';
import 'package:padelhub/models/club.dart';
import 'package:padelhub/screens/booking/booking_screen.dart';
import 'package:padelhub/screens/home/club_info_screen.dart';
import 'package:padelhub/screens/home/open_matches_screen.dart';
import 'package:padelhub/services/club_service.dart';

class ClubMainScreen extends StatefulWidget {
  const ClubMainScreen({super.key});

  @override
  State<ClubMainScreen> createState() => _ClubMainScreenState();
}

class _ClubMainScreenState extends State<ClubMainScreen>
    with SingleTickerProviderStateMixin {
  final ClubService _clubService = ClubService();
  Club? _club;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _loadClub();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClub() async {
    try {
      final club = await _clubService.getDefaultClub();
      if (mounted) {
        setState(() {
          _club = club;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading club: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_club == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('No club configuration found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header común con imagen, nombre y dirección
          _buildClubHeader(),
          // TabBar
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Home'),
                Tab(text: 'Book'),
                Tab(text: 'Open Matches'),
              ],
            ),
          ),
          // Contenido de las tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ClubInfoScreen(club: _club!),
                BookingScreen(club: _club!),
                OpenMatchesScreen(club: _club!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubHeader() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.sports_tennis,
              size: 100,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _club!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3.0,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
                if (_club!.address != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _club!.address!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 2.0,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
