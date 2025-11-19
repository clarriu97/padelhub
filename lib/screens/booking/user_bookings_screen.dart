import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:padelhub/colors.dart';
import 'package:padelhub/models/booking.dart';
import 'package:padelhub/services/booking_service.dart';
import 'package:intl/intl.dart';

class UserBookingsScreen extends StatefulWidget {
  const UserBookingsScreen({super.key});

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen>
    with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  late TabController _tabController;
  bool _isLoading = false;
  List<Booking> _upcomingBookings = [];
  List<Booking> _pastBookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final upcoming = await _bookingService.getUserUpcomingBookings(user.uid);
      final past = await _bookingService.getUserPastBookings(user.uid);

      setState(() {
        _upcomingBookings = upcoming;
        _pastBookings = past;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading bookings: $e')));
      }
    }
  }

  Future<void> _toggleSharing(Booking booking) async {
    try {
      await _bookingService.toggleSharingEnabled(
        clubId: booking.clubId,
        courtId: booking.courtId,
        bookingId: booking.id,
        enabled: !booking.sharingEnabled,
      );
      await _loadBookings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              booking.sharingEnabled
                  ? 'Sharing disabled'
                  : 'Sharing enabled - others can now request to join',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error toggling sharing: $e')));
      }
    }
  }

  Future<void> _approveJoinRequest(Booking booking, String userId) async {
    try {
      await _bookingService.approveJoinRequest(
        clubId: booking.clubId,
        courtId: booking.courtId,
        bookingId: booking.id,
        requestUserId: userId,
      );
      await _loadBookings();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Join request approved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error approving request: $e')));
      }
    }
  }

  Future<void> _rejectJoinRequest(Booking booking, String userId) async {
    try {
      await _bookingService.rejectJoinRequest(
        clubId: booking.clubId,
        courtId: booking.courtId,
        bookingId: booking.id,
        requestUserId: userId,
      );
      await _loadBookings();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Join request rejected')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error rejecting request: $e')));
      }
    }
  }

  // ignore: unused_element
  Future<void> _removeSharedUser(Booking booking, String userId) async {
    try {
      await _bookingService.removeSharedUser(
        clubId: booking.clubId,
        courtId: booking.courtId,
        bookingId: booking.id,
        userId: userId,
      );
      await _loadBookings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User removed from booking')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing user: $e')));
      }
    }
  }

  Future<void> _cancelBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Cancel Booking',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to cancel this booking?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _bookingService.cancelBooking(
          clubId: booking.clubId,
          courtId: booking.courtId,
          bookingId: booking.id,
        );
        await _loadBookings();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Booking cancelled')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling booking: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.onPrimary,
          labelColor: AppColors.onPrimary,
          unselectedLabelColor: AppColors.onPrimary.withValues(alpha: 0.7),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(_upcomingBookings, isUpcoming: true),
                _buildBookingsList(_pastBookings, isUpcoming: false),
              ],
            ),
    );
  }

  Widget _buildBookingsList(
    List<Booking> bookings, {
    required bool isUpcoming,
  }) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_busy : Icons.history,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming bookings' : 'No past bookings',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking, isUpcoming: isUpcoming);
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, {required bool isUpcoming}) {
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user?.uid == booking.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and time
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEE, MMM d, yyyy').format(booking.startDateTime),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${booking.startTime} - ${booking.endTime}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Booking details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Court info
                Row(
                  children: [
                    Icon(Icons.sports_tennis, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Court ${booking.courtId}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${booking.price.toStringAsFixed(2)} €',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Duration
                Row(
                  children: [
                    Icon(Icons.timer, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${booking.durationMinutes} minutes',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),

                // Sharing status for owner
                if (isOwner && isUpcoming) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        booking.sharingEnabled ? Icons.share : Icons.lock,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        booking.sharingEnabled ? 'Sharing enabled' : 'Private',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Switch(
                        value: booking.sharingEnabled,
                        onChanged: (_) => _toggleSharing(booking),
                        activeTrackColor: AppColors.primary,
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ],

                // Players count
                if (booking.sharingEnabled ||
                    booking.sharedWith.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${booking.sharedWith.length + 1}/${booking.maxPlayers} players',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],

                // Join requests (for owner)
                if (isOwner &&
                    booking.joinRequests.isNotEmpty &&
                    isUpcoming) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Join Requests',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...booking.joinRequests.map((request) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              request['userName'] ?? 'Unknown',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.check, color: AppColors.success),
                            onPressed: () =>
                                _approveJoinRequest(booking, request['userId']),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: AppColors.error),
                            onPressed: () =>
                                _rejectJoinRequest(booking, request['userId']),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                // Cancel button (for upcoming bookings)
                if (isOwner && isUpcoming) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _cancelBooking(booking),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel Booking'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
