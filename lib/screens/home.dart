import 'package:flutter/material.dart';
import 'package:milzip/screens/my_page_screen.dart';
import 'package:milzip/screens/recommend/quick_recommend_screen.dart';
import 'package:milzip/theme/app_colors.dart';
import 'package:milzip/widgets/app_header.dart';
import 'benefit/amusement_park.dart';
import 'map/benefit_map.dart';
import 'map/benefit_map.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const QuickRecommendScreen();
      case 1:
        return _placeholder('AI 맞춤 추천');
      case 2:
        return const BenefitMapScreen();
      case 3:
        return BenefitCollectionScreen();
      case 4:
        return _placeholder('마이페이지');
      default:
        return const QuickRecommendScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(),
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() {
            _currentIndex = i;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color(0xFFBBBBBB),
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        elevation: 12,
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

  Widget _placeholder(String title) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, color: AppColors.textSub),
      ),
    );
  }
}
