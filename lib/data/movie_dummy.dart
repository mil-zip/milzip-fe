import '../models/movie.dart';

// 영화 차트 더미 데이터
// 백엔드 API 추가 시 fetchMovies()로 교체
const List<Map<String, dynamic>> _movieJsonData = [
  {
    "id": 1,
    "title": "살목지",
    "genre": "스릴러",
    "runtime_minutes": 119,
    "total_audience": 600000,
    "rank": 1,
    "poster_color": "#3A3A3A",
    "poster_asset": "assets/images/movie_salmokji.png", // 포스터 사진
  },
  {
    "id": 2,
    "title": "프로젝트 헤일메리",
    "genre": "SF",
    "runtime_minutes": 130,
    "total_audience": 450000,
    "rank": 2,
    "tagline": "",
    "poster_color": "#4A6FA5",
    "poster_asset": "assets/images/movie_project.png", // 포스터 사진
  },
  {
    "id": 3,
    "title": "왕과 사는 남자",
    "genre": "사극",
    "runtime_minutes": 125,
    "total_audience": 320000,
    "rank": 3,
    "tagline": "",
    "poster_color": "#6B4423",
    "poster_asset": "assets/images/movie_kingwithman.png", // 포스터 사진
  },
  {
    "id": 4,
    "title": "악마는 프라다를 입는다",
    "genre": "드라마",
    "runtime_minutes": 109,
    "total_audience": 280000,
    "rank": 4,
    "tagline": "",
    "poster_color": "#C0392B",
    "poster_asset": "assets/images/movie_devilwearprada.png", // 포스터 사진
  },
];

List<Movie> getDummyMovies() {
  return _movieJsonData.map((json) => Movie.fromJson(json)).toList();
}
