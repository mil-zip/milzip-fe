import 'package:flutter/material.dart';

class FreeTextScreen extends StatelessWidget {
  final TextEditingController controller;

  const FreeTextScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final examples = [
      '삼겹살 먹고 싶어요',
      '분위기 좋은 데이트 장소 추천해주세요',
      '조용히 책 읽을 수 있는 카페',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '편하게 이야기해주세요',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: Color(0xFF6B9358), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B9358),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '이렇게 입력해보세요',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B9358)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...examples.map((text) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B9358).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF6B9358).withOpacity(0.15)),
                  ),
                  child: Text(
                    '"$text"',
                    style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.5, fontStyle: FontStyle.italic),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
