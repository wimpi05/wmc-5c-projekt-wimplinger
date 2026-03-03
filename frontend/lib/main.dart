// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'providers/theme_provider.dart';
// import 'providers/ride_provider.dart';
// import 'providers/user_provider.dart';
// import 'screens/home_screen.dart';
// import 'screens/create_ride_screen.dart';

// import 'models/user.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         // ChangeNotifierProvider(create: (_) => ThemeProvider()),
//         // ChangeNotifierProvider(create: (_) => RideProvider()),
//         // ChangeNotifierProvider(create: (_) => UserProvider()
//           // ..setCurrentUser(User(
//           //   id: 1,
//           //   name: 'Demo User',
//           //   email: 'demo@ridelog.com',
//           //   createdAt: DateTime.now(),
//           // ))),
//       ],
//       // child: Consumer<ThemeProvider>(
//       //   builder: (context, themeProvider, child) {
//       //     return MaterialApp(
//       //       title: 'RideLog',
//       //       debugShowCheckedModeBanner: false,
//       //       theme: themeProvider.currentTheme,
//       //       home: const MainScreen(),
//       //     );
//       //   },
//       // ),
//     );
//   }
// }

// class MainScreen extends StatefulWidget {
//   const MainScreen({super.key});

//   @override
//   State<MainScreen> createState() => _MainScreenState();
// }

// class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
//   int _currentIndex = 0;
//   late AnimationController _fabAnimationController;
//   late Animation<double> _fabAnimation;

//   final List<Widget> _screens = const [
//     HomeScreen(),
   
//   ];

//   final List<NavigationDestination> _destinations = const [
//     NavigationDestination(
//       icon: Icon(Icons.home_outlined),
//       selectedIcon: Icon(Icons.home),
//       label: 'Home',
//     ),
//     NavigationDestination(
//       icon: Icon(Icons.history_outlined),
//       selectedIcon: Icon(Icons.history),
//       label: 'Historie',
//     ),
//     NavigationDestination(
//       icon: Icon(Icons.bar_chart_outlined),
//       selectedIcon: Icon(Icons.bar_chart),
//       label: 'Statistik',
//     ),
//     NavigationDestination(
//       icon: Icon(Icons.settings_outlined),
//       selectedIcon: Icon(Icons.settings),
//       label: 'Einstellungen',
//     ),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _fabAnimationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 200),
//     );
//     _fabAnimation = CurvedAnimation(
//       parent: _fabAnimationController,
//       curve: Curves.easeInOut,
//     );
//     _fabAnimationController.forward();
//   }

//   @override
//   void dispose() {
//     _fabAnimationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: AnimatedSwitcher(
//         duration: const Duration(milliseconds: 300),
//         transitionBuilder: (child, animation) {
//           return FadeTransition(
//             opacity: animation,
//             child: SlideTransition(
//               position: Tween<Offset>(
//                 begin: const Offset(0.05, 0),
//                 end: Offset.zero,
//               ).animate(animation),
//               child: child,
//             ),
//           );
//         },
//         child: IndexedStack(
//           key: ValueKey<int>(_currentIndex),
//           index: _currentIndex,
//           children: _screens,
//         ),
//       ),
//       bottomNavigationBar: NavigationBar(
//         selectedIndex: _currentIndex,
//         onDestinationSelected: (index) {
//           setState(() {
//             _currentIndex = index;
//             _fabAnimationController.reset();
//             _fabAnimationController.forward();
//           });
//         },
//         destinations: _destinations,
//       ),
//       floatingActionButton: _currentIndex == 0
//           ? ScaleTransition(
//               scale: _fabAnimation,
//               child: FloatingActionButton.extended(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const CreateRideScreen(),
//                     ),
//                   );
//                 },
//                 icon: const Icon(Icons.add),
//                 label: const Text('Fahrt erstellen'),
//               ),
//             )
//           : null,
//     );
//   }
// }
