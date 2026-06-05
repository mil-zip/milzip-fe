import '../models/theme_park.dart';

// 백엔드 응답 JSON을 그대로 모방한 더미 데이터
// 나중에 실제 API 연동 시 fetchThemeParks()만 http.get으로 바꾸면 됨
const List<Map<String, dynamic>> _themeParkJsonData = [
  {
    "id": 1,
    "themepark_name": "에버랜드",
    "address": "경기도 용인시 처인구 포곡읍 에버랜드로 199",
    "latitude": 37.2939104,
    "longitude": 127.2025664,
    "benefit": "휴가 군인·공익 본인 한정 1회 무료 자유이용권",
    "discount_type": "FREE",
    "original_price": 62000,
    "discounted_price": 0,
    "required_document": "휴가증, 병력증명서",
    "valid_until": "2026-09-30",
    "image_asset": "assets/images/park_everland.png",
  },
  {
    "id": 2,
    "themepark_name": "롯데월드",
    "address": "서울특별시 송파구 올림픽로 240",
    "latitude": 37.5111158,
    "longitude": 127.0981670,
    "benefit": "휴가 군인 자유이용권 3만원 할인",
    "discount_type": "AMOUNT",
    "original_price": 67000,
    "discounted_price": 37000,
    "required_document": "휴가증, 병력증명서",
    "valid_until": null,
    "image_asset": "assets/images/park_lotte.png",
  },
  {
    "id": 3,
    "themepark_name": "서울랜드",
    "address": "경기도 과천시 광명로 181",
    "latitude": 37.4341563,
    "longitude": 127.0201267,
    "benefit": "하나은행 나라사랑카드 결제 시 70% 할인 (동반 1인 포함)",
    "discount_type": "PERCENTAGE",
    "original_price": 52000,
    "discounted_price": 15600,
    "required_document": "휴가증, 나라사랑카드",
    "valid_until": null,
    "image_asset": "assets/images/park_seoul.png",
  },
];

// 더미 데이터 가져오기
// TODO: 나중에 백엔드 연동 시 http 요청으로 교체
//   Future<List<ThemePark>> fetchThemeParks() async {
//     final response = await http.get(Uri.parse('$baseUrl/themeparks'));
//     final json = jsonDecode(response.body);
//     return (json['themeparks'] as List)
//         .map((e) => ThemePark.fromJson(e))
//         .toList();
//   }
List<ThemePark> getDummyThemeParks() {
  return _themeParkJsonData.map((json) => ThemePark.fromJson(json)).toList();
}
