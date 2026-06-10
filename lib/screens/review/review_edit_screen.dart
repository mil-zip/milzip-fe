import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/store_review.dart';
import '../../services/store_review_api.dart';
import '../../theme/app_colors.dart';
import '../review/review_survey_screen.dart' show HalfStarRating;

class ReviewEditScreen extends StatefulWidget {
  final StoreReview review;

  const ReviewEditScreen({super.key, required this.review});

  @override
  State<ReviewEditScreen> createState() => _ReviewEditScreenState();
}

class _ReviewEditScreenState extends State<ReviewEditScreen> {
  late double _rating;
  late TextEditingController _contentCtrl;
  late Set<String> _goodPoints; // 한글 레이블

  /// 기존 이미지 URL 목록 (삭제 가능)
  late List<String> _existingUrls;
  /// 새로 추가한 로컬 이미지
  final List<XFile> _newImages = [];
  /// 이미지를 변경했는지 (삭제하거나 추가한 경우)
  bool _imagesChanged = false;

  bool _saving = false;

  static const _maxImages = 3;

  static const _goodPointOptions = [
    ('TASTY',           '음식이 맛있어요'),
    ('LARGE_PORTION',   '양이 많아요'),
    ('GOOD_VALUE',      '가성비가 좋아요'),
    ('GOOD_FOR_SOLO',   '혼밥하기 좋아요'),
    ('GOOD_FOR_GROUPS', '단체로 오기 좋아요'),
    ('QUIET',           '조용하고 좋아요'),
  ];

  static const _enumToLabel = {
    'TASTY':           '음식이 맛있어요',
    'LARGE_PORTION':   '양이 많아요',
    'GOOD_VALUE':      '가성비가 좋아요',
    'GOOD_FOR_SOLO':   '혼밥하기 좋아요',
    'GOOD_FOR_GROUPS': '단체로 오기 좋아요',
    'QUIET':           '조용하고 좋아요',
  };

  int get _totalImageCount => _existingUrls.length + _newImages.length;

  @override
  void initState() {
    super.initState();
    _rating = widget.review.rating;
    _contentCtrl = TextEditingController(text: widget.review.content);
    _goodPoints = widget.review.goodPoints
        .map((e) => _enumToLabel[e] ?? e)
        .toSet();
    _existingUrls = List<String>.from(widget.review.imageUrls);
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_totalImageCount >= _maxImages) {
      _showSnackBar('이미지는 최대 $_maxImages개까지 등록할 수 있습니다.');
      return;
    }
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _newImages.add(image);
      _imagesChanged = true;
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingUrls.removeAt(index);
      _imagesChanged = true;
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
      _imagesChanged = true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final labelToEnum = {
        for (final (enumKey, label) in _goodPointOptions) label: enumKey,
      };
      final r = widget.review;

      // images 처리
      // - 변경 없음 → null (서버가 기존 이미지 유지)
      // - 변경 있음 → 남은 기존 이미지를 URL에서 다운로드 후 새 이미지와 합쳐 전송
      List<String>? newImagePaths;
      final tempFiles = <File>[];
      if (_imagesChanged) {
        // 남은 기존 이미지 URL → temp 파일로 다운로드
        final tmpDir = Directory.systemTemp;
        for (int i = 0; i < _existingUrls.length; i++) {
          try {
            final res = await http.get(Uri.parse(_existingUrls[i]));
            final ext = _existingUrls[i].split('.').last.split('?').first;
            final tmp = File('${tmpDir.path}/review_existing_${DateTime.now().millisecondsSinceEpoch}_$i.$ext');
            await tmp.writeAsBytes(res.bodyBytes);
            tempFiles.add(tmp);
          } catch (_) {
            // 다운로드 실패한 기존 이미지는 건너뜀
          }
        }
        newImagePaths = [
          ...tempFiles.map((f) => f.path),
          ..._newImages.map((x) => x.path),
        ];
      }

      final updated = await StoreReviewApi.update(
        storeId: r.storeId,
        reviewId: r.id,
        fields: {
          'rating': _rating.round(),
          'visitType': r.visitType,
          'waitTime': r.waitTime,
          'visitPurpose': r.visitPurpose,
          'visitWith': r.visitWith,
          if (r.benefitStatus != null) 'benefitStatus': r.benefitStatus,
          'content': _contentCtrl.text.trim(),
          'goodPoints': _goodPoints
              .map((label) => labelToEnum[label] ?? label)
              .toList(),
        },
        newImagePaths: newImagePaths,
      );
      // temp 파일 정리
      for (final f in tempFiles) {
        try { await f.delete(); } catch (_) {}
      }
      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(34, 10, 34, 18),
        child: Align(
          alignment: Alignment.centerRight,
          heightFactor: 1,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              disabledBackgroundColor: AppColors.surfaceSoft,
              foregroundColor: AppColors.textWhite,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textWhite,
                    ),
                  )
                : const Text(
                    '저장',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 24, color: AppColors.textSub),
                  ),
                  const Expanded(
                    child: Text(
                      '리뷰 수정',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMain,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(34, 24, 34, 34),
                children: [
                  // ── 별점 ──
                  const Text(
                    '별점',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF3B30),
                    ),
                  ),
                  const SizedBox(height: 12),
                  HalfStarRating(
                    rating: _rating,
                    onChanged: (v) => setState(() => _rating = v),
                  ),
                  const SizedBox(height: 32),

                  // ── 좋았던 점 ──
                  const Text(
                    '좋았던 점',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: _goodPointOptions.map(((String, String) opt) {
                      final (_, label) = opt;
                      final selected = _goodPoints.contains(label);
                      return GestureDetector(
                        onTap: () => setState(() {
                          selected
                              ? _goodPoints.remove(label)
                              : _goodPoints.add(label);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.selected
                                : AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: selected
                                  ? AppColors.pressed
                                  : AppColors.border,
                              width: selected ? 2 : 1.5,
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? AppColors.textWhite
                                  : AppColors.textMain,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // ── 리뷰 내용 ──
                  const Text(
                    '리뷰 내용',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _contentCtrl,
                      maxLines: 6,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '리뷰 내용을 입력해 주세요.',
                        counterStyle: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSub,
                        ),
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSub,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── 이미지 ──
                  const Text(
                    '사진',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '최대 $_maxImages장 · 기존 사진을 삭제하고 새 사진을 추가하면 교체됩니다.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      // 기존 이미지 (network)
                      ..._existingUrls.asMap().entries.map((e) {
                        return _ImageThumb(
                          child: Image.network(
                            e.value,
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                          ),
                          onRemove: () => _removeExistingImage(e.key),
                        );
                      }),
                      // 새 이미지 (local file)
                      ..._newImages.asMap().entries.map((e) {
                        return _ImageThumb(
                          child: Image.file(
                            File(e.value.path),
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                          ),
                          onRemove: () => _removeNewImage(e.key),
                        );
                      }),
                      // 추가 버튼
                      if (_totalImageCount < _maxImages)
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 36,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;

  const _ImageThumb({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 100, height: 100, child: child),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
