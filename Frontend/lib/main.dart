// lib/main.dart
import 'package:flutter/material.dart';
import 'package:urban_eye/pages/auth_page.dart';
import 'package:urban_eye/pages/feed_page.dart';
import 'package:urban_eye/pages/report_page.dart';
import 'package:urban_eye/pages/profile_page.dart';
import 'package:urban_eye/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize(); // keep your setup here
  runApp(const UrbanEyeApp());
}

class UrbanEyeApp extends StatelessWidget {
  const UrbanEyeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF00796B);
    return MaterialApp(
      title: 'UrbanEye',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF5F7F9),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ),
      initialRoute: AuthService.isSignedIn ? '/home' : '/auth',
      routes: {
        '/auth': (_) => const AuthPage(),
        '/home': (_) => const HomeShell(),
        '/feed': (_) => const FeedPage(),
        '/report': (_) => const ReportPage(),
        '/profile': (_) => const ProfilePage(),
      },
    );
  }
}

/* --------------------------
   HOME SHELL (Bottom Nav)
   -------------------------- */

class HomeShell extends StatefulWidget {
  const HomeShell({Key? key}) : super(key: key);

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<Widget> _pages = [
    FeedPage(),
    Center(child: Text('Map (coming soon)', style: TextStyle(fontSize: 18))),
    ReportPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int idx) {
    setState(() => _index = idx);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.primary;
    final unselectedColor = Colors.grey[600];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: _pages),
      ),

      // Bottom navigation with FAB notch
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: kBottomNavigationBarHeight,
          child: Row(
            // Left items, then spacer, then right items
            children: <Widget>[
              Expanded(child: _NavItem(icon: Icons.list_alt, label: 'Feed', selected: _index == 0, onTap: () => _onItemTapped(0), selectedColor: selectedColor, unselectedColor: unselectedColor)),
              Expanded(child: _NavItem(icon: Icons.map, label: 'Map', selected: _index == 1, onTap: () => _onItemTapped(1), selectedColor: selectedColor, unselectedColor: unselectedColor)),
              // FAB gap
              const SizedBox(width: 56),
              Expanded(child: _NavItem(icon: Icons.report, label: 'Report', selected: _index == 2, onTap: () => _onItemTapped(2), selectedColor: selectedColor, unselectedColor: unselectedColor)),
              Expanded(child: _NavItem(icon: Icons.person, label: 'Profile', selected: _index == 3, onTap: () => _onItemTapped(3), selectedColor: selectedColor, unselectedColor: unselectedColor)),
            ],
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // prefer navigation so stack behaves predictably
          Navigator.of(context).pushNamed('/report');
        },
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Report'),
      ),
    );
  }
}

/* --------------------------
   Small nav item widget
   -------------------------- */

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;
  final Color? unselectedColor;

  const _NavItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: selected ? selectedColor : unselectedColor),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: selected ? selectedColor : unselectedColor, fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
