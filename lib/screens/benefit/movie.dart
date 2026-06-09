import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/movie.dart';
import '../../models/theater.dart';
import '../../data/movie_dummy.dart';
import '../../data/theater_dummy.dart';
import '../../services/movie_api.dart';
import '../../services/user_service.dart';

class MovieSection extends StatefulWidget {
  const MovieSection({super.key});

  @override
  State<MovieSection> createState() => _MovieSectionState();
}

class _MovieSectionState extends State<MovieSection> {
  List<Movie> _movies = [];
  List<Theater> _theaters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // ignore: avoid_print
    print('[benefit-movie] init');
    _loadData();
  }

  Future<void> _loadData() async {
    // ignore: avoid_print
    print('[benefit-movie] load start');
    try {
      final results = await Future.wait([
        MovieApi.getBoxOffice(),
        MovieApi.getCinemas(),
        UserService.getBenefitFavorites().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      final savedIds = (results[2] as List<dynamic>)
          .map((e) => ((e as Map<String, dynamic>)['benefitId'] as num?)?.toInt())
          .whereType<int>()
          .toSet();
      // ignore: avoid_print
      print('[benefit-movie] load success movies=${(results[0] as List).length} theaters=${(results[1] as List).length}');
      if (!mounted) return;
      setState(() {
        _movies = (results[0] as List)
            .map((j) => Movie.fromApi(j as Map<String, dynamic>))
            .toList();
        _theaters = (results[1] as List).map((j) {
          final t = Theater.fromApi(j as Map<String, dynamic>);
          t.isBookmarked = savedIds.contains(t.id);
          return t;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('[benefit-movie] load error $e');
      if (!mounted) return;
      setState(() {
        _movies = getDummyMovies();
        _theaters = getDummyTheaters();
        _isLoading = false;
      });
    }
  }

  void _showBookingSheet(BuildContext context, Movie movie) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final cinemas = [
          {
            'name': 'CGV',
            'logo': 'assets/images/cgv_logo.png',
            'url': 'https://www.cgv.co.kr',
          },
          {
            'name': '메가박스',
            'logo': 'assets/images/megabox_logo.jpg',
            'url': 'https://www.megabox.co.kr',
          },
          {
            'name': '롯데시네마',
            'logo': 'assets/images/lotte_logo.png',
            'url': 'https://www.lottecinema.co.kr',
          },
        ];

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\'${movie.title}\' 예매하기',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              ...cinemas.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final uri = Uri.parse(c['url']!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  c['logo']!,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              '${c['name']}에서 예매',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Color(0xFFAAAAAA),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final topMovie = _movies.isNotEmpty ? _movies.first : null;
    final otherMovies = _movies.length > 1 ? _movies.sublist(1) : <Movie>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text(
            '이번주 박스오피스',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),

        if (topMovie != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => _showBookingSheet(context, topMovie),
              child: _ChartHeroCard(movie: topMovie),
            ),
          ),

        const SizedBox(height: 28),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Text(
            '상영 중인 다른 영화',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: otherMovies.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () =>
                      _showBookingSheet(context, otherMovies[index]),
                  child: _OtherMovieCard(movie: otherMovies[index]),
                ),
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
            onBookmarkToggle: () async {
              final messenger = ScaffoldMessenger.of(context);
              final newState = !theater.isBookmarked;
              setState(() => theater.isBookmarked = newState);
              try {
                if (newState) {
                  await UserService.addBenefitFavorite(theater.id);
                } else {
                  await UserService.removeBenefitFavorite(theater.id);
                }
              } catch (_) {
                if (mounted) setState(() => theater.isBookmarked = !newState);
              }
              if (!mounted) return;
              messenger.clearSnackBars();
              messenger.showSnackBar(
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

// ── 포스터 이미지 헬퍼 ───────────────────────────────────────────────────────
Widget _buildPoster(Movie movie, {BoxFit fit = BoxFit.cover}) {
  if (movie.isPosterNetwork) {
    return Image.network(
      movie.posterAsset!,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: movie.posterColor,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white54,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: movie.posterColor,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              movie.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  } else if (movie.posterAsset != null) {
    return Image.asset(movie.posterAsset!, fit: fit);
  }
  return Container(color: movie.posterColor);
}

// ── 1위 큰 카드 ─────────────────────────────────────────────────────────────
class _ChartHeroCard extends StatelessWidget {
  final Movie movie;
  const _ChartHeroCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: movie.posterColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPoster(movie),
          // 하단 그라디언트 (얇게)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                ),
              ),
            ),
          ),
          // 순위 배지
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '${movie.rank}위',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // 하단 정보
          Positioned(
            bottom: 12,
            left: 14,
            right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${movie.genre} · ${movie.runtimeLabel} · ${movie.formattedAudience}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 다른 영화 카드 ──────────────────────────────────────────────────────────
class _OtherMovieCard extends StatelessWidget {
  final Movie movie;
  const _OtherMovieCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 115,
      height: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 165,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: movie.posterColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPoster(movie),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '${movie.rank}위',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: Text(
              movie.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 영화관 할인 행 (로고 이미지 사용) ────────────────────────────────────────
class _TheaterRow extends StatelessWidget {
  final Theater theater;
  final VoidCallback onBookmarkToggle;

  const _TheaterRow({required this.theater, required this.onBookmarkToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            // 로고 이미지
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
              ),
              child: theater.logoAsset != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        theater.logoAsset!,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Center(
                      child: Text(
                        theater.logoText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theater.brandColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theater.brand,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    theater.benefit.replaceAll(' · ', '\n'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
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
                  color: theater.isBookmarked
                      ? const Color(0xFF6B9358)
                      : const Color(0xFFCCCCCC),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
