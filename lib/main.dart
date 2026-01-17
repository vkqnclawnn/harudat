import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'dday_model.dart';
import 'home_screen.dart';
import 'theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive 초기화
  await Hive.initFlutter();

  // DDayModel 어댑터 등록
  Hive.registerAdapter(DDayModelAdapter());

  runApp(const HaruDotApp());
}

class HaruDotApp extends StatelessWidget {
  const HaruDotApp({super.key});

  @override
  Widget build(BuildContext context) {
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4CAF50),
      brightness: Brightness.dark,
    ).copyWith(
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
      surfaceVariant: const Color(0xFF2A2A2A),
      primary: const Color(0xFF4CAF50),
    );

    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4CAF50),
      brightness: Brightness.light,
    ).copyWith(
      background: const Color(0xFFE5E5E5),
      surface: const Color(0xFFFFFFFF),
      surfaceVariant: const Color(0xFFF1F1F1),
      primary: const Color(0xFF4CAF50),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DDayProvider()..init()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final darkTheme = ThemeData(
            useMaterial3: true,
            fontFamily: 'Pretendard',
            colorScheme: darkScheme,
            scaffoldBackgroundColor: darkScheme.background,
            textTheme: Typography.material2021().white.apply(
                  bodyColor: darkScheme.onBackground,
                  displayColor: darkScheme.onBackground,
                ),
          );

          final lightTheme = ThemeData(
            useMaterial3: true,
            fontFamily: 'Pretendard',
            colorScheme: lightScheme,
            scaffoldBackgroundColor: lightScheme.background,
            textTheme: Typography.material2021().black.apply(
                  bodyColor: lightScheme.onBackground,
                  displayColor: lightScheme.onBackground,
                ),
          );

          return MaterialApp(
            title: 'HaruDot',
            debugShowCheckedModeBanner: false,
            // 한국어 로케일 지원
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ko', 'KR'),
              Locale('en', 'US'),
            ],
            locale: const Locale('ko', 'KR'),
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
