// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase/supabase_service.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/objects_provider.dart';
import 'admin/screens/admin_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF5F0E8),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  await SupabaseService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ObjectsProvider()),
      ],
      child: MaterialApp(
        title: 'АРхив',
        theme: ThemeData(
          primaryColor: const Color(0xFF870C0E),
          scaffoldBackgroundColor: Colors.white,
        ),
        debugShowCheckedModeBanner: false,
        home: _getInitialScreen(),
        routes: {
          '/studio': (context) => const MainNavigationScreen(),
          '/admin': (context) => const AdminScreen(),
        },
      ),
    );
  }

  Widget _getInitialScreen() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return const MainNavigationScreen();
    } else {
      return const LoginScreen();
    }
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 2;

  final List<Widget> _pages = [
    const ScannerScreen(),
    const MapScreen(),
    const MenuScreen(),
    const ProfileScreen(),
  ];

  void changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // Предзагружаем объекты при старте
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObjectsProvider>().loadObjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF870C0E),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Сканер',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Карта'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Меню'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}
