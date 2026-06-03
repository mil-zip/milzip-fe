import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/store.dart';
import '../../../models/store_review_draft.dart';

class ReviewSubmitScreen extends StatefulWidget {
  final Store store;
  final StoreReviewDraft draft;

  const ReviewSubmitScreen({
    super.key,
    required this.store,
    required this.draft,
  });

  @override
  State<ReviewSubmitScreen> createState() => _ReviewSubmitScreenState();
}

class _ReviewSubmitScreenState extends State<ReviewSubmitScreen> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];

  bool get canRegister => _contentController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _images.add(image);
    });
  }

  void _register() {
    if (!canRegister) return;

    Navigator.popUntil(context, (route) => route.isFirst);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('리뷰가 등록되었습니다.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(34, 10, 34, 18),
        child: Align(
          alignment: Alignment.centerRight,
          heightFactor: 1,
          child: ElevatedButton(
            onPressed: canRegister ? _register : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC2C8),
              disabledBackgroundColor: const Color(0xFFE8E8E8),
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '등록',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 28),
                  ),
                  const Spacer(),
                  const Icon(Icons.star_border, size: 36),
                  const SizedBox(width: 18),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 36),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Text(
                widget.store.name,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Text(
                '★${draft.rating.toStringAsFixed(1)}  ·  ${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')} · 1번째 방문',
                style: const TextStyle(fontSize: 17, color: Color(0xFF777777)),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Text(
                '${draft.waitTimeAnswer} · ${draft.purposeAnswer} · ${draft.companionAnswer}',
                style: const TextStyle(fontSize: 17, color: Color(0xFF555555)),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Row(
                children: [
                  Text(
                    draft.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF5A4F),
                    ),
                  ),
                  const SizedBox(width: 18),
                  ...List.generate(
                    5,
                    (_) => const Icon(
                      Icons.star,
                      size: 42,
                      color: Color(0xFFFF5A4F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Text(
                '🛡️ 군장병 ${draft.benefitAnswer} 받았어요!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF00C878),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: draft.goodPoints.map((point) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8FFD2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Row(
                children: [
                  ..._images.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              File(entry.value.path),
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _images.removeAt(entry.key);
                                });
                              },
                              child: const CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.black,
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: const Icon(Icons.add, size: 42),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 34),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 7,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText:
                      '✎ 당신의 후기를 작성해주세요!\n\n리뷰 작성 시 욕설, 비방, 명예훼손성 표현은 삼가해주세요.',
                  hintStyle: TextStyle(
                    fontSize: 17,
                    height: 1.45,
                    color: Color(0xFF888888),
                  ),
                ),
                style: const TextStyle(fontSize: 17, height: 1.45),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
