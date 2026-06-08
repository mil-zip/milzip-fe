import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  final VoidCallback onReset;

  const ResultsScreen({super.key, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        spacing: 12,
        children: [
          ResultCard(
            title: '두둑한한판',
            address: '경기도 파주시 광탄면 보광로 646',
            benefit: '군장병 10% 할인',
            distance: '1.2km',
          ),
          ResultCard(
            title: '커피에반하다(금촌역점)',
            address: '경기도 파주시 새꽃로 200',
            benefit: '군장병 마카롱 제공',
            distance: '1.2km',
          ),
        ],
      ),
    );
  }
}

class ResultCard extends StatelessWidget {
  final String title;
  final String address;
  final String benefit;
  final String distance;

  const ResultCard({
    super.key,
    required this.title,
    required this.address,
    required this.benefit,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.image, color: Colors.grey[400], size: 40),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFBA31).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '군장병 할인 제공',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFD4973A)),
                  ),
                ),
                Text(distance, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
