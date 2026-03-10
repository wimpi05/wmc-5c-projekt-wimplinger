import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ride.dart';
import '../providers/ride_provider.dart';
import '../providers/user_provider.dart';

const double _kUnifiedHeaderHeight = 108;
const double _kUnifiedHeaderTitleSize = 28;
const double _kUnifiedHeaderSubtitleSize = 13;
const double _kUnifiedHeaderTitleSubtitleGap = 4;
const double _kUnifiedHeaderLeftInset = 24;

class CreateRideScreen extends StatefulWidget {
	const CreateRideScreen({super.key});

	@override
	State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
	final _formKey = GlobalKey<FormState>();
	final _startController = TextEditingController();
	final _destinationController = TextEditingController();
	final _dateController = TextEditingController();
	final _timeController = TextEditingController();
	final _seatsController = TextEditingController(text: '4');
	final _priceController = TextEditingController();
	final _noteController = TextEditingController();

	DateTime? _selectedDate;
	TimeOfDay? _selectedTime;
	bool _isSubmitting = false;

	@override
	void dispose() {
		_startController.dispose();
		_destinationController.dispose();
		_dateController.dispose();
		_timeController.dispose();
		_seatsController.dispose();
		_priceController.dispose();
		_noteController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final userProvider = context.watch<UserProvider>();
		final currentUser = userProvider.currentUser;
		final bool hasUsername = (currentUser?.name.trim().isNotEmpty ?? false);
		final topInset = MediaQuery.of(context).padding.top;
		final primary = Theme.of(context).colorScheme.primary;

		return Scaffold(
			backgroundColor: const Color(0xFFF5F7FA),
			body: Column(
				children: [
					Container(
						width: double.infinity,
						height: topInset + _kUnifiedHeaderHeight,
						padding: EdgeInsets.only(top: topInset),
						decoration: BoxDecoration(color: primary),
						child: const Padding(
							padding: EdgeInsets.fromLTRB(_kUnifiedHeaderLeftInset, 0, 16, 0),
							child: Align(
								alignment: Alignment.centerLeft,
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									mainAxisAlignment: MainAxisAlignment.center,
									children: [
										Text('Fahrt erstellen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: _kUnifiedHeaderTitleSize)),
										SizedBox(height: _kUnifiedHeaderTitleSubtitleGap),
										Text('Teile deine Strecke', style: TextStyle(color: Colors.white70, fontSize: _kUnifiedHeaderSubtitleSize)),
									],
								),
							),
						),
					),
					Expanded(
						child: SingleChildScrollView(
							padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
							child: Form(
								key: _formKey,
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
								if (!hasUsername) _buildProfileRequiredCard(),
								_buildSectionLabel(Icons.my_location_outlined, 'Startort'),
								_buildTextField(
									controller: _startController,
									hint: 'Startort eingeben',
									validator: (value) {
										if (value == null || value.trim().isEmpty) {
											return 'Startort ist ein Pflichtfeld.';
										}
										return null;
									},
								),
								const SizedBox(height: 12),
								_buildSectionLabel(Icons.place_outlined, 'Zielort'),
								_buildTextField(
									controller: _destinationController,
									hint: 'Ziel eingeben',
									validator: (value) {
										if (value == null || value.trim().isEmpty) {
											return 'Zielort ist ein Pflichtfeld.';
										}
										return null;
									},
								),
								const SizedBox(height: 12),
								Row(
									children: [
										Expanded(
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													_buildSectionLabel(Icons.calendar_month_outlined, 'Datum'),
													_buildPickerField(
														controller: _dateController,
														hint: 'tt.mm.jjjj',
														icon: Icons.calendar_today,
														onTap: _pickDate,
														validator: (_) => _selectedDate == null ? 'Datum ist Pflicht.' : null,
													),
												],
											),
										),
										const SizedBox(width: 10),
										Expanded(
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													_buildSectionLabel(Icons.access_time_outlined, 'Uhrzeit'),
													_buildPickerField(
														controller: _timeController,
														hint: '--:--',
														icon: Icons.schedule,
														onTap: _pickTime,
														validator: (_) => _selectedTime == null ? 'Uhrzeit ist Pflicht.' : null,
													),
												],
											),
										),
									],
								),
								const SizedBox(height: 12),
								_buildSectionLabel(Icons.people_outline, 'Verfügbare Sitzplätze'),
								_buildTextField(
									controller: _seatsController,
									hint: 'Anzahl Sitze',
									keyboardType: TextInputType.number,
									validator: (value) {
										final seats = int.tryParse(value ?? '');
										if (seats == null || seats <= 0) {
											return 'Verfügbare Sitzplätze muss größer als 0 sein.';
										}
										return null;
									},
								),
								const SizedBox(height: 12),
								_buildSectionLabel(Icons.euro_outlined, 'Preis pro Platz (optional)'),
								_buildTextField(
									controller: _priceController,
									hint: 'z.B. 4.50',
									keyboardType: const TextInputType.numberWithOptions(decimal: true),
									validator: (value) {
										if (value == null || value.trim().isEmpty) return null;
										final price = double.tryParse(value.replaceAll(',', '.'));
										if (price == null || price < 0) {
											return 'Bitte gültigen Preis eingeben.';
										}
										return null;
									},
								),
								const SizedBox(height: 12),
								_buildSectionLabel(Icons.notes_outlined, 'Notiz (optional)'),
								_buildTextField(
									controller: _noteController,
									hint: 'Zusatzinfos für Mitfahrer',
									maxLines: 3,
								),
								const SizedBox(height: 18),
								SizedBox(
									width: double.infinity,
									child: ElevatedButton(
										onPressed: (!hasUsername || _isSubmitting) ? null : _submit,
										style: ElevatedButton.styleFrom(
											backgroundColor: primary,
											foregroundColor: Colors.white,
											disabledBackgroundColor: const Color(0xFFB8BFDF),
											padding: const EdgeInsets.symmetric(vertical: 14),
											shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
											elevation: 0,
										),
										child: _isSubmitting
												? const SizedBox(
														width: 20,
														height: 20,
														child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
													)
												: const Text('Fahrt veröffentlichen', style: TextStyle(fontWeight: FontWeight.w700)),
									),
								),
								const SizedBox(height: 10),
								SizedBox(
									width: double.infinity,
									child: OutlinedButton(
										onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
										style: OutlinedButton.styleFrom(
											foregroundColor: const Color(0xFF394057),
											side: BorderSide(color: Colors.grey.shade300),
											padding: const EdgeInsets.symmetric(vertical: 14),
											shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
										),
										child: const Text('Abbrechen', style: TextStyle(fontWeight: FontWeight.w600)),
									),
								),
									],
								),
							),
						),
					),
				],
			),
		);
	}

	Widget _buildProfileRequiredCard() {
		return Container(
			width: double.infinity,
			margin: const EdgeInsets.only(bottom: 14),
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: const Color(0xFFEAF6EA),
				border: Border.all(color: const Color(0xFF9AD19C)),
				borderRadius: BorderRadius.circular(14),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					const Row(
						children: [
							Icon(Icons.info_outline, size: 18, color: Color(0xFF2E7D32)),
							SizedBox(width: 8),
							Text('Profil erforderlich', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
						],
					),
					const SizedBox(height: 6),
					const Text(
						'Bitte lege zuerst in den Einstellungen einen Benutzernamen fest, bevor du eine Fahrt erstellst.',
						style: TextStyle(color: Color(0xFF3D5A40), fontSize: 13),
					),
					const SizedBox(height: 8),
					TextButton(
						onPressed: () {
							Navigator.of(context).pop('open_settings');
						},
						style: TextButton.styleFrom(
							backgroundColor: const Color(0xFFBFE5C1),
							foregroundColor: const Color(0xFF245A29),
							padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
							shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
						),
						child: const Text('Zu Einstellungen'),
					),
				],
			),
		);
	}

	Widget _buildSectionLabel(IconData icon, String text) {
		return Padding(
			padding: const EdgeInsets.only(bottom: 6),
			child: Row(
				children: [
					Icon(icon, size: 14, color: const Color(0xFF6F78A8)),
					const SizedBox(width: 6),
					Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF394057))),
				],
			),
		);
	}

	Widget _buildTextField({
		required TextEditingController controller,
		required String hint,
		TextInputType keyboardType = TextInputType.text,
		String? Function(String?)? validator,
		int maxLines = 1,
	}) {
		return TextFormField(
			controller: controller,
			keyboardType: keyboardType,
			validator: validator,
			maxLines: maxLines,
			decoration: InputDecoration(
				hintText: hint,
				filled: true,
				fillColor: const Color(0xFFEEF0F6),
				contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(14),
					borderSide: BorderSide.none,
				),
				errorMaxLines: 2,
			),
		);
	}

	Widget _buildPickerField({
		required TextEditingController controller,
		required String hint,
		required IconData icon,
		required VoidCallback onTap,
		String? Function(String?)? validator,
	}) {
		return TextFormField(
			controller: controller,
			readOnly: true,
			onTap: onTap,
			validator: validator,
			decoration: InputDecoration(
				hintText: hint,
				suffixIcon: Icon(icon, size: 16),
				filled: true,
				fillColor: const Color(0xFFEEF0F6),
				contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(14),
					borderSide: BorderSide.none,
				),
			),
		);
	}

	Future<void> _pickDate() async {
		final now = DateTime.now();
		final picked = await showDatePicker(
			context: context,
			initialDate: _selectedDate ?? now,
			firstDate: now,
			lastDate: DateTime(now.year + 2),
		);

		if (picked != null) {
			setState(() {
				_selectedDate = picked;
				_dateController.text =
						'${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}';
			});
		}
	}

	Future<void> _pickTime() async {
		final picked = await showTimePicker(
			context: context,
			initialTime: _selectedTime ?? const TimeOfDay(hour: 8, minute: 0),
		);

		if (picked != null) {
			setState(() {
				_selectedTime = picked;
				_timeController.text =
						'${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
			});
		}
	}

	Future<void> _submit() async {
		final user = context.read<UserProvider>().currentUser;
		if (user == null || user.id == null || user.name.trim().isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Bitte zuerst Benutzername/Profil in den Einstellungen hinterlegen.')),
			);
			return;
		}

		if (!_formKey.currentState!.validate()) {
			return;
		}

		final date = _selectedDate!;
		final time = _selectedTime!;
		final departTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
		final seats = int.parse(_seatsController.text.trim());
		final priceText = _priceController.text.trim();
		final noteText = _noteController.text.trim();

		final newRide = Ride(
			id: 0,
			driverUserId: user.id!,
			driverUsername: user.name,
			startName: _startController.text.trim(),
			endName: _destinationController.text.trim(),
			departTime: departTime,
			seatsTotal: seats,
			seatsOccupied: 0,
			pricePerSeat: priceText.isEmpty ? null : double.tryParse(priceText.replaceAll(',', '.')),
			note: noteText.isEmpty ? null : noteText,
			createdAt: DateTime.now(),
		);

		setState(() => _isSubmitting = true);
		final ok = await context.read<RideProvider>().addRide(newRide);
		if (!mounted) return;
		setState(() => _isSubmitting = false);

		if (ok) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Fahrt erfolgreich erstellt.')),
			);
			Navigator.of(context).pop(true);
			return;
		}

		final error = context.read<RideProvider>().error;
		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(content: Text(error ?? 'Fahrt konnte nicht erstellt werden.')),
		);
	}
}
