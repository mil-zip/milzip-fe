import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:milzip/models/ai_recommend_result.dart';
import 'package:milzip/services/ai_recommend_api.dart';
import 'package:milzip/services/location_service.dart';
import 'widgets/ai_action_button.dart';
import 'widgets/category_selection_screen.dart';
import 'widgets/company_selection_screen.dart';
import 'widgets/free_text_screen.dart';
import 'widgets/loading_screen.dart';
import 'widgets/location_input_screen.dart';
import 'widgets/results_screen.dart';

class AiRecommendScreen extends StatefulWidget {
  const AiRecommendScreen({super.key});

  @override
  State<AiRecommendScreen> createState() => _AiRecommendScreenState();
}

class _AiRecommendScreenState extends State<AiRecommendScreen> {
  int _currentStep = 0;
  String? _selectedCompany;
  Set<String> _selectedCategories = {};
  bool _isGeocodingLoading = false;

  AiRecommendResult? _result;
  Future<AiRecommendResult>? _apiFuture;
  bool _isResultReady = false;

  final TextEditingController _freeTextController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  static const Color primaryColor = Color(0xFF6B9358);

  bool get _hasLocation => LocationService.instance.position != null;

  @override
  void dispose() {
    _freeTextController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_currentStep == 4 && _hasLocation) {
      setState(() => _currentStep = 2);
    } else if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _selectCompany(String company) {
    setState(() => _selectedCompany = company);
  }

