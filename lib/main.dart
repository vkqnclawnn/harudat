import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'dday_model.dart';
import 'home_screen.dart';

/// D-Day 데이터를 관리하는 Provider
class DDayProvider extends ChangeNotifier {
  DDayModel? _dday;
  late Box<DDayModel> _box;

  DDayModel? get dday => _dday;
  bool get hasDDay => _dday != null;

  /// Hive Box 초기화 및 데이터 로드
  Future<void> init() async {
    _box = await Hive.openBox<DDayModel>('dday_box');
    if (_box.isNotEmpty) {
      _dday = _box.getAt(0);
    }
    notifyListeners();
  }

  /// D-Day 저장 (기존 데이터 덮어쓰기)
  Future<void> saveDDay(DDayModel dday) async {
    // 기존 데이터 삭제 후 새로 저장
    await _box.clear();
    await _box.add(dday);
    _dday = dday;
    notifyListeners();
  }

  /// D-Day 삭제
  Future<void> deleteDDay() async {
    await _box.clear();
    _dday = null;
    notifyListeners();
  }
}

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
