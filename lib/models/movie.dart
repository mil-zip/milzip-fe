import 'package:flutter/material.dart';

class Movie {
  final int id;
  final String title;
  final String genre;
  final int runtimeMinutes;
  final int totalAudience;
  final int rank;
  final String tagline;
  final String? posterAsset;
  final String posterColorHex;

  Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.runtimeMinutes,
    required this.totalAudience,
    required this.rank,
    required this.tagline,
    required this.posterColorHex,
    this.posterAsset,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'],
      genre: json['genre'],
      runtimeMinutes: json['runtime_minutes'],
      totalAudience: json['total_audience'],
      rank: json['rank'],
      tagline: json['tagline'] ?? '',
      posterColorHex: json['poster_color'] ?? '#555555',
      posterAsset: json['poster_asset'],
    );
  }

  /// 실제 API 응답용
  factory Movie.fromApi(Map<String, dynamic> json) {
    return Movie(
      id: int.tryParse(json['movieCd'] ?? '') ?? 0,
      title: json['title'] ?? '',
      genre: json['genre'] ?? '',
      runtimeMinutes: json['runtimeMinutes'] ?? 0,
      totalAudience: json['audienceCount'] ?? 0,
      rank: json['rank'] ?? 0,
      tagline: '',
      posterColorHex: '#333333',
      posterAsset: json['posterUrl'],  // 네트워크 이미지 URL
    );
  }

  /// posterAsset이 URL인지 확인
  bool get isPosterNetwork =>
      posterAsset != null && posterAsset!.startsWith('http');

  String get formattedAudience {
    if (totalAudience >= 10000) {
      final man = (totalAudience / 10000).round();
      return '$man만 관객';
    }
    return '$totalAudience명';
  }

  String get runtimeLabel => '$runtimeMinutes분';

  Color get posterColor {
    final hex = posterColorHex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  String get infoLine => '$title | $genre · $runtimeLabel · $formattedAudience';
}

class MoviePoster extends StatelessWidget {
  final Movie movie;

  const MoviePoster({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        image: movie.posterAsset != null
            ? DecorationImage(
                image: AssetImage(movie.posterAsset!),
                fit: BoxFit.cover,
              )
            : null,
        color: movie.posterColor,
      ),
    );
  }
}
