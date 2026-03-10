import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

//라우팅을 위한 파일들을 import
import 'dday_cal.dart';
import 'total_cal.dart';

//Flutter App Main으로 앱의 시작점
void main() {
  runApp(const MyApp());
}

//앱 전체를 담당하는 위젝 설정
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '약 용량 계산기',

      //디버그 모드 배너 제거
      debugShowCheckedModeBanner: false,

      //앱 전체 테마 설정 -> 색상, 폰트, 디자인 설정
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        fontFamily: 'Pretender',
      ),

      // 한국어 달력을 위한 설정 유지
      locale: const Locale('ko'),

      // 한국어를 포함한 로케일 델리게이트 등록
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
      ],

      //앱의 시작점을 MainScreen으로 설정
      home: const MainScreen(),
    );
  }
}

//네비게이션(라우팅)을 담당하는 메인 스크린
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  //현재 선택된 탭 인덱스 (index = 0이면 디데이 계산기, 1이면 전체용량 계산기)
  int _selectedIndex = 0; //디폴트값 즉 시작페이지는 디데이 계산기

  // 탭 인덱스에 대응하는 페이지 위젯 목록
  final List<Widget> _pages = [
    const DDayCalculatorPage(),
    const TotalCalculatorPage(),
  ];

  //하단 탭 아이템을 탭했을 때 호출되는 콜백
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //_selectedIndex에 해당하는 페이지를 body에 표시해줌
      body: SafeArea(
        child: _pages[_selectedIndex],
      ),

      // 하단 탭 네비게이션 설정
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '디데이 계산기',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: '처방량 계산기',
          ),
        ],
      ),
    );
  }
}