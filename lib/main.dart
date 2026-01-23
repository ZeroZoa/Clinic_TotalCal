import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// 생성하신 파일들을 임포트합니다.
import 'dday_cal.dart';
import 'total_cal.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '약 용량 계산기',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        // 폰트나 기본 스타일을 여기서 전역으로 잡습니다.
        fontFamily: 'Pretender',
      ),
      // 한국어 달력을 위한 설정 유지
      locale: const Locale('ko'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
      ],
      // 앱의 진입점(Home)을 MainScreen으로 설정
      home: const MainScreen(),
    );
  }
}

/// 네비게이션(라우팅)을 담당하는 메인 스크린
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 현재 선택된 탭 인덱스 (0: 디데이, 1: 전체용량)
  int _selectedIndex = 0;

  // 각 탭에 연결될 페이지 리스트
  // 주의: dday_cal.dart와 total_cal.dart에 해당 클래스 이름이 존재해야 합니다.
  final List<Widget> _pages = [
    const DDayCalculatorPage(),   // dday_cal.dart의 메인 클래스
    const TotalCalculatorPage(),  // total_cal.dart의 메인 클래스 (아직 없다면 생성 필요)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 현재 인덱스에 맞는 페이지를 보여줍니다.
      body: SafeArea(
        child: _pages[_selectedIndex],
      ),
      // 하단 탭 네비게이션
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed, // 탭이 4개 미만일 때 권장
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'D-Day 계산',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: '전체 용량',
          ),
        ],
      ),
    );
  }
}

