import '../models/store.dart';

final List<Map<String, dynamic>> storeJson = [
  {
    "id": 1,
    "name": "육회본가",
    "category": "FOOD",
    "category_detail": "일반 음식점/한식",
    "address": "경기도 포천시 일동면 화동로 1051번길 7",
    "latitude": 37.9573894208327,
    "longitude": 127.316846982356,
    "phone": "031-534-8886",
    "open_time": "15:00",
    "close_time": "03:00",
    "menu": "육회",
    "benefit_description": "이용금액의 5% 할인",
    "discount_rate": 5,
    "is_military_benefit": true,
    "is_benefit_verified": false,
  },
];

List<Store> getDummyStores() {
  return storeJson.map((json) => Store.fromJson(json)).toList();
}
