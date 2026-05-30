import 'package:flutter/material.dart';
import 'benefit/amusement_park.dart';
import 'map/benefit_map.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    Placeholder(), // 빠른 추천 (추후)
    Placeholder(), // AI 맞춤 (추후)
    BenefitMapScreen(), // 혜택 지도
    BenefitCollectionScreen(), // 혜택 모아보기
    Placeholder(), // 마이페이지 (추후)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF293C2C),
        unselectedItemColor: const Color(0xFFAAAAAA),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bolt_outlined),
            label: '빠른 추천',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            label: 'AI 맞춤',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: '혜택 지도',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard_outlined),
            label: '혜택 모아보기',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '마이페이지',
          ),
        ],
      ),
    );
  }
}