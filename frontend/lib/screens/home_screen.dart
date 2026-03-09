import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ride_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/ride_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isHome = _selectedNavIndex == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: isHome ? _buildHomeBody() : SafeArea(child: _buildSectionPage()),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateRide(context),
        backgroundColor: const Color(0xFFA5D6A7),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add, size: 30, color: Colors.black54),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 8,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: SizedBox(
            height: 68,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.home_outlined, label: 'Home', index: 0),
                _buildNavItem(icon: Icons.history, label: 'Verlauf', index: 1),
                const SizedBox(width: 40),
                _buildNavItem(icon: Icons.bar_chart, label: 'Statistik', index: 3),
                _buildNavItem(icon: Icons.settings_outlined, label: 'Einstellungen', index: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeBody() {
    final double topInset = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(22, topInset + 16, 22, 20),
          decoration: const BoxDecoration(
            color: Color(0xFF3F51B5),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RideLog',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 38, color: Colors.white, height: 1),
              ),
              SizedBox(height: 8),
              Text(
                'Dein Dashboard fuer Fahrgemeinschaften',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          color: const Color(0xFFF0F1F5),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFE6E7EC),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: const Color(0xFF3F51B5),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF5C6379),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(child: Text('Heute', style: TextStyle(fontWeight: FontWeight.bold))),
                Tab(child: Text('Demnächst', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              RideListView(filterToday: true),
              RideListView(filterToday: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isActive = _selectedNavIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() => _selectedNavIndex = index);
      },
      child: SizedBox(
        width: 68,
        child: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 21, color: isActive ? const Color(0xFF3F51B5) : const Color(0xFF777E91)),
              const SizedBox(height: 1),
              SizedBox(
                width: 68,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  textAlign: TextAlign.center,
                  textScaler: const TextScaler.linear(1),
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.0,
                    color: isActive ? const Color(0xFF3F51B5) : const Color(0xFF777E91),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionPage() {
    const style = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
    if (_selectedNavIndex == 1) {
      return const Center(child: Text('Der Verlaufs-Screen ist als naechstes dran.', style: style));
    }
    if (_selectedNavIndex == 3) {
      return const Center(child: Text('Der Statistik-Screen ist als naechstes dran.', style: style));
    }
    return const Center(child: Text('Der Einstellungen-Screen ist als naechstes dran.', style: style));
  }

  void _openCreateRide(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Der Create-Ride-Flow ist als naechstes dran.')),
    );
  }
}

class RideListView extends StatelessWidget {
  final bool filterToday;

  const RideListView({super.key, required this.filterToday});

  @override
  Widget build(BuildContext context) {
    final rideProvider = context.watch<RideProvider>();
    final userProvider = context.watch<UserProvider>();
    final int? currentUserId = userProvider.currentUser?.id;
    final rides = filterToday ? rideProvider.todayRides : rideProvider.upcomingRides;

    if (rideProvider.isLoading && rides.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rideProvider.error != null && rides.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Fahrten konnten nicht geladen werden.\n${rideProvider.error}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.read<RideProvider>().fetchRides(),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      );
    }

    if (rides.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<RideProvider>().fetchRides(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 160),
            Center(
              child: Text(
                'Noch keine Fahrten in diesem Tab.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<RideProvider>().fetchRides(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rides.length,
        itemBuilder: (context, index) {
          final ride = rides[index];
          final bool isDriver = currentUserId != null && ride.driverUserId == currentUserId;

          return RideCard(
            ride: ride,
            currentUserId: currentUserId,
            onJoin: (ride.isFull || currentUserId == null)
                ? null
                : () async {
                    final ok = await context.read<RideProvider>().joinRide(ride.id, currentUserId);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? 'Fahrt erfolgreich beigetreten.' : 'Beitritt zur Fahrt fehlgeschlagen.')),
                    );
                  },
            onEdit: isDriver
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Der Bearbeiten-Flow ist als naechstes dran.')),
                    );
                  }
                : null,
            onDelete: isDriver
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Der Loeschen-Flow ist als naechstes dran.')),
                    );
                  }
                : null,
          );
        },
      ),
    );
  }
}