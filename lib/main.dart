import 'package:flutter/material.dart';
import 'package:test_audio_analysis_app/features/splash/presentation/pages/splash_page.dart';
import 'package:test_audio_analysis_app/features/trail/presentation/pages/trail_page.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CSS SPEECH ANALYZER',
      home: // DateTime.now().isAfter(DateTime(2025, 5, 20))
         // ? TrailPage()
           SplashPage(),
      theme: AppTheme.lightTheme,
    );
  }
}
