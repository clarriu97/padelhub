import 'package:flutter/material.dart';
import 'package:padelhub/colors.dart';
import 'package:padelhub/models/club.dart';

class ClubInfoScreen extends StatelessWidget {
  final Club club;

  const ClubInfoScreen({super.key, required this.club});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Contact Information'),
            const SizedBox(height: 8),
            if (club.phoneNumber != null)
              _buildInfoRow(Icons.phone, club.phoneNumber!),
            if (club.website != null)
              _buildInfoRow(Icons.language, club.website!),
            if (club.opensAt != null && club.closesAt != null)
              _buildInfoRow(
                Icons.access_time,
                '${club.opensAt} - ${club.closesAt}',
              ),

            const SizedBox(height: 24),
            _buildSectionTitle('Amenities'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                if (club.hasAccessibleAccess)
                  _buildAmenity(Icons.accessible, 'Accessible'),
                if (club.hasParking)
                  _buildAmenity(Icons.local_parking, 'Parking'),
                if (club.hasShop) _buildAmenity(Icons.shopping_bag, 'Shop'),
                if (club.hasCafeteria) _buildAmenity(Icons.coffee, 'Cafeteria'),
                if (club.hasSnackBar)
                  _buildAmenity(Icons.fastfood, 'Snack Bar'),
                if (club.hasChangingRooms)
                  _buildAmenity(Icons.checkroom, 'Changing Rooms'),
                if (club.hasLockers) _buildAmenity(Icons.lock, 'Lockers'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenity(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
