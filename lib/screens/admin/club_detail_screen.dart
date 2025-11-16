import 'package:flutter/material.dart';
import 'package:padelhub/colors.dart';
import 'package:padelhub/models/club.dart';
import 'package:padelhub/models/court.dart';
import 'package:padelhub/services/club_service.dart';
import 'package:padelhub/services/court_service.dart';

class ClubDetailScreen extends StatefulWidget {
  final Club club;

  const ClubDetailScreen({super.key, required this.club});

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  final ClubService _clubService = ClubService();
  final CourtService _courtService = CourtService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _timezoneController;
  late TextEditingController _addressController;
  late TextEditingController _opensAtController;
  late TextEditingController _closesAtController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.club.name);
    _timezoneController = TextEditingController(text: widget.club.timezone);
    _addressController = TextEditingController(text: widget.club.address ?? '');
    _opensAtController = TextEditingController(text: widget.club.opensAt ?? '');
    _closesAtController = TextEditingController(
      text: widget.club.closesAt ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timezoneController.dispose();
    _addressController.dispose();
    _opensAtController.dispose();
    _closesAtController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedClub = Club(
        id: widget.club.id,
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
      );

      await _clubService.updateClub(updatedClub);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating club: $e')));
      }
    }
  }

  Future<void> _deleteClub() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Club',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.club.name}"? This will also delete all courts associated with this club.',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _clubService.deleteClub(widget.club.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Club deleted successfully!')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting club: $e')));
        }
      }
    }
  }

  void _showAddCourtDialog() {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final surfaceController = TextEditingController(text: 'artificial grass');
    final descriptionController = TextEditingController();
    bool isIndoor = true;
    bool hasLighting = true;
    bool hasAirConditioning = true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Add Court',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: idController,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Court ID (e.g., court1)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      hintText: 'lowercase, no spaces',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a court ID';
                      }
                      if (value.contains(' ')) {
                        return 'ID cannot contain spaces';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Court Name',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      hintText: 'e.g., Court 1',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a court name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: surfaceController,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Surface Type',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      hintText: 'e.g., artificial grass, concrete',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a surface type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    style: TextStyle(color: AppColors.textPrimary),
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      hintText: 'Additional details',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(
                      'Indoor',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    value: isIndoor,
                    onChanged: (value) {
                      setDialogState(() => isIndoor = value);
                    },
                    activeTrackColor: AppColors.primary,
                  ),
                  SwitchListTile(
                    title: Text(
                      'Has Lighting',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    value: hasLighting,
                    onChanged: (value) {
                      setDialogState(() => hasLighting = value);
                    },
                    activeTrackColor: AppColors.primary,
                  ),
                  SwitchListTile(
                    title: Text(
                      'Has Air Conditioning',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    value: hasAirConditioning,
                    onChanged: (value) {
                      setDialogState(() => hasAirConditioning = value);
                    },
                    activeTrackColor: AppColors.primary,
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
                if (formKey.currentState!.validate()) {
                  try {
                    await _courtService.createCourt(
                      clubId: widget.club.id,
                      id: idController.text.trim().toLowerCase(),
                      name: nameController.text.trim(),
                      surface: surfaceController.text.trim(),
                      indoor: isIndoor,
                      hasLighting: hasLighting,
                      hasAirConditioning: hasAirConditioning,
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Court created successfully!'),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating court: \$e')),
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

  Future<void> _deleteCourt(Court court) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Court',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${court.name}"?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _courtService.deleteCourt(widget.club.id, court.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Court deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting court: $e')));
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
        title: Text(widget.club.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteClub,
            tooltip: 'Delete club',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Club Info Card
                    Card(
                      color: AppColors.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.business,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Club Information',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Club ID (read-only)
                            Text(
                              'Club ID',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                widget.club.id,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Club Name
                            TextFormField(
                              controller: _nameController,
                              style: TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Club Name',
                                labelStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                hintText: 'e.g., PadelHub Pamplona',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: AppColors.background,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a club name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Timezone
                            TextFormField(
                              controller: _timezoneController,
                              style: TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Timezone',
                                labelStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                hintText: 'e.g., Europe/Madrid',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: AppColors.background,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a timezone';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Address
                            TextFormField(
                              controller: _addressController,
                              style: TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Address (optional)',
                                labelStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                hintText: 'e.g., Calle Mayor 123',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: AppColors.background,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Opens At
                            TextFormField(
                              controller: _opensAtController,
                              style: TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Opens At (optional)',
                                labelStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                hintText: 'e.g., 08:00',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: AppColors.background,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Closes At
                            TextFormField(
                              controller: _closesAtController,
                              style: TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Closes At (optional)',
                                labelStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                hintText: 'e.g., 23:00',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: AppColors.background,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Courts Section
                    Card(
                      color: AppColors.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.sports_tennis,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Courts',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle),
                                  color: AppColors.primary,
                                  onPressed: _showAddCourtDialog,
                                  tooltip: 'Add court',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            StreamBuilder<List<Court>>(
                              stream: _courtService.getCourts(widget.club.id),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Text(
                                    'Error: ${snapshot.error}',
                                    style: const TextStyle(color: Colors.red),
                                  );
                                }

                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final courts = snapshot.data!;

                                if (courts.isEmpty) {
                                  return Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.sports_tennis,
                                          size: 48,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No courts yet',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap + to add a court',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: courts.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final court = courts[index];
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.textSecondary
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            court.indoor
                                                ? Icons.home
                                                : Icons.wb_sunny,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  court.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${court.surface} • ${court.indoor ? 'Indoor' : 'Outdoor'}',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                if (court.hasLighting == true)
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.lightbulb,
                                                        size: 14,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Has lighting',
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .textSecondary,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                if (court.hasAirConditioning)
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.ac_unit,
                                                        size: 14,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Air conditioning',
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .textSecondary,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 20,
                                            ),
                                            color: Colors.red,
                                            onPressed: () =>
                                                _deleteCourt(court),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
