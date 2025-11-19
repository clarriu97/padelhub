import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:padelhub/colors.dart';
import 'package:padelhub/models/club.dart';
import 'package:padelhub/services/club_service.dart';
import 'package:padelhub/screens/admin/club_detail_screen.dart';

class ClubsAdminScreen extends StatefulWidget {
  const ClubsAdminScreen({super.key});

  @override
  State<ClubsAdminScreen> createState() => _ClubsAdminScreenState();
}

class _ClubsAdminScreenState extends State<ClubsAdminScreen> {
  final ClubService _clubService = ClubService();
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _timezoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _opensAtController = TextEditingController();
  final _closesAtController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  bool _hasAccessibleAccess = false;
  bool _hasParking = false;
  bool _hasShop = false;
  bool _hasCafeteria = false;
  bool _hasSnackBar = false;
  bool _hasChangingRooms = false;
  bool _hasLockers = false;
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _timezoneController.dispose();
    _addressController.dispose();
    _opensAtController.dispose();
    _closesAtController.dispose();
    _websiteController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final isAdmin = await _clubService.isUserAdmin(user.uid);
      setState(() {
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCreateClubDialog() {
    _idController.clear();
    _nameController.clear();
    _timezoneController.text = 'Europe/Madrid';
    _addressController.clear();
    _opensAtController.clear();
    _closesAtController.clear();
    _websiteController.clear();
    _phoneNumberController.clear();
    setState(() {
      _hasAccessibleAccess = false;
      _hasParking = false;
      _hasShop = false;
      _hasCafeteria = false;
      _hasSnackBar = false;
      _hasChangingRooms = false;
      _hasLockers = false;
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Create New Club',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _idController,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Club ID (e.g., pamplona)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      hintText: 'lowercase, no spaces',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a club ID';
                      }
                      if (value.contains(' ')) {
                        return 'ID cannot contain spaces';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Club Name',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      hintText: 'e.g., PadelHub Pamplona',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a club name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _timezoneController,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Timezone',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      hintText: 'e.g., Europe/Madrid',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a timezone';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Address (optional)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      hintText: 'e.g., Calle Mayor 123',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _opensAtController,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Opens At (optional)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      hintText: 'e.g., 08:00',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _closesAtController,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Closes At (optional)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      hintText: 'e.g., 23:00',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _websiteController,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Website (optional)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      hintText: 'e.g., https://example.com',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneNumberController,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Phone Number (optional)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      hintText: 'e.g., +34 123 456 789',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Facilities & Amenities',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: Text(
                      'Accessible Access',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      'For people with reduced mobility',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    value: _hasAccessibleAccess,
                    onChanged: (value) {
                      setDialogState(() => _hasAccessibleAccess = value!);
                    },
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text(
                      'Parking',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    value: _hasParking,
                    onChanged: (value) {
                      setDialogState(() => _hasParking = value!);
                    },
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text(
                      'Shop',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    value: _hasShop,
                    onChanged: (value) {
                      setDialogState(() => _hasShop = value!);
                    },
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text(
                      'Cafeteria',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    value: _hasCafeteria,
                    onChanged: (value) {
                      setDialogState(() => _hasCafeteria = value!);
                    },
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text(
                      'Snack Bar',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    value: _hasSnackBar,
                    onChanged: (value) {
                      setDialogState(() => _hasSnackBar = value!);
                    },
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text(
                      'Changing Rooms',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    value: _hasChangingRooms,
                    onChanged: (value) {
                      setDialogState(() => _hasChangingRooms = value!);
                    },
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text(
                      'Lockers',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    value: _hasLockers,
                    onChanged: (value) {
                      setDialogState(() => _hasLockers = value!);
                    },
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    await _clubService.createClub(
                      id: _idController.text.trim().toLowerCase(),
                      name: _nameController.text.trim(),
                      timezone: _timezoneController.text.trim(),
                      address: _addressController.text.trim().isEmpty
                          ? null
                          : _addressController.text.trim(),
                      opensAt: _opensAtController.text.trim().isEmpty
                          ? null
                          : _opensAtController.text.trim(),
                      closesAt: _closesAtController.text.trim().isEmpty
                          ? null
                          : _closesAtController.text.trim(),
                      website: _websiteController.text.trim().isEmpty
                          ? null
                          : _websiteController.text.trim(),
                      phoneNumber: _phoneNumberController.text.trim().isEmpty
                          ? null
                          : _phoneNumberController.text.trim(),
                      hasAccessibleAccess: _hasAccessibleAccess,
                      hasParking: _hasParking,
                      hasShop: _hasShop,
                      hasCafeteria: _hasCafeteria,
                      hasSnackBar: _hasSnackBar,
                      hasChangingRooms: _hasChangingRooms,
                      hasLockers: _hasLockers,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Club created successfully!'),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating club: \$e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'Admin Access Required',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You do not have permission to access this page.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<Club>>(
          stream: _clubService.getClubs(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final clubs = snapshot.data!;

            if (clubs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.business,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No clubs yet',
                      style: TextStyle(
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first club to get started',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: clubs.length,
              itemBuilder: (context, index) {
                final club = clubs[index];
                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClubDetailScreen(club: club),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Icon(Icons.business, color: AppColors.primary),
                    ),
                    title: Text(
                      club.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID: ${club.id}',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(
                          'Timezone: ${club.timezone}',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        if (club.opensAt != null)
                          Text(
                            'Opens: ${club.opensAt}',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateClubDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add Club'),
      ),
    );
  }
}
