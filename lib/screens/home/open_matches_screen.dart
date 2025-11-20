import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:padelhub/colors.dart';
import 'package:padelhub/models/booking.dart';
import 'package:padelhub/models/club.dart';
import 'package:padelhub/models/court.dart';
import 'package:padelhub/services/booking_service.dart';
import 'package:padelhub/services/court_service.dart';

class OpenMatchesScreen extends StatefulWidget {
  final Club club;
  final CourtService? courtService;
  final BookingService? bookingService;

  const OpenMatchesScreen({
    super.key,
    required this.club,
    this.courtService,
    this.bookingService,
  });

  @override
  State<OpenMatchesScreen> createState() => _OpenMatchesScreenState();
}

class _OpenMatchesScreenState extends State<OpenMatchesScreen> {
  late final CourtService _courtService;
  late final BookingService _bookingService;

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<Court> _courts = [];
  List<Booking> _shareableBookings = [];

  @override
  void initState() {
    super.initState();
    _courtService = widget.courtService ?? CourtService();
    _bookingService = widget.bookingService ?? BookingService();
    _loadCourts();
  }

  Future<void> _loadCourts() async {
    _courtService.getCourts(widget.club.id).listen((courts) async {
      if (mounted) {
        setState(() {
          _courts = courts;
        });
        if (_courts.isNotEmpty) {
          await _loadShareableBookings();
        }
      }
    });
  }

  Future<void> _loadShareableBookings() async {
    if (_courts.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final user = FirebaseAuth.instance.currentUser;

      final shareableBookings = await _bookingService.getShareableBookings(
        clubId: widget.club.id,
        courts: _courts,
        date: dateStr,
      );

      // Filter out bookings owned by current user
      if (mounted) {
        setState(() {
          _shareableBookings = shareableBookings
              .where((b) => b.userId != user?.uid)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shareable bookings: $e')),
        );
      }
    }
  }

  Future<void> _requestToJoin(Booking booking) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await _bookingService.requestToJoinBooking(
        clubId: booking.clubId,
        courtId: booking.courtId,
        bookingId: booking.id,
        userId: user.uid,
        userName: user.email ?? user.displayName ?? 'Unknown User',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Join request sent! Waiting for owner approval.'),
          ),
        );
        // Reload shareable bookings to update UI
        await _loadShareableBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending request: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDateSelector(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _shareableBookings.isEmpty
              ? Center(
                  child: Text(
                    'No open matches for this date',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _shareableBookings.length,
                  itemBuilder: (context, index) {
                    final booking = _shareableBookings[index];
                    final court = _courts.firstWhere(
                      (c) => c.id == booking.courtId,
                      orElse: () => Court(
                        id: 'unknown',
                        name: 'Unknown Court',
                        surface: 'Unknown',
                        pricePerHour: 0,
                      ),
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  court.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    booking.startTime,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Duration: ${booking.durationMinutes} min',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _requestToJoin(booking),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Request to Join'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 14,
          itemBuilder: (context, index) {
            final date = DateTime.now().add(Duration(days: index));
            final isSelected =
                DateFormat('yyyy-MM-dd').format(date) ==
                DateFormat('yyyy-MM-dd').format(_selectedDate);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
                _loadShareableBookings();
              },
              child: Container(
                width: 60,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEE').format(date).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppColors.onPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d').format(date),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.onPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
