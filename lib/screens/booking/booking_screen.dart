import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:padelhub/colors.dart';
import 'package:padelhub/models/club.dart';
import 'package:padelhub/models/court.dart';
import 'package:padelhub/models/booking.dart';
import 'package:padelhub/models/time_slot.dart';
import 'package:padelhub/models/court_availability.dart';
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
  DateTime _selectedDate = DateTime.now();
  TimeSlot? _selectedTimeSlot;
  CourtAvailability? _selectedCourtAvailability;
  int? _selectedDuration;
  bool _showAvailableOnly = true;
  bool _isLoading = false;

  List<Club> _clubs = [];
  List<Court> _courts = [];
  Map<String, List<Booking>> _bookingsByCourtId = {};
  List<TimeSlot> _availableSlots = [];
  List<CourtAvailability> _availableCourts = [];

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

    _courtService.getCourts(_selectedClub!.id).listen((courts) async {
      setState(() {
        _courts = courts;
      });
      
      if (_courts.isNotEmpty) {
        await _loadBookingsAndSlots();
      }
    });
  }

  Future<void> _loadBookingsAndSlots() async {
    if (_selectedClub == null || _courts.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // Obtener todas las reservas de todas las pistas
      _bookingsByCourtId = await _bookingService.getClubBookingsForDate(
        clubId: _selectedClub!.id,
        courts: _courts,
        date: dateStr,
      );

      // Calcular slots disponibles considerando todas las pistas
      _availableSlots = _bookingService.calculateAvailableTimeSlots(
        bookingsByCourtId: _bookingsByCourtId,
        courts: _courts,
        opensAt: _selectedClub!.opensAt ?? '08:00',
        closesAt: _selectedClub!.closesAt ?? '23:00',
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading availability: $e')),
        );
      }
    }
  }

  Future<void> _createBooking() async {
    if (_selectedClub == null ||
        _selectedCourtAvailability == null ||
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
        pricePerHour: _selectedCourtAvailability!.court.pricePerHour,
      );

      await _bookingService.createBooking(
        clubId: _selectedClub!.id,
        courtId: _selectedCourtAvailability!.court.id,
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
          _selectedCourtAvailability = null;
          _selectedDuration = null;
          _availableCourts = [];
        });
        // Reload bookings
        await _loadBookingsAndSlots();
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

                // Club information section
                if (_selectedClub != null) _buildClubInfo(),

                // Selector de fecha con calendario horizontal
                _buildDateSelector(),

                // Toggle para mostrar solo slots disponibles
                _buildAvailableOnlyToggle(),

                // Grid de slots de tiempo
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  )
                else
                  _buildTimeSlotGrid(),

                // Mostrar pistas disponibles cuando se selecciona un horario
                if (_selectedTimeSlot != null && _availableCourts.isEmpty)
                  _loadAvailableCourtsForSelectedTime(),
                
                if (_selectedTimeSlot != null && _availableCourts.isNotEmpty)
                  _buildAvailableCourtsSection(),

                // Información de la pista seleccionada y duración
                if (_selectedCourtAvailability != null) _buildDurationSelector(),

                // Botón de reserva
                if (_selectedCourtAvailability != null && _selectedDuration != null)
                  _buildBookButton(),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadAvailableCourtsForSelectedTime() {
    // Load available courts when time slot is selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedTimeSlot != null && _availableCourts.isEmpty) {
        setState(() {
          _availableCourts = _bookingService.getAvailableCourtsForTimeSlot(
            timeSlot: _selectedTimeSlot!.startTime,
            bookingsByCourtId: _bookingsByCourtId,
            courts: _courts,
            closesAt: _selectedClub!.closesAt ?? '23:00',
          );
        });
      }
    });
    return const SizedBox.shrink();
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
            _selectedTimeSlot = null;
            _selectedCourtAvailability = null;
            _selectedDuration = null;
            _availableCourts = [];
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
                      _selectedCourtAvailability = null;
                      _selectedDuration = null;
                      _availableCourts = [];
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
                      _selectedCourtAvailability = null;
                      _selectedDuration = null;
                      
                      // Cargar pistas disponibles para este horario
                      _availableCourts = _bookingService.getAvailableCourtsForTimeSlot(
                        timeSlot: slot.startTime,
                        bookingsByCourtId: _bookingsByCourtId,
                        courts: _courts,
                        closesAt: _selectedClub!.closesAt ?? '23:00',
                      );
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

  Widget _buildAvailableCourtsSection() {
    if (_availableCourts.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.schedule, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Available courts at ${_selectedTimeSlot!.startTime}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        ..._availableCourts.map((courtAvailability) {
          final isSelected = _selectedCourtAvailability?.court.id == 
              courtAvailability.court.id;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCourtAvailability = courtAvailability;
                _selectedDuration = courtAvailability.availableDurations.first;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.sports_tennis,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          courtAvailability.court.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${courtAvailability.court.indoor ? 'Indoor' : 'Outdoor'} | ${courtAvailability.court.surface}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDurationSelector() {
    if (_selectedCourtAvailability == null) return const SizedBox();

    return Card(
      margin: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select duration:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _selectedCourtAvailability!.availableDurations.map((duration) {
                final price = _selectedCourtAvailability!.getPriceForDuration(duration);
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

  Widget _buildClubInfo() {
    if (_selectedClub == null) return const SizedBox();

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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.business,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedClub!.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_selectedClub!.address != null)
                        Text(
                          _selectedClub!.address!,
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

            // Horario
            if (_selectedClub!.opensAt != null ||
                _selectedClub!.closesAt != null)
              _buildInfoRow(
                Icons.schedule,
                'Hours',
                '${_selectedClub!.opensAt ?? 'N/A'} - ${_selectedClub!.closesAt ?? 'N/A'}',
              ),

            // Teléfono
            if (_selectedClub!.phoneNumber != null)
              _buildInfoRow(Icons.phone, 'Phone', _selectedClub!.phoneNumber!),

            // Website
            if (_selectedClub!.website != null)
              _buildInfoRow(Icons.language, 'Website', _selectedClub!.website!),

            // Facilities
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_selectedClub!.hasParking) _buildFacilityChip('Parking'),
                if (_selectedClub!.hasAccessibleAccess)
                  _buildFacilityChip('Accessible'),
                if (_selectedClub!.hasShop) _buildFacilityChip('Shop'),
                if (_selectedClub!.hasCafeteria)
                  _buildFacilityChip('Cafeteria'),
                if (_selectedClub!.hasSnackBar) _buildFacilityChip('Snack Bar'),
                if (_selectedClub!.hasChangingRooms)
                  _buildFacilityChip('Changing Rooms'),
                if (_selectedClub!.hasLockers) _buildFacilityChip('Lockers'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
