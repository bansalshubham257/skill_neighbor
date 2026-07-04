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

  final box = Hive.box('user_box');
  final isLoggedIn = box.get('user_id') != null;

  runApp(
    Provider(
      create: (_) => ApiService(),
      child: SkillNeighborApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class SkillNeighborApp extends StatelessWidget {
  final bool isLoggedIn;
  const SkillNeighborApp({super.key, this.isLoggedIn = false});

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
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (_) => const AuthScreen(),
        '/home': (_) => const HomeScreen(),
        '/add-society': (_) => const AddSocietyScreen(),
      },
    );
  }
}