  void _proceedFromCompany() {
    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('함께할 사람을 선택해주세요')),
      );
      return;
    }
    setState(() => _currentStep = 2);
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else if (_selectedCategories.length < 3) {
        _selectedCategories.add(category);
      }
    });
  }

  void _proceedToLocation() {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 1개 이상의 카테고리를 선택해주세요')),
      );
      return;
    }
    if (_hasLocation) {
      setState(() => _currentStep = 4);
    } else {
      setState(() => _currentStep = 3);
    }
  }

  Future<void> _proceedToFreeText() async {
    final text = _locationController.text.trim();
    if (text.isEmpty) {
      setState(() => _currentStep = 4);
      return;
    }

    setState(() => _isGeocodingLoading = true);
    try {
      await locationFromAddress('$text, 한국');
    } catch (_) {
      // 변환 실패해도 진행
    } finally {
      if (mounted) setState(() => _isGeocodingLoading = false);
    }
    if (mounted) setState(() => _currentStep = 4);
  }

  void _submitRecommendation() {
    if (_freeTextController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('찾고 있는 장소를 알려주세요')),
      );
      return;
    }

    final pos = LocationService.instance.position;
    _apiFuture = AiRecommendApi.fetch(
      freeText: _freeTextController.text.trim(),
      companion: _mapCompanion(_selectedCompany),
      categories: _selectedCategories.isEmpty ? null : _selectedCategories.toList(),
      lat: pos.latitude,
      lng: pos.longitude,
    );

    setState(() {
      _currentStep = 5;
      _isResultReady = false;
    });
  }

  void _onLoadingDone(AiRecommendResult result) {
    if (!mounted) return;
    setState(() {
      _result = result;
      _isResultReady = true;
      // 버튼 활성화만 — step 6 이동은 사용자가 "결과 보기" 탭 시
    });
  }

  void _onLoadingError(String message) {
    if (!mounted) return;
    setState(() {
      _currentStep = 4;
      _isResultReady = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('추천 실패: $message')),
    );
  }

  void _reset() {
    setState(() {
      _currentStep = 0;
      _selectedCompany = null;
      _selectedCategories = {};
      _result = null;
      _apiFuture = null;
      _isResultReady = false;
      _freeTextController.clear();
      _locationController.clear();
    });
  }

  String? _mapCompanion(String? company) {
    switch (company) {
      case '친구':
        return 'FRIEND';
      case '연인':
        return 'COUPLE';
      case '가족':
        return 'FAMILY';
      case '혼자':
        return 'ALONE';
      default:
        return null;
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return '누구와\n함께인가요?';
      case 2:
        return '어떤 경험을\n원하나요?';
      case 3:
        return '어느 지역에서\n찾고 있나요?';
      case 4:
        return '어떤 장소를\n찾고 있나요?';
      default:
        return '';
    }
  }

  Widget _buildBottomButtons() {
    // 로딩 중 / 완료 — 항상 버튼 표시 (회색→초록 전환)
    if (_currentStep == 5) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        child: _ResultReadyButton(
          ready: _isResultReady,
          onTap: () => setState(() => _currentStep = 6),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Row(
        children: [
          if (_currentStep > 0 && _currentStep != 6) ...[
            Expanded(
              child: GestureDetector(
                onTap: _goBack,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chevron_left_rounded,
                          size: 22, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Text(
                        '이전',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: AiActionButton(
              label: _currentStep == 0
                  ? '지금 바로 시작'
                  : _currentStep == 6
                      ? '다시 추천 받기'
                      : (_currentStep == 3 && _isGeocodingLoading)
                          ? '위치 확인 중...'
                          : '다음',
              enabled: (_currentStep != 3 || !_isGeocodingLoading) &&
                  (_currentStep != 1 || _selectedCompany != null) &&
                  (_currentStep != 2 || _selectedCategories.isNotEmpty),
              onTap: _currentStep == 0
                  ? () => setState(() => _currentStep = 1)
                  : _currentStep == 1
                      ? _proceedFromCompany
                      : _currentStep == 2
                          ? _proceedToLocation
                          : _currentStep == 3
                              ? _proceedToFreeText
                              : _currentStep == 4
                                  ? _submitRecommendation
                                  : _currentStep == 6
                                      ? _reset
                                      : () {},
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _currentStep == 0 ? const Color(0xFFFAFCF8) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  if (_currentStep == 0) ...[
                    Positioned(
                      top: -80,
                      right: -80,
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              primaryColor.withOpacity(0.22),
                              primaryColor.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 140,
                      left: -120,
                      child: Container(
                        width: 340,
                        height: 340,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFFD66B).withOpacity(0.18),
                              const Color(0xFFFFD66B).withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Opacity(
                          opacity: 0.10,
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              primaryColor,
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              'assets/images/milzip_logo_icon.png',
                              width: MediaQuery.of(context).size.width * 0.7,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else if (_currentStep < 6) ...[
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(height: 4, color: Colors.grey[200]),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        height: 4,
                        width: MediaQuery.of(context).size.width *
                            (_currentStep.clamp(1, 4) / 4),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF7CAA66), Color(0xFF5A8348)],
                          ),
                        ),
                      ),
                    ),
                  ],
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentStep > 0)
                          SizedBox(
                            height: (_currentStep == 5 || _currentStep == 6)
                                ? 4
                                : 72,
                          ),
                        if (_currentStep == 0)
                          SizedBox(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height - 340,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'AI 맞춤 추천',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: primaryColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                      colors: [Colors.black, primaryColor],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds),
                                    child: const Text(
                                      '당신을 위한\n완벽한 장소',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 44,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1.2,
                                        letterSpacing: -1.0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    '짧은 시간 안에 맛있는 곳, 재밌는 곳,\n군장병 혜택 있는 곳을 찾고 있나요?',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[800],
                                      height: 1.6,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '밀집이가 당신의 상황에 딱 맞는\n장소를 추천해드릴게요',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[600],
                                      height: 1.6,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: Center(
                              child: Text(
                                _getStepTitle(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ),
                        if (_currentStep != 5 && _currentStep != 6)
                          const SizedBox(height: 32),
                        if (_currentStep == 1)
                          CompanySelectionScreen(
                            onSelect: _selectCompany,
                            selectedCompany: _selectedCompany,
                          )
                        else if (_currentStep == 2)
                          CategorySelectionScreen(
                            selectedCategories: _selectedCategories,
                            onToggleCategory: _toggleCategory,
                            onProceed: _proceedToLocation,
                          )
                        else if (_currentStep == 3)
                          LocationInputScreen(
                            controller: _locationController,
                            onSkip: () => setState(() => _currentStep = 4),
                          )
                        else if (_currentStep == 4)
                          FreeTextScreen(controller: _freeTextController)
                        else if (_currentStep == 5 && _apiFuture != null)
                          LoadingScreen(
                            future: _apiFuture!,
                            onDone: _onLoadingDone,
                            onError: _onLoadingError,
                          )
                        else if (_currentStep == 6 && _result != null)
                          ResultsScreen(
                            result: _result!,
                            onReset: _reset,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }
}

/// 로딩 중에는 회색, API 완료 시 초록으로 전환되는 결과보기 버튼
class _ResultReadyButton extends StatelessWidget {
  final bool ready;
  final VoidCallback onTap;

  const _ResultReadyButton({required this.ready, required this.onTap});

  static const _greenStart = Color(0xFF7CAA66);
  static const _greenEnd = Color(0xFF5A8348);
  static const _grayStart = Color(0xFFD8D8D8);
  static const _grayEnd = Color(0xFFC2C2C2);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: ready ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (_, t, __) {
        final c1 = Color.lerp(_grayStart, _greenStart, t)!;
        final c2 = Color.lerp(_grayEnd, _greenEnd, t)!;
        final textColor =
            Color.lerp(const Color(0xFF999999), Colors.white, t)!;

        return GestureDetector(
          onTap: ready ? onTap : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c1, c2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: t > 0.5
                  ? [
                      BoxShadow(
                        color: _greenEnd.withOpacity(0.45 * t),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '결과 보기',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, color: textColor, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }
}
