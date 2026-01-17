import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'dday_model.dart';
import 'home_screen.dart';
import 'services/home_widget_service.dart';
import 'theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.shaderWarmUp = const _HaruShaderWarmUp();
  WidgetsBinding.instance.deferFirstFrame();

  // Hive 초기화
  await Hive.initFlutter();

  // DDayModel 어댑터 등록
  Hive.registerAdapter(DDayModelAdapter());

  runApp(const HaruDotApp());

  // 첫 프레임 전에 셰이더를 미리 준비
  WidgetsBinding.instance.scheduleWarmUpFrame();
  WidgetsBinding.instance.allowFirstFrame();

  await HomeWidgetService.updateFromStorage();
}

class _HaruShaderWarmUp extends ShaderWarmUp {
  const _HaruShaderWarmUp();

  @override
  Future<void> warmUpOnCanvas(ui.Canvas canvas) async {
    final bgPaint = ui.Paint()..color = const ui.Color(0xFF121212);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 200, 200), bgPaint);

    final gradientPaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        const ui.Offset(0, 0),
        const ui.Offset(160, 60),
        [const ui.Color(0xFF66BB6A), const ui.Color(0xFF4CAF50)],
      );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(16, 24, 160, 56),
        const ui.Radius.circular(16),
      ),
      gradientPaint,
    );

    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontFamily: 'Pretendard',
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    )..pushStyle(
        ui.TextStyle(color: const ui.Color(0xFFFFFFFF)),
      );

    paragraphBuilder.addText('HaruDot');
    final paragraph = paragraphBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 160));
    canvas.drawParagraph(paragraph, const ui.Offset(28, 40));

    final dotPaint = ui.Paint()..color = const ui.Color(0xFF1E88E5);
    canvas.drawCircle(const ui.Offset(40, 120), 6, dotPaint);
    canvas.drawCircle(const ui.Offset(56, 120), 6, dotPaint);
    canvas.drawCircle(const ui.Offset(72, 120), 6, dotPaint);
  }
}

class HaruDotApp extends StatelessWidget {
  const HaruDotApp({super.key});

  @override
  Widget build(BuildContext context) {
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4CAF50),
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF1E1E1E),
      surfaceContainerHighest: const Color(0xFF2A2A2A),
      primary: const Color(0xFF4CAF50),
    );

    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4CAF50),
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFFFFFFF),
      surfaceContainerHighest: const Color(0xFFF1F1F1),
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
            scaffoldBackgroundColor: const Color(0xFF121212),
            textTheme: Typography.material2021().white.apply(
                  bodyColor: darkScheme.onSurface,
                  displayColor: darkScheme.onSurface,
                ),
          );

          final lightTheme = ThemeData(
            useMaterial3: true,
            fontFamily: 'Pretendard',
            colorScheme: lightScheme,
            scaffoldBackgroundColor: const Color(0xFFE5E5E5),
            textTheme: Typography.material2021().black.apply(
                  bodyColor: lightScheme.onSurface,
                  displayColor: lightScheme.onSurface,
                ),
          );

          return MaterialApp(
            title: 'D-Dot',
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
