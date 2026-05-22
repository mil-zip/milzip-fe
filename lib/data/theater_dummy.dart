import '../models/theater.dart';

// 백엔드 응답 JSON 구조와 동일
// 나중에 fetchTheaters() 함수로 교체 (http 호출)
const List<Map<String, dynamic>> _theaterJsonData = [
  {
    "id": 1,
    "theater_brand": "CGV",
    "benefit":
        "일반(2D) 주중/주말 10,000원 · 3D 주중(월~목) 11,000원, 주말(금~일) 12,000원 (동반 4인까지 할인 가능)",
    "required_document": "휴가증, 군인증",
    "discount_type": "AMOUNT",
    "external_link": "https://www.cgv.co.kr",
    "created_at": "2026-04-15 10:30:00",
    "updated_at": null,
  },
  {
    "id": 2,
    "theater_brand": "롯데시네마",
    "benefit": "월 6매씩 영화 1만원권 관람권 제공",
    "required_document": "휴가증, 군인증",
    "discount_type": "VOUCHER",
    "external_link": "https://www.lottecinema.co.kr",
    "created_at": "2026-04-15 10:30:00",
    "updated_at": null,
  },
  {
    "id": 3,
    "theater_brand": "메가박스",
    "benefit": "일반관 11,000원 (7천원 할인) · 컴포트관 12,000원 (6천원 할인), 동반 4인까지 할인 가능",
    "required_document": "휴가증, 군인증",
    "discount_type": "AMOUNT",
    "external_link": "https://www.megabox.co.kr",
    "created_at": "2026-04-15 10:30:00",
    "updated_at": null,
  },
];

List<Theater> getDummyTheaters() {
  return _theaterJsonData.map((json) => Theater.fromJson(json)).toList();
}
