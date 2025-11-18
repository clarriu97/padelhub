import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:padelhub/colors.dart';
import 'package:padelhub/models/club.dart';
import 'package:padelhub/models/court.dart';
import 'package:padelhub/models/booking.dart';
import 'package:padelhub/models/time_slot.dart';
import 'package:padelhub/services/club_service.dart';
import 'package:padelhub/services/court_service.dart';
import 'package:padelhub/services/booking_service.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final ClubService _clubService = ClubService();
  final CourtService _courtService = CourtService();
  final BookingService _bookingService = BookingService();

  Club? _selectedClub;
  Court? _selectedCourt;
  DateTime _selectedDate = DateTime.now();
  TimeSlot? _selectedTimeSlot;
  int? _selectedDuration;
  bool _showAvailableOnly = true;
  bool _isLoading = false;

  List<Club> _clubs = [];
  List<Court> _courts = [];
  List<Booking> _existingBookings = [];
  List<TimeSlot> _availableSlots = [];

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    _clubService.getClubs().listen((clubs) {
      setState(() {
        _clubs = clubs;
        if (_clubs.isNotEmpty && _selectedClub == null) {
          _selectedClub = _clubs.first;
          _loadCourts();
        }
      });
    });
  }

  Future<void> _loadCourts() async {
    if (_selectedClub == null) return;

    _courtService.getCourts(_selectedClub!.id).listen((courts) {
      setState(() {
        _courts = courts;
        if (_courts.isNotEmpty) {
          _selectedCourt = _courts.first;
          _loadBookingsAndSlots();
        }
      });
    });
  }

  void _loadBookingsAndSlots() {
    if (_selectedClub == null || _selectedCourt == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    _bookingService
        .getCourtBookings(
          clubId: _selectedClub!.id,
          courtId: _selectedCourt!.id,
          date: dateStr,
        )
        .listen((bookings) {
          setState(() {
            _existingBookings = bookings;
            _availableSlots = _bookingService.calculateAvailableSlots(
              existingBookings: _existingBookings,
              opensAt: _selectedClub!.opensAt ?? '08:00',
              closesAt: _selectedClub!.closesAt ?? '23:00',
            );
          });
        });
  }

  Future<void> _createBooking() async {
    if (_selectedClub == null ||
        _selectedCourt == null ||
        _selectedTimeSlot == null ||
        _selectedDuration == null) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final price = _bookingService.calculatePrice(
        durationMinutes: _selectedDuration!,
        pricePerHour: _selectedCourt!.pricePerHour,
      );

      await _bookingService.createBooking(
        clubId: _selectedClub!.id,
        courtId: _selectedCourt!.id,
        userId: user.uid,
        date: dateStr,
        startTime: _selectedTimeSlot!.startTime,
        durationMinutes: _selectedDuration!,
        players: [user.email ?? 'Player 1'],
        price: price,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking created successfully!')),
        );
        setState(() {
          _selectedTimeSlot = null;
          _selectedDuration = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating booking: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar con imagen
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _selectedClub?.name ?? 'Book',
                style: const TextStyle(
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
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.sports_tennis,
                  size: 100,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Selector de club
                _buildClubSelector(),

                // Selector de fecha con calendario horizontal
                _buildDateSelector(),

                // Toggle para mostrar solo slots disponibles
                _buildAvailableOnlyToggle(),

                // Grid de slots de tiempo
                _buildTimeSlotGrid(),

                // Información de la pista seleccionada
                if (_selectedTimeSlot != null) _buildCourtInfo(),

                // Botón de reserva
                if (_selectedTimeSlot != null && _selectedDuration != null)
                  _buildBookButton(),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubSelector() {
    if (_clubs.isEmpty) return const SizedBox();

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<Club>(
        initialValue: _selectedClub,
        decoration: InputDecoration(
          labelText: 'Select Club',
          labelStyle: TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(Icons.business, color: AppColors.primary),
        ),
        dropdownColor: AppColors.surface,
        style: TextStyle(color: AppColors.textPrimary),
        items: _clubs.map((club) {
          return DropdownMenuItem(value: club, child: Text(club.name));
        }).toList(),
        onChanged: (club) {
          setState(() {
            _selectedClub = club;
            _selectedCourt = null;
            _selectedTimeSlot = null;
            _selectedDuration = null;
            _loadCourts();
          });
        },
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Selector de pista
          if (_courts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.sports_tennis, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Court>(
                      initialValue: _selectedCourt,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      dropdownColor: AppColors.surface,
                      style: TextStyle(color: AppColors.textPrimary),
                      items: _courts.map((court) {
                        return DropdownMenuItem(
                          value: court,
                          child: Text(court.name),
                        );
                      }).toList(),
                      onChanged: (court) {
                        setState(() {
                          _selectedCourt = court;
                          _loadBookingsAndSlots();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Calendario horizontal
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 10, // 10 días hacia adelante
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index));
                final isSelected =
                    DateFormat('yyyy-MM-dd').format(date) ==
                    DateFormat('yyyy-MM-dd').format(_selectedDate);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                      _selectedTimeSlot = null;
                      _selectedDuration = null;
                      _loadBookingsAndSlots();
                    });
                  },
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.background,
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
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.onPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? AppColors.onPrimary
                                : AppColors.textSecondary,
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
      ),
    );
  }

  Widget _buildAvailableOnlyToggle() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Show available slots only',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Switch(
            value: _showAvailableOnly,
            onChanged: (value) {
              setState(() => _showAvailableOnly = value);
            },
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotGrid() {
    final slots = _showAvailableOnly ? _availableSlots : _generateAllSlots();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: slots.map((slot) {
          final isSelected = _selectedTimeSlot?.startTime == slot.startTime;

          return GestureDetector(
            onTap: slot.isAvailable
                ? () {
                    setState(() {
                      _selectedTimeSlot = slot;
                      _selectedDuration = slot.availableDurations.first;
                    });
                  }
                : null,
            child: Container(
              width: (MediaQuery.of(context).size.width - 56) / 3,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : slot.isAvailable
                    ? AppColors.surface
                    : AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                slot.startTime,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppColors.onPrimary
                      : slot.isAvailable
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<TimeSlot> _generateAllSlots() {
    // Genera todos los slots posibles entre opensAt y closesAt
    // Solo para mostrar cuando _showAvailableOnly = false
    return _availableSlots; // Por ahora, usa los disponibles
  }

  Widget _buildCourtInfo() {
    if (_selectedCourt == null || _selectedTimeSlot == null) {
      return const SizedBox();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_tennis, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCourt!.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${_selectedCourt!.indoor ? 'Indoor' : 'Outdoor'} | ${_selectedCourt!.surface}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Select duration:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _selectedTimeSlot!.availableDurations.map((duration) {
                final price = _bookingService.calculatePrice(
                  durationMinutes: duration,
                  pricePerHour: _selectedCourt!.pricePerHour,
                );
                final isSelected = _selectedDuration == duration;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedDuration = duration);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withValues(alpha: 0.8),
                                ],
                              )
                            : null,
                        color: isSelected ? null : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${price.toStringAsFixed(2)} €',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppColors.onPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$duration min',
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected
                                  ? AppColors.onPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _createBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Book Court',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
