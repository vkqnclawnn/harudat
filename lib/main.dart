import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'dday_model.dart';
import 'home_screen.dart';

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
    return ChangeNotifierProvider(
      create: (_) => DDayProvider()..init(),
      child: MaterialApp(
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
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Pretendard',
          scaffoldBackgroundColor: const Color(0xFFE5E5E5),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2FFF00),
            brightness: Brightness.light,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
