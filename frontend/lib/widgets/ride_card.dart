import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ride.dart';

class RideCard extends StatelessWidget {
  final Ride ride;
  final int? currentUserId;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RideCard({
    super.key,
    required this.ride,
    this.currentUserId,
    this.onJoin,
    this.onLeave,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDriver = currentUserId != null && ride.driverUserId == currentUserId;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildLocationRow(Icons.radio_button_checked, 'Von', ride.startName, scheme.primary, scheme),
                      const SizedBox(height: 12),
                      _buildLocationRow(Icons.location_on, 'Nach', ride.endName, scheme.tertiary, scheme),
                    ],
                  ),
                ),
                _buildSeatIndicator(scheme),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(ride.departTime),
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),

            Text(
              isDriver ? 'Du (Fahrer)' : ride.driverUsername,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),

            _buildActionButtons(isDriver, scheme),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final dateStr = ride.isToday ? 'Heute' : DateFormat('dd.MM.').format(dateTime);
    final timeStr = DateFormat('HH:mm').format(dateTime);
    return '$dateStr, $timeStr';
  }

  Widget _buildLocationRow(IconData icon, String label, String value, Color color, ColorScheme scheme) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: scheme.onSurface),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeatIndicator(ColorScheme scheme) {
    Color indicatorColor = ride.seatsAvailable > 1 ? Colors.green : Colors.orange;
    if (ride.isFull) indicatorColor = Colors.red;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 65,
          width: 65,
          child: CircularProgressIndicator(
            value: ride.occupancyRate,
            backgroundColor: scheme.surfaceContainerHighest,
            color: indicatorColor,
            strokeWidth: 7,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${ride.seatsAvailable}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text(
              'frei',
              style: TextStyle(fontSize: 10, color: Colors.grey, height: 0.8),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDriver, ColorScheme scheme) {
    if (isDriver) {
      return Row(
        children: [
          _actionButton(
            'Bearbeiten',
            Icons.edit_outlined,
            scheme.primaryContainer,
            scheme.primary,
            onEdit,
          ),
          const SizedBox(width: 12),
          _actionButton(
            'Löschen',
            Icons.delete_outline,
            scheme.errorContainer,
            scheme.error,
            onDelete,
          ),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: ride.currentUserJoined ? onLeave : (ride.isFull ? null : onJoin),
        icon: Icon(
          ride.currentUserJoined ? Icons.exit_to_app : Icons.person_add_alt_outlined,
          size: 18,
        ),
        label: Text(ride.isFull ? 'Voll' : ride.currentUserJoined ? 'Fahrt verlassen' : 'Fahrt beitreten'),
        style: ElevatedButton.styleFrom(
          backgroundColor: ride.currentUserJoined ? scheme.errorContainer : scheme.primary,
          foregroundColor: ride.currentUserJoined ? scheme.error : scheme.onPrimary,
          disabledBackgroundColor: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color bg,
    Color textColor,
    VoidCallback? onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: textColor.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}