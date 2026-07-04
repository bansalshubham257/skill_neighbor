import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_society_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  await Hive.openBox('user_box');
  await Hive.openBox('bookmarks_box');
  await Hive.openBox('settings_box');

  runApp(
    Provider(
      create: (_) => ApiService(),
      child: const SkillNeighborApp(),
    ),
  );
}

class SkillNeighborApp extends StatelessWidget {
  const SkillNeighborApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillNeighbor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const AuthScreen(),
        '/home': (_) => const HomeScreen(),
        '/add-society': (_) => const AddSocietyScreen(),
      },
    );
  }
}
