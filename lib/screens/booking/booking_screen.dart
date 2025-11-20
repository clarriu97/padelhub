import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:padelhub/colors.dart';
import 'package:padelhub/models/club.dart';
import 'package:padelhub/models/court.dart';
import 'package:padelhub/models/booking.dart';
import 'package:padelhub/models/time_slot.dart';
import 'package:padelhub/models/court_availability.dart';
import 'package:padelhub/services/court_service.dart';
import 'package:padelhub/services/booking_service.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  final Club club;
  final CourtService? courtService;
  final BookingService? bookingService;

  const BookingScreen({
    super.key,
    required this.club,
    this.courtService,
    this.bookingService,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late final CourtService _courtService;
  late final BookingService _bookingService;

  DateTime _selectedDate = DateTime.now();
  TimeSlot? _selectedTimeSlot;
  CourtAvailability? _selectedCourtAvailability;
  int? _selectedDuration;
  bool _showAvailableOnly = true;
  bool _isLoading = false;
  bool _enableSharing = false;

  List<Court> _courts = [];
  Map<String, List<Booking>> _bookingsByCourtId = {};
  List<TimeSlot> _availableSlots = [];
  List<CourtAvailability> _availableCourts = [];

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
          await _loadBookingsAndSlots();
        }
      }
    });
  }

  Future<void> _loadBookingsAndSlots() async {
    if (_courts.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // Obtener todas las reservas de todas las pistas
      _bookingsByCourtId = await _bookingService.getClubBookingsForDate(
        clubId: widget.club.id,
        courts: _courts,
        date: dateStr,
      );

      // Calcular slots disponibles considerando todas las pistas
      _availableSlots = _bookingService.calculateAvailableTimeSlots(
        bookingsByCourtId: _bookingsByCourtId,
        courts: _courts,
        opensAt: widget.club.opensAt ?? '08:00',
        closesAt: widget.club.closesAt ?? '23:00',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading availability: $e')),
        );
      }
    }
  }

  Future<void> _createBooking() async {
    if (_selectedCourtAvailability == null ||
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
        clubId: widget.club.id,
        courtId: _selectedCourtAvailability!.court.id,
        userId: user.uid,
        date: dateStr,
        startTime: _selectedTimeSlot!.startTime,
        durationMinutes: _selectedDuration!,
        players: [user.email ?? 'Player 1'],
        price: price,
        sharingEnabled: _enableSharing,
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
          _enableSharing = false;
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Selector de fecha con calendario horizontal
        _buildDateSelector(),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
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
                if (_selectedCourtAvailability != null)
                  _buildDurationSelector(),

                // Sharing toggle
                if (_selectedCourtAvailability != null &&
                    _selectedDuration != null)
                  _buildSharingToggle(),

                // Botón de reserva
                if (_selectedCourtAvailability != null &&
                    _selectedDuration != null)
                  _buildBookButton(),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
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
            closesAt: widget.club.closesAt ?? '23:00',
          );
        });
      }
    });
    return const SizedBox.shrink();
  }

  Widget _buildDateSelector() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: 70,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 14, // 2 weeks
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
                });
                _loadBookingsAndSlots();
              },
              child: Container(
                width: 50,
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
                        fontSize: 11,
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
                        fontSize: 18,
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

  Widget _buildAvailableOnlyToggle() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Show available slots only',
            style: TextStyle(
              fontSize: 14,
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

    if (slots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No slots available for this date',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
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
                      _availableCourts = _bookingService
                          .getAvailableCourtsForTimeSlot(
                            timeSlot: slot.startTime,
                            bookingsByCourtId: _bookingsByCourtId,
                            courts: _courts,
                            closesAt: widget.club.closesAt ?? '23:00',
                          );
                    });
                  }
                : null,
            child: Container(
              width: (MediaQuery.of(context).size.width - 32 - 20) / 5,
              padding: const EdgeInsets.symmetric(vertical: 10),
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
                  fontSize: 13,
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
    // Por simplicidad, devolvemos los disponibles + los no disponibles si los tuviéramos
    // Pero _availableSlots ya debería tener todos si calculateAvailableTimeSlots lo hiciera
    // Revisando la implementación original, parece que calculateAvailableTimeSlots devuelve solo disponibles?
    // No, devuelve TimeSlot que tiene isAvailable.
    // Si _availableSlots solo tiene disponibles, entonces necesitamos lógica para generar todos.
    // Asumiremos que _availableSlots contiene todos los slots con su estado isAvailable.
    return _availableSlots;
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        ..._availableCourts.map((courtAvailability) {
          final isSelected =
              _selectedCourtAvailability?.court.id ==
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
              padding: const EdgeInsets.all(12),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.sports_tennis,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          courtAvailability.court.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${courtAvailability.court.indoor ? 'Indoor' : 'Outdoor'} | ${courtAvailability.court.surface}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select duration:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _selectedCourtAvailability!.availableDurations.map((
                duration,
              ) {
                final price = _selectedCourtAvailability!.getPriceForDuration(
                  duration,
                );
                final isSelected = _selectedDuration == duration;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedDuration = duration);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(12),
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
                              fontSize: 18,
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
                              fontSize: 12,
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

  Widget _buildSharingToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SwitchListTile(
        title: const Text('Allow others to join?'),
        subtitle: const Text('Make this booking open for other players'),
        value: _enableSharing,
        onChanged: (bool value) {
          setState(() {
            _enableSharing = value;
          });
        },
        activeTrackColor: AppColors.primary,
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
            elevation: 4,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'BOOK NOW',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
