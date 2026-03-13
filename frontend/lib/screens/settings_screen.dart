import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

const double _kUnifiedHeaderHeight = 108;
const double _kUnifiedHeaderTitleSize = 28;
const double _kUnifiedHeaderSubtitleSize = 13;
const double _kUnifiedHeaderTitleSubtitleGap = 4;
const double _kUnifiedHeaderLeftInset = 24;

class SettingsScreen extends StatefulWidget {
	const SettingsScreen({super.key});

	@override
	State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
	bool _isEditingName = false;
	late final TextEditingController _nameController;
	final ApiService _apiService = ApiService();
	List<Group> _groups = [];
	bool _groupsLoading = true;

	int? _lastLoadedUserId;

	@override
	void initState() {
		super.initState();
		_nameController = TextEditingController();
	}

	@override
	void didChangeDependencies() {
		super.didChangeDependencies();
		final user = context.read<UserProvider>().currentUser;
		_nameController.text = user?.name ?? '';

		if (user?.id != null && _lastLoadedUserId != user!.id) {
			_lastLoadedUserId = user.id;
			_loadGroups();
		}
	}

	@override
	void dispose() {
		_nameController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final topInset = MediaQuery.of(context).padding.top;
		final user = context.watch<UserProvider>().currentUser;
		final hasName = (user?.name.trim().isNotEmpty ?? false);
		final primary = Theme.of(context).colorScheme.primary;

		return Container(
			color: Theme.of(context).scaffoldBackgroundColor,
			child: Column(
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
										Text(
											'Einstellungen',
											style: TextStyle(fontWeight: FontWeight.w700, fontSize: _kUnifiedHeaderTitleSize, color: Colors.white),
										),
										SizedBox(height: _kUnifiedHeaderTitleSubtitleGap),
										Text(
											'App und Profil anpassen',
											style: TextStyle(fontSize: _kUnifiedHeaderSubtitleSize, color: Colors.white70),
										),
									],
								),
							),
						),
					),
					Expanded(
						child: ListView(
							padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
							children: [
								_sectionTitle('DEIN PROFIL'),
								_buildProfileCard(hasName),
								const SizedBox(height: 14),
								_sectionTitle('THEMEAUSWAHL'),
								_buildThemeCard(),
								const SizedBox(height: 14),
								Row(
									children: [
										Expanded(child: _sectionTitle('MEINE GRUPPEN')),
										_smallActionButton('Beitreten', onTap: _showJoinDialog),
										const SizedBox(width: 8),
										_smallActionButton('Erstellen', filled: true, onTap: _showCreateDialog),
									],
								),
								const SizedBox(height: 8),
								if (_groupsLoading)
									const Padding(
										padding: EdgeInsets.symmetric(vertical: 20),
										child: Center(child: CircularProgressIndicator()),
									)
								else if (_groups.isEmpty)
									Builder(
										builder: (context) {
											final scheme = Theme.of(context).colorScheme;
											return Container(
												padding: const EdgeInsets.all(14),
												decoration: BoxDecoration(
													color: scheme.surfaceContainer,
													borderRadius: BorderRadius.circular(14),
													border: Border.all(color: scheme.outlineVariant),
												),
												child: Row(
													children: [
														Icon(Icons.groups_outlined, color: scheme.onSurfaceVariant, size: 18),
														const SizedBox(width: 10),
														Expanded(
															child: Text(
																'Du bist aktuell in keiner Gruppe.',
																style: TextStyle(color: scheme.onSurfaceVariant),
															),
														),
													],
												),
											);
										},
									)
								else
									..._groups.map(_buildGroupCard),
							],
						),
					),
				],
			),
		);
	}

	Widget _sectionTitle(String text) {
		final scheme = Theme.of(context).colorScheme;
		return Padding(
			padding: const EdgeInsets.only(bottom: 8),
			child: Text(
				text,
				style: TextStyle(
					fontSize: 12,
					letterSpacing: 0.3,
					color: scheme.onSurfaceVariant,
					fontWeight: FontWeight.w700,
				),
			),
		);
	}

	Widget _buildProfileCard(bool hasName) {
		final user = context.watch<UserProvider>().currentUser;
		final String currentName = user?.name ?? '';
		final String email = user?.email ?? '';
		final scheme = Theme.of(context).colorScheme;

		return Container(
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: scheme.surface,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: scheme.outlineVariant),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					if (email.isNotEmpty) ...[
						Text(
							email,
							style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
						),
						const SizedBox(height: 8),
					],
					Row(
						children: [
							Expanded(
								child: _isEditingName
										? TextField(
												controller: _nameController,
												decoration: const InputDecoration(
													isDense: true,
													hintText: 'Name eingeben',
													border: InputBorder.none,
												),
											)
										: Text(
												hasName ? currentName : 'Profil einrichten',
												style: TextStyle(fontSize: 18, color: scheme.onSurface, fontWeight: FontWeight.w600),
											),
							),
							TextButton(
								onPressed: _isEditingName ? _saveName : () => setState(() => _isEditingName = true),
								style: TextButton.styleFrom(
									minimumSize: const Size(56, 30),
									backgroundColor: scheme.surfaceContainerHighest,
									foregroundColor: scheme.onSurfaceVariant,
									padding: const EdgeInsets.symmetric(horizontal: 12),
									shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
								),
								child: Text(_isEditingName ? 'Speichern' : 'Bearbeiten'),
							),
						],
					),
					const SizedBox(height: 8),
					Row(
						children: [
							Expanded(
								child: Text(
									'Du bist mit deinem Konto angemeldet.',
									style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
								),
							),
							TextButton.icon(
								onPressed: () async {
									await context.read<UserProvider>().logout();
								},
								icon: const Icon(Icons.logout, size: 16),
								label: const Text('Logout'),
							),
						],
					),
				],
			),
		);
	}

	Widget _buildThemeCard() {
		final themeProvider = context.watch<ThemeProvider>();
		final primary = Theme.of(context).colorScheme.primary;
		final scheme = Theme.of(context).colorScheme;
		final selected = AppThemeCatalog.options.firstWhere(
			(option) => option.preset == themeProvider.preset,
			orElse: () => AppThemeCatalog.options.first,
		);

		return Container(
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: scheme.surface,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: scheme.outlineVariant),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							Icon(Icons.palette_outlined, size: 16, color: primary),
							SizedBox(width: 8),
							Text('App-Design', style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface)),
						],
					),
					const SizedBox(height: 10),
					Container(
						height: 36,
						padding: const EdgeInsets.symmetric(horizontal: 10),
						decoration: BoxDecoration(
							color: scheme.surfaceContainerHighest,
							borderRadius: BorderRadius.circular(12),
						),
						child: DropdownButtonHideUnderline(
							child: DropdownButton<AppThemeOption>(
								value: selected,
								isExpanded: true,
								icon: const Icon(Icons.keyboard_arrow_down),
								items: AppThemeCatalog.options
										.map(
											(option) => DropdownMenuItem<AppThemeOption>(
												value: option,
												child: Row(
													children: [
														Container(width: 14, height: 14, decoration: BoxDecoration(color: option.preview, borderRadius: BorderRadius.circular(3))),
														const SizedBox(width: 8),
														Text(_themeLabelDe(option.label)),
													],
												),
											),
										)
										.toList(),
								onChanged: (option) {
									if (option == null) return;
									themeProvider.setThemePreset(option.preset);
								},
							),
						),
					),
				],
			),
		);
	}

	String _themeLabelDe(String label) => label;

	Widget _smallActionButton(String text, {bool filled = false, required VoidCallback onTap}) {
		final scheme = Theme.of(context).colorScheme;
		return InkWell(
			onTap: onTap,
			borderRadius: BorderRadius.circular(20),
			child: Container(
				padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
				decoration: BoxDecoration(
					color: filled ? scheme.primaryContainer : scheme.surface,
					borderRadius: BorderRadius.circular(20),
					border: Border.all(color: filled ? scheme.primaryContainer : scheme.outlineVariant),
				),
				child: Row(
					children: [
						if (filled) ...[
							Icon(Icons.add, size: 14, color: scheme.primary),
							const SizedBox(width: 4),
						],
						Text(text, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: scheme.onSurface)),
					],
				),
			),
		);
	}

	Widget _buildGroupCard(Group group) {
		final scheme = Theme.of(context).colorScheme;
		final memberLabel = group.membersCount == 1 ? 'Mitglied' : 'Mitglieder';
		return Container(
			margin: const EdgeInsets.only(bottom: 10),
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: scheme.surface,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: scheme.outlineVariant),
			),
			child: Row(
				children: [
					Container(
						height: 32,
						width: 32,
						decoration: BoxDecoration(
							color: scheme.surfaceContainerHighest,
							borderRadius: BorderRadius.circular(16),
						),
						child: Icon(Icons.groups_2_outlined, size: 18, color: scheme.primary),
					),
					const SizedBox(width: 10),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(group.name, style: TextStyle(fontSize: 16, color: scheme.onSurface, fontWeight: FontWeight.w600)),
								const SizedBox(height: 2),
								Text('${group.membersCount} $memberLabel - Code: ${group.code}', style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
								if (group.isOwner)
									Padding(
										padding: EdgeInsets.only(top: 2),
										child: Text('Admin', style: TextStyle(fontSize: 12, color: scheme.primary, fontWeight: FontWeight.w600)),
									),
							],
						),
					),
					IconButton(
						onPressed: () async {
							final userId = context.read<UserProvider>().currentUser?.id;
							if (userId == null) return;

							try {
								await _apiService.leaveGroup(groupId: group.id, userId: userId);
								await _loadGroups();
							} catch (e) {
								if (!mounted) return;
								ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Aktion fehlgeschlagen: $e')));
							}
						},
						icon: Icon(group.isOwner ? Icons.delete_outline : Icons.logout, size: 18, color: scheme.onSurfaceVariant),
					),
				],
			),
		);
	}

	Future<void> _saveName() async {
		final name = _nameController.text.trim();
		if (name.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitte einen Namen eingeben.')));
			return;
		}

		try {
			await context.read<UserProvider>().updateProfileName(name);
			if (!mounted) return;
			setState(() => _isEditingName = false);
			ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name gespeichert.')));
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Speichern fehlgeschlagen: $e')));
		}
	}

	Future<void> _showJoinDialog() async {
		final userId = context.read<UserProvider>().currentUser?.id;
		if (userId == null) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Bitte zuerst einloggen.')),
			);
			return;
		}

		final controller = TextEditingController();
		final code = await showDialog<String>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Gruppe beitreten'),
				content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Gruppencode eingeben')),
				actions: [
					TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Abbrechen')),
					FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Beitreten')),
				],
			),
		);

		if (code == null || code.isEmpty) return;

		try {
			await _apiService.joinGroup(code: code, userId: userId);
			await _loadGroups();
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Beitritt fehlgeschlagen: $e')));
		}
	}

	Future<void> _showCreateDialog() async {
		final userId = context.read<UserProvider>().currentUser?.id;
		if (userId == null) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Bitte zuerst einloggen.')),
			);
			return;
		}

		final nameController = TextEditingController();
		final createdName = await showDialog<String>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Gruppe erstellen'),
				content: TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Gruppenname')),
				actions: [
					TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Abbrechen')),
					FilledButton(onPressed: () => Navigator.of(context).pop(nameController.text.trim()), child: const Text('Erstellen')),
				],
			),
		);

		if (createdName == null || createdName.isEmpty) return;

		try {
			await _apiService.createGroup(name: createdName, userId: userId);
			await _loadGroups();
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erstellen fehlgeschlagen: $e')));
		}
	}

	Future<void> _loadGroups() async {
		final userId = context.read<UserProvider>().currentUser?.id;
		if (userId == null) {
			setState(() {
				_groups = [];
				_groupsLoading = false;
			});
			return;
		}

		setState(() => _groupsLoading = true);
		try {
			final groups = await _apiService.getGroupsForUser(userId);
			if (!mounted) return;
			setState(() {
				_groups = groups;
				_groupsLoading = false;
			});
		} catch (e) {
			if (!mounted) return;
			setState(() => _groupsLoading = false);
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gruppen laden fehlgeschlagen: $e')));
		}
	}
}

