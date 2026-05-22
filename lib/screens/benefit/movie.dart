import 'package:flutter/material.dart';
import '../../models/movie.dart';
import '../../models/theater.dart';
import '../../data/movie_dummy.dart';
import '../../data/theater_dummy.dart';

// ─── 영화 섹션 (BenefitCollectionScreen에서 영화 탭 누를 때 보여줄 위젯) ─────────

class MovieSection extends StatefulWidget {
  const MovieSection({super.key});

  @override
  State<MovieSection> createState() => _MovieSectionState();
}

class _MovieSectionState extends State<MovieSection> {
  late List<Movie> _movies;
  late List<Theater> _theaters;

  @override
  void initState() {
    super.initState();
    _movies = getDummyMovies();
    _theaters = getDummyTheaters();
  }

  @override
  Widget build(BuildContext context) {
    final topMovie = _movies.firstWhere((m) => m.rank == 1);
    final otherMovies = _movies.where((m) => m.rank > 1).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text(
            '이번주 상영 차트',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _ChartHeroCard(movie: topMovie),
        ),

        const SizedBox(height: 28),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '상영 중인 다른 영화',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  '전체보기 >',
                  style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: otherMovies.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _OtherMovieCard(movie: otherMovies[index]),
              );
            },
          ),
        ),

        const SizedBox(height: 28),

        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            '영화관별 할인 혜택',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),

        ..._theaters.map(
          (theater) => _TheaterRow(
            theater: theater,
            onBookmarkToggle: () {
              setState(() => theater.isBookmarked = !theater.isBookmarked);

              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    theater.isBookmarked
                        ? '${theater.brand}이(가) 저장되었습니다!'
                        : '${theater.brand} 저장이 취소되었습니다',
                  ),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── 차트 1위 큰 카드 ──────────────────────────────────────────────────────────

class _ChartHeroCard extends StatelessWidget {
  final Movie movie;

  const _ChartHeroCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: movie.posterColor,
        borderRadius: BorderRadius.circular(14),
        image: movie.posterAsset != null
            ? DecorationImage(
                image: AssetImage(movie.posterAsset!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '예매율 ${movie.rank}위',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),

          if (movie.posterAsset == null)
            Center(
              child: Text(
                movie.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black.withOpacity(0.45),
              child: Text(
                movie.infoLine,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 다른 영화 카드 (작은 포스터) ──────────────────────────────────────────────

class _OtherMovieCard extends StatelessWidget {
  final Movie movie;

  const _OtherMovieCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 105,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: movie.posterColor,
              borderRadius: BorderRadius.circular(10),
              image: movie.posterAsset != null
                  ? DecorationImage(
                      image: AssetImage(movie.posterAsset!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '예매율 ${movie.rank}위',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ),

                if (movie.posterAsset == null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        movie.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 영화관 할인 행 ────────────────────────────────────────────────────────────

class _TheaterRow extends StatelessWidget {
  final Theater theater;
  final VoidCallback onBookmarkToggle;

  const _TheaterRow({required this.theater, required this.onBookmarkToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Center(
              child: Text(
                theater.logoText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theater.brandColor,
                  fontSize: theater.brand == '메가박스' ? 9 : 11,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              theater.benefit,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1A1A1A),
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(width: 8),

          GestureDetector(
            onTap: onBookmarkToggle,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                theater.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                key: ValueKey(theater.isBookmarked),
                color: const Color(0xFF1A1A1A),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
