// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/ride_provider.dart';
// import '../providers/user_provider.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
    
//     // Load rides on init
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<RideProvider>().fetchRides();
//     });
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('RideLog'),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: 'Heute'),
//             Tab(text: 'Bevorstehend'),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               context.read<RideProvider>().fetchRides();
//             },
//           ),
//         ],
//       ),
//       body: Consumer2<RideProvider, UserProvider>(
//         builder: (context, rideProvider, userProvider, child) {
//           if (rideProvider.isLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (rideProvider.error != null) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.error_outline,
//                     size: 64,
//                     color: Theme.of(context).colorScheme.error,
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Fehler beim Laden',
//                     style: Theme.of(context).textTheme.titleLarge,
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     rideProvider.error!,
//                     style: Theme.of(context).textTheme.bodyMedium,
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 16),
//                   FilledButton.icon(
//                     onPressed: () {
//                       rideProvider.clearError();
//                       rideProvider.fetchRides();
//                     },
//                     icon: const Icon(Icons.refresh),
//                     label: const Text('Erneut versuchen'),
//                   ),
//                 ],
//               ),
//             );
//           }

//           return TabBarView(
//             controller: _tabController,
//             children: [
//               _buildRidesList(
//                 context,
//                 rideProvider.todayRides,
//                 userProvider.currentUser?.id,
//                 'Keine Fahrten heute',
//               ),
//               _buildRidesList(
//                 context,
//                 rideProvider.upcomingRides,
//                 userProvider.currentUser?.id,
//                 'Keine bevorstehenden Fahrten',
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildRidesList(
//     BuildContext context,
//     List rides,
//     int? currentUserId,
//     String emptyMessage,
//   ) {
//     if (rides.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.car_rental,
//               size: 64,
//               color: Theme.of(context).colorScheme.outline,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               emptyMessage,
//               style: Theme.of(context).textTheme.titleMedium,
//             ),
//           ],
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: () => context.read<RideProvider>().fetchRides(),
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: rides.length,
//         itemBuilder: (context, index) {
//           final ride = rides[index];
//           final isDriver = ride.driverUserId == currentUserId;

//           return Padding(
//             padding: const EdgeInsets.only(bottom: 16),
           
//           );
//         },
//       ),
//     );
//   }

//   void _joinRide(BuildContext context, int rideId, int? userId) async {
//     if (userId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Bitte melden Sie sich an')),
//       );
//       return;
//     }

//     final success = await context.read<RideProvider>().joinRide(rideId, userId);
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             success
//                 ? 'Erfolgreich angemeldet!'
//                 : 'Fehler beim Beitreten',
//           ),
//         ),
//       );
//     }
//   }
// }
