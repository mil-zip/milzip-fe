import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:milzip/screens/login_screen.dart';
import 'package:milzip/screens/my_page_screen.dart';
import 'package:milzip/screens/recommend/quick_recommend_screen.dart';
import 'package:milzip/screens/recommend/ai_recommend_screen.dart';
import 'package:milzip/services/auth_service.dart';
import 'package:milzip/services/location_service.dart';
import 'package:milzip/theme/app_colors.dart';
import 'package:milzip/widgets/app_header.dart';
import 'package:milzip/widgets/location_picker_sheet.dart';
import 'benefit/amusement_park.dart';
import 'map/benefit_map.dart';

/// 외부에서 HomeScreen 탭을 전환할 때 사용
/// value: 탭 인덱스, data: 탭 내부에 전달할 부가 정보 (예: 혜택 카테고리)
final homeTabNotifier = ValueNotifier<({int tab, int? subIndex})>((tab: 0, subIndex: null));

/// 혜택 탭(index 3)으로 이동하면서 BenefitCollectionScreen의 카테고리도 전환
final benefitCategoryNotifier = ValueNotifier<int>(1);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// 새로고침(웹) 후 마지막으로 보던 탭 복원용 저장 키
const String _kHomeTabKey = 'home_tab_index';

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _locationLabel = '포천시 신북읍';

  // 탭 전환 시 재생성 방지
  final _pages = const [
    QuickRecommendScreen(),
    AiRecommendScreen(),
    BenefitMapScreen(),
    BenefitCollectionScreen(),
    MyPageScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _restoreTab();
    _initLocation();
    homeTabNotifier.addListener(_onExternalTabChange);
  }

  /// 저장된 마지막 탭 복원 (웹 새로고침 대응)
  Future<void> _restoreTab() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_kHomeTabKey);
    if (saved != null && saved >= 0 && saved < _pages.length && mounted) {
      setState(() => _currentIndex = saved);
    }
  }

  void _saveTab(int index) {
    SharedPreferences.getInstance().then((p) => p.setInt(_kHomeTabKey, index));
  }

  @override
  void dispose() {
    homeTabNotifier.removeListener(_onExternalTabChange);
    super.dispose();
  }

  void _onExternalTabChange() {
    final v = homeTabNotifier.value;
    setState(() => _currentIndex = v.tab);
    _saveTab(v.tab);
  }

  Future<void> _initLocation() async {
    await LocationService.instance.initialize();
    if (mounted) {
      setState(() {
        _locationLabel = LocationService.instance.address;
      });
    }
  }

  void _showLocationPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationPickerSheet(
        onLocationSelected: (address) {
          Navigator.pop(context);
          setState(() => _locationLabel = address);
        },
      ),
    );
  }

  Widget _buildCurrentPage() => _pages[_currentIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        location: _locationLabel,
        onLocationTap: _showLocationPicker,
      ),
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) async {
          if (i == 4) {
            final loggedIn = await AuthService.isLoggedIn();
            if (!context.mounted) return;
            if (!loggedIn) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
              return;
            }
          }
          setState(() => _currentIndex = i);
          _saveTab(i);
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

}
