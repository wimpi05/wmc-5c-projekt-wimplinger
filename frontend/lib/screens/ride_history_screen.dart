import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/ride.dart';
import '../providers/ride_provider.dart';
import '../providers/user_provider.dart';

enum HistoryPeriod { all, last7, last30, last90 }

enum HistoryRole { all, driver, passenger }

const double _kUnifiedHeaderHeight = 108;
const double _kUnifiedHeaderTitleSize = 28;
const double _kUnifiedHeaderSubtitleSize = 13;
const double _kUnifiedHeaderTitleSubtitleGap = 4;
const double _kUnifiedHeaderLeftInset = 24;

class RideHistoryScreen extends StatefulWidget {
	final bool embedded;

	const RideHistoryScreen({super.key, this.embedded = true});

	@override
	State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
	HistoryPeriod _selectedPeriod = HistoryPeriod.last30;
	HistoryRole _selectedRole = HistoryRole.all;

	@override
	Widget build(BuildContext context) {
		final content = _buildContent(context);
		if (widget.embedded) return content;

		return Scaffold(
			backgroundColor: Theme.of(context).scaffoldBackgroundColor,
			body: content,
		);
	}

	Widget _buildContent(BuildContext context) {
		final rideProvider = context.watch<RideProvider>();
		final userProvider = context.watch<UserProvider>();
		final currentUserId = userProvider.currentUser?.id;
		final topInset = MediaQuery.of(context).padding.top;
		final primary = Theme.of(context).colorScheme.primary;
		final scheme = Theme.of(context).colorScheme;

		final now = DateTime.now();
		final allPastRides = rideProvider.rides.where((ride) => ride.departTime.isBefore(now)).toList()
			..sort((a, b) => b.departTime.compareTo(a.departTime));

		final filtered = allPastRides.where((ride) {
			if (_selectedPeriod != HistoryPeriod.all) {
				final from = _periodStart(now, _selectedPeriod);
				if (from != null && ride.departTime.isBefore(from)) return false;
			}

			if (_selectedRole == HistoryRole.driver) {
				return currentUserId != null && ride.driverUserId == currentUserId;
			}

			if (_selectedRole == HistoryRole.passenger) {
				return currentUserId != null && ride.driverUserId != currentUserId && ride.currentUserJoined;
			}

			return true;
		}).toList();

		final totalRides = filtered.length;
		final totalKm = filtered.fold<double>(0, (sum, ride) => sum + (ride.distanceKm ?? 0));
		final savedCo2Kg = totalKm * 0.12;

		return Column(
			children: [
				Container(
					width: double.infinity,
					color: primary,
					height: topInset + _kUnifiedHeaderHeight,
					padding: EdgeInsets.only(top: topInset),
					child: const Padding(
						padding: EdgeInsets.fromLTRB(_kUnifiedHeaderLeftInset, 0, 16, 0),
						child: Align(
							alignment: Alignment.centerLeft,
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								mainAxisAlignment: MainAxisAlignment.center,
								children: [
									Text(
										'Ride History',
										style: TextStyle(fontWeight: FontWeight.w700, fontSize: _kUnifiedHeaderTitleSize, color: Colors.white),
									),
									SizedBox(height: _kUnifiedHeaderTitleSubtitleGap),
									Text(
										'Your past commutes',
										style: TextStyle(fontSize: _kUnifiedHeaderSubtitleSize, color: Colors.white70),
									),
								],
							),
						),
					),
				),
				Container(
					width: double.infinity,
					color: scheme.surfaceContainerLow,
					padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
					child: Row(
						children: [
							Expanded(
								child: _buildFilterDropdown<HistoryRole>(
									value: _selectedRole,
									items: const {
										HistoryRole.all: 'Alle Gruppenfahrten',
										HistoryRole.driver: 'Als Fahrer',
										HistoryRole.passenger: 'Als Mitfahrer',
									},
									onChanged: (value) => setState(() => _selectedRole = value),
								),
							),
							const SizedBox(width: 8),
							Expanded(
								child: _buildFilterDropdown<HistoryPeriod>(
									value: _selectedPeriod,
									items: const {
										HistoryPeriod.all: 'Gesamte Zeit',
										HistoryPeriod.last7: 'Letzte 7 Tage',
										HistoryPeriod.last30: 'Letzte 30 Tage',
										HistoryPeriod.last90: 'Letzte 90 Tage',
									},
									onChanged: (value) => setState(() => _selectedPeriod = value),
								),
							),
						],
					),
				),
				Padding(
					padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
					child: Row(
						children: [
							Expanded(child: _buildStatCard('${totalRides}', 'Fahrten', const Color(0xFF5362C2))),
							const SizedBox(width: 8),
							Expanded(child: _buildStatCard(totalKm.toStringAsFixed(1), 'KM', const Color(0xFF76B788))),
							const SizedBox(width: 8),
							Expanded(child: _buildStatCard(savedCo2Kg.toStringAsFixed(1), 'kg CO₂', const Color(0xFF6B63C8))),
						],
					),
				),
				Expanded(
					child: rideProvider.isLoading && rideProvider.rides.isEmpty
							? const Center(child: CircularProgressIndicator())
							: filtered.isEmpty
									?
									const Center(
											child: Text(
												'Keine Fahrten für diesen Filter gefunden.',
												style: TextStyle(color: Colors.grey),
											),
										)
									: ListView.separated(
											padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
											itemCount: filtered.length,
											separatorBuilder: (_, __) => const SizedBox(height: 10),
											itemBuilder: (context, index) {
												final ride = filtered[index];
												final isDriver = currentUserId != null && ride.driverUserId == currentUserId;
												return _buildHistoryRideCard(ride, isDriver);
											},
										),
				),
			],
		);
	}

	DateTime? _periodStart(DateTime now, HistoryPeriod period) {
		switch (period) {
			case HistoryPeriod.last7:
				return now.subtract(const Duration(days: 7));
			case HistoryPeriod.last30:
				return now.subtract(const Duration(days: 30));
			case HistoryPeriod.last90:
				return now.subtract(const Duration(days: 90));
			case HistoryPeriod.all:
				return null;
		}
	}

	Widget _buildFilterDropdown<T>({
		required T value,
		required Map<T, String> items,
		required ValueChanged<T> onChanged,
	}) {
		final scheme = Theme.of(context).colorScheme;
		return Container(
			height: 36,
			padding: const EdgeInsets.symmetric(horizontal: 10),
			decoration: BoxDecoration(
				color: scheme.surfaceContainerHighest,
				borderRadius: BorderRadius.circular(12),
			),
			child: DropdownButtonHideUnderline(
				child: DropdownButton<T>(
					value: value,
					isExpanded: true,
					icon: const Icon(Icons.keyboard_arrow_down, size: 18),
					style: TextStyle(color: scheme.onSurface, fontSize: 11),
					items: items.entries
							.map((entry) => DropdownMenuItem<T>(value: entry.key, child: Text(entry.value)))
							.toList(),
					onChanged: (next) {
						if (next != null) onChanged(next);
					},
				),
			),
		);
	}

	Widget _buildStatCard(String value, String label, Color accent) {
		final scheme = Theme.of(context).colorScheme;
		return Container(
			padding: const EdgeInsets.symmetric(vertical: 11),
			decoration: BoxDecoration(
				color: scheme.surfaceContainer,
				borderRadius: BorderRadius.circular(11),
			),
			child: Column(
				children: [
					Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: accent)),
					const SizedBox(height: 2),
					Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
				],
			),
		);
	}

	Widget _buildHistoryRideCard(Ride ride, bool isDriver) {
		final isPassenger = !isDriver && ride.currentUserJoined;
		final distance = ride.distanceKm ?? 0;
		final primary = Theme.of(context).colorScheme.primary;
		final scheme = Theme.of(context).colorScheme;
		return Container(
			decoration: BoxDecoration(
				color: scheme.surface,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: scheme.outlineVariant),
			),
			child: Padding(
				padding: const EdgeInsets.all(12),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Row(
							children: [
								Container(
									padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
									decoration: BoxDecoration(
										color: isDriver
											? scheme.primaryContainer
											: isPassenger
												? scheme.tertiaryContainer
												: scheme.surfaceContainerHighest,
										borderRadius: BorderRadius.circular(999),
									),
									child: Text(
										isDriver ? 'Fahrer' : isPassenger ? 'Mitfahrer' : 'Gruppenfahrt',
										style: TextStyle(
											color: isDriver ? primary : isPassenger ? scheme.tertiary : scheme.onSurfaceVariant,
											fontSize: 11,
											fontWeight: FontWeight.w700,
										),
									),
								),
								const Spacer(),
								if (ride.groupName != null && ride.groupName!.isNotEmpty)
									Padding(
										padding: const EdgeInsets.only(right: 8),
										child: Text(
											ride.groupName!,
											style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
										),
									),
								Text(
									'${distance.toStringAsFixed(1)} km',
									style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
								),
							],
						),
						const SizedBox(height: 10),
						Row(
							children: [
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											_historyLine(Icons.my_location_outlined, 'Von', ride.startName, const Color(0xFF5662C4)),
											const SizedBox(height: 8),
											_historyLine(Icons.place_outlined, 'Nach', ride.endName, const Color(0xFF53A95D)),
											const SizedBox(height: 8),
											Row(
												children: [
													const Icon(Icons.access_time, size: 14, color: Color(0xFF8B90A1)),
													const SizedBox(width: 5),
													Text(
														DateFormat('dd.MM.yyyy, HH:mm').format(ride.departTime),
														style: const TextStyle(fontSize: 12, color: Color(0xFF8B90A1)),
													),
												],
											),
										],
									),
								),
								const SizedBox(width: 8),
								SizedBox(
									height: 52,
									width: 52,
									child: Stack(
										alignment: Alignment.center,
										children: [
											CircularProgressIndicator(
												value: ride.occupancyRate,
												strokeWidth: 5,
												backgroundColor: const Color(0xFFF0F1F5),
												color: ride.isFull
														? Colors.red
														: (ride.seatsAvailable <= 1 ? Colors.orange : const Color(0xFF60B76C)),
											),
											Column(
												mainAxisSize: MainAxisSize.min,
												children: [
													Text('${ride.seatsAvailable}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
													const Text('frei', style: TextStyle(fontSize: 9, color: Color(0xFF8B90A1), height: 0.8)),
												],
											),
										],
									),
								),
							],
						),
					],
				),
			),
		);
	}

	Widget _historyLine(IconData icon, String label, String value, Color iconColor) {
		return Row(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Icon(icon, size: 14, color: iconColor),
				const SizedBox(width: 6),
				Expanded(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8B90A1))),
							Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF30384A))),
						],
					),
				),
			],
		);
	}
}
