import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/dilution_plans_screen.dart';

void main() {
  // アプリケーション初期化時には向きを固定（縦向き）
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '日本酒タンク管理',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        appBarTheme: AppBarTheme(
          elevation: 2,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        ),
        tabBarTheme: TabBarTheme(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/dilution-plans': (context) => DilutionPlansScreen(),
      },
    );
  }
}