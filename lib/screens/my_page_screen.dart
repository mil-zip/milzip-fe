import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:milzip/models/store.dart';
import 'package:milzip/models/store_review.dart';
import 'package:milzip/screens/favorite_stores_screen.dart';
import 'package:milzip/screens/map/store_detail_screen.dart';
import 'package:milzip/screens/login_screen.dart';
import 'package:milzip/screens/mypage/military_verification_screen.dart';
import 'package:milzip/screens/mypage/password_reset_screen.dart';
import 'package:milzip/screens/review/review_detail_screen.dart';
import 'package:milzip/screens/saved_benefits_screen.dart';
import 'package:milzip/services/auth_service.dart';
import 'package:milzip/services/user_service.dart';
import 'package:milzip/theme/app_colors.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  // 유저 정보
  String _nickname = '';
  String _email = '';
  String _militaryStatus = 'NOT_VERIFIED';
  String? _profileImageUrl;

  // 즐겨찾기
  List<Map<String, dynamic>> _favorites = [];

  // 리뷰
  List<StoreReview> _reviews = [];


  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) {
      _redirectToLogin();
      return;
    }
    try {
      final results = await Future.wait([
        UserService.getMyInfo(),
        UserService.getFavorites(),
        UserService.getMyReviews(),
      ]);
      if (!mounted) return;
      final info = results[0] as Map<String, dynamic>;
      final favs = results[1] as List<Map<String, dynamic>>;
      final reviewPage = results[2] as StoreReviewPage;
      setState(() {
        _nickname = info['nickname'] ?? '';
        _email = info['email'] ?? '';
        _militaryStatus = (info['militaryStatus'] as String?) ?? 'NOT_VERIFIED';
        _profileImageUrl = info['profileImageUrl'] as String?;
        _favorites = favs;
        _reviews = reviewPage.content;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('401') || msg.contains('403') || msg.contains('만료')) {
        await AuthService.clearTokens();
        _redirectToLogin();
      }
    }
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });
  }

  Future<void> _editNickname() async {
    final newNickname = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NicknameEditSheet(initialNickname: _nickname),
    );
    if (newNickname != null && mounted) {
      setState(() => _nickname = newNickname);
    }
  }

  Future<void> _pickAndUpdateProfileImage() async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final data = await UserService.updateProfileImage(bytes);
      if (mounted) {
        setState(() => _profileImageUrl = data['profileImageUrl'] as String?);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  // ── 카테고리 아이콘 ────────────────────────────────────────────────────────
  static IconData _categoryToIcon(String? category) {
    switch (category) {
      case 'FOOD':
      case '음식':
        return Icons.restaurant_rounded;
      case 'CAFE':
      case '카페':
        return Icons.local_cafe_rounded;
      case 'LEISURE':
      case '여가':
      case '영화':
      case '놀이공원':
        return Icons.local_activity_rounded;
      case 'ACCOMMODATION':
      case '숙박':
        return Icons.hotel_rounded;
      default:
        return Icons.store_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF3F4F7),
      child: RefreshIndicator(
        onRefresh: _loadAll,
        color: AppColors.primaryAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildProfile(),
              const SizedBox(height: 8),
              _buildAccountSettings(),  // 군인 인증 + 비밀번호 변경
              const SizedBox(height: 8),
              _buildActivity(),         // 즐겨찾기 + 저장한 혜택
              const SizedBox(height: 8),
              _buildReviews(),
              const SizedBox(height: 8),
              _buildLogout(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── 프로필 + 군인 인증 ────────────────────────────────────────────────────
  Widget _buildProfile() {
    final isVerified = _militaryStatus == 'VERIFIED';
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        children: [
          // 프로필 사진
          GestureDetector(
            onTap: _pickAndUpdateProfileImage,
            child: Stack(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFD0D3D8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    image: _profileImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_profileImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _profileImageUrl == null
                      ? const Icon(Icons.person_rounded, size: 38, color: Colors.white)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 13, color: AppColors.textSub),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 닉네임
          GestureDetector(
            onTap: _editNickname,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _nickname.isNotEmpty ? _nickname : '닉네임',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit_rounded, size: 14, color: AppColors.textSub),
              ],
            ),
          ),
          if (_email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_email, style: const TextStyle(fontSize: 13, color: AppColors.textSub)),
          ],

          const SizedBox(height: 20),

          // 군인 인증 카드
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isVerified ? AppColors.surfaceSoft : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isVerified ? AppColors.primaryAccent.withAlpha(80) : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isVerified
                        ? AppColors.primaryAccent.withAlpha(30)
                        : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    size: 20,
                    color: isVerified ? AppColors.primaryAccent : const Color(0xFFAAAAAA),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isVerified ? '군인 인증 완료' : '군인 인증',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isVerified ? AppColors.primaryAccent : AppColors.textMain,
                    ),
                  ),
                ),
                if (isVerified)
                  const Icon(Icons.check_circle_rounded, color: AppColors.primaryAccent, size: 22)
                else
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MilitaryVerificationScreen()),
                      );
                      _loadAll();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '인증하기',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 비밀번호 변경 ─────────────────────────────────────────────────────────
  Widget _buildAccountSettings() {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PasswordResetScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: const [
              Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textSub),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '비밀번호 변경',
                  style: TextStyle(fontSize: 15, color: AppColors.textMain, fontWeight: FontWeight.w500),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSub),
            ],
          ),
        ),
      ),
    );
  }

  // ── 즐겨찾기 + 저장한 혜택 ────────────────────────────────────────────────
  Widget _buildActivity() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 즐겨찾기한 매장
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoriteStoresScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '즐겨찾기한 매장',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                          if (_favorites.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${_favorites.length}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryAccent,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSub),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_favorites.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Text(
                        '즐겨찾기한 매장이 없습니다.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      ),
                    )
                  else
                    SizedBox(
                      height: 152,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _favorites.length,
                        separatorBuilder: (context, r) => const SizedBox(width: 10),
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          final raw = _favorites[index];
                          final icon = _categoryToIcon(raw['category'] as String?);
                          final imageUrls = (raw['imageUrls'] as List?)
                              ?.map((e) => e.toString())
                              .toList() ?? [];
                          final storeName =
                              raw['name'] as String? ??
                              raw['storeName'] as String? ?? '';
                          final storeId = (raw['storeId'] ?? raw['id']) as int? ?? 0;
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StoreDetailScreen(
                                  store: Store.fromJson(<String, dynamic>{
                                    ...raw,
                                    'id': storeId,
                                    'name': storeName,
                                  }),
                                ),
                              ),
                            ),
                            child: SizedBox(
                              width: 101,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 101,
                                      height: 101,
                                      child: imageUrls.isNotEmpty
                                          ? Image.network(
                                              imageUrls.first,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                    color: const Color(0xFFD0D3D8),
                                                    child: Icon(icon,
                                                        size: 32,
                                                        color: Colors.white),
                                                  ),
                                            )
                                          : Container(
                                              color: const Color(0xFFD0D3D8),
                                              child: Icon(icon,
                                                  size: 32,
                                                  color: Colors.white),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    storeName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMain,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 구분선
          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F7)),

          // 저장한 혜택
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedBenefitsScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '저장한 혜택',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSub),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 리뷰 목록 ──────────────────────────────────────────────────────────────
  Widget _buildReviews() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '내 리뷰',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
          ),
          if (_reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text('작성한 리뷰가 없습니다.', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
            )
          else ...[
            const Text(
              '최신순',
              style: TextStyle(fontSize: 13, color: AppColors.textSub, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: _reviews.map((review) {
                final thumbUrl = review.imageUrls.isNotEmpty
                    ? review.imageUrls.first
                    : null;
                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push<dynamic>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewDetailScreen(review: review, isOwner: true),
                      ),
                    );
                    if (!mounted) return;
                    if (result == 'deleted') {
                      setState(() => _reviews.removeWhere((r) => r.id == review.id));
                    } else if (result is StoreReview) {
                      setState(() {
                        final idx = _reviews.indexWhere((r) => r.id == result.id);
                        if (idx >= 0) _reviews[idx] = result;
                      });
                    }
                  },
                  child: SizedBox(
                  width: (MediaQuery.of(context).size.width - 40 - 7) / 2,
                  height: 214,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D3D8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: thumbUrl != null
                              ? Image.network(thumbUrl, fit: BoxFit.cover)
                              : Center(
                                  child: Icon(
                                    Icons.restaurant_rounded,
                                    size: 40,
                                    color: Colors.white.withAlpha(180),
                                  ),
                                ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withAlpha(140),
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '★${review.rating.toStringAsFixed(1)} · ${review.createdDateLabel}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                                Text(
                                  review.content,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),  // SizedBox
                );  // GestureDetector
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ── 로그아웃 ──────────────────────────────────────────────────────────────
  Widget _buildLogout() {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: const Text(
                '로그아웃',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              content: const Text(
                '로그아웃 하시겠습니까?',
                style: TextStyle(fontSize: 14, color: AppColors.textSub),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('취소', style: TextStyle(color: AppColors.textSub)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    '로그아웃',
                    style: TextStyle(color: Color(0xFFE24B4A), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
          if (confirmed != true || !mounted) return;
          await AuthService.logout();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: const [
              Icon(Icons.logout_rounded, size: 20, color: Color(0xFFE24B4A)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '로그아웃',
                  style: TextStyle(fontSize: 15, color: Color(0xFFE24B4A), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 닉네임 수정 바텀시트 ──────────────────────────────────────────────────────
class _NicknameEditSheet extends StatefulWidget {
  final String initialNickname;

  const _NicknameEditSheet({required this.initialNickname});

  @override
  State<_NicknameEditSheet> createState() => _NicknameEditSheetState();
}

class _NicknameEditSheetState extends State<_NicknameEditSheet> {
  late final TextEditingController _controller;
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNickname);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isChanged => _controller.text.trim() != widget.initialNickname;
  bool get _isValid => _controller.text.trim().length >= 2;

  Future<void> _save() async {
    final nickname = _controller.text.trim();
    setState(() { _isLoading = true; _errorText = null; });
    try {
      final available = await AuthService.checkNicknameAvailability(nickname);
      if (!mounted) return;
      if (!available) {
        setState(() { _errorText = '이미 사용 중인 닉네임입니다.'; _isLoading = false; });
        return;
      }
      await UserService.updateNickname(nickname);
      if (mounted) Navigator.pop(context, nickname);
    } catch (e) {
      if (mounted) setState(() => _errorText = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '닉네임 변경',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 20,
            onChanged: (_) => setState(() => _errorText = null),
            decoration: InputDecoration(
              hintText: '새 닉네임 입력 (2~20자)',
              hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              counterText: '',
              errorText: _errorText,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _errorText != null ? const Color(0xFFE24B4A) : AppColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _errorText != null ? const Color(0xFFE24B4A) : AppColors.primaryAccent,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE24B4A)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE24B4A), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isChanged && _isValid && !_isLoading) ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                disabledBackgroundColor: AppColors.border,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('저장', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
