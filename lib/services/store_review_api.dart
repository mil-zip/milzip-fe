import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/store_review.dart';
import '../models/store_review_draft.dart';
import '../services/auth_service.dart';
import '../utils/auth_expired_exception.dart';
import 'api_client.dart';

MediaType _imageMediaType(String path) {
  final ext = path.split('.').last.toLowerCase();
  final sub = switch (ext) {
    'jpg' || 'jpeg' => 'jpeg',
    'png'           => 'png',
    'webp'          => 'webp',
    'heic'          => 'heic',
    'heif'          => 'heif',
    _               => 'jpeg',
  };
  return MediaType('image', sub);
}

class StoreReviewApi {
  /// GET /stores/{storeId}/reviews — 리뷰 목록 + goodPointCounts 조회
  static Future<StoreReviewResult> getList({
    required int storeId,
    int page = 0,
    int size = 10,
  }) async {
    final data = await ApiClient.get(
      '/stores/$storeId/reviews?page=$page&size=$size',
    );
    return StoreReviewResult.fromJson(data as Map<String, dynamic>);
  }

  /// GET /stores/{storeId}/reviews/{reviewId} — 리뷰 단건 조회
  static Future<StoreReview> getSingle({
    required int storeId,
    required int reviewId,
  }) async {
    final data = await ApiClient.get('/stores/$storeId/reviews/$reviewId');
    return StoreReview.fromJson(data as Map<String, dynamic>);
  }

  /// POST /stores/{storeId}/reviews — 리뷰 작성
  /// 이미지가 있으면 multipart, 없으면 JSON으로 전송
  static Future<StoreReview> create({
    required int storeId,
    required SubmittedStoreReview submitted,
  }) async {
    final draft = submitted.draft;
    final userInfo = await AuthService.getUserInfo();
    final isMilitary = userInfo['militaryStatus'] == 'VERIFIED';

    final body = <String, dynamic>{
      'rating': draft.rating.round(),
      if (isMilitary && draft.benefitStatusEnum.isNotEmpty)
        'benefitStatus': draft.benefitStatusEnum,
      'visitType': draft.visitTypeEnum,
      'waitTime': draft.waitTimeEnum,
      'visitPurpose': draft.visitPurposeEnum,
      'visitWith': draft.visitWithEnum,
      'goodPoints': draft.goodPointEnums,
      'content': submitted.content,
    };

    if (submitted.imageFiles.isEmpty) {
      final data = await ApiClient.post(
        '/stores/$storeId/reviews',
        body: body,
      );
      return StoreReview.fromJson(data as Map<String, dynamic>);
    }

    // 이미지가 있으면 multipart 전송 (401/403 시 토큰 갱신 후 1회 재시도)
    for (int attempt = 1; attempt <= 2; attempt++) {
      final token = await AuthService.getAccessToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiClient.baseUrl}/stores/$storeId/reviews'),
      );
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      request.fields['rating'] = draft.rating.round().toString();
      if (isMilitary && draft.benefitStatusEnum.isNotEmpty) {
        request.fields['benefitStatus'] = draft.benefitStatusEnum;
      }
      request.fields['visitType'] = draft.visitTypeEnum;
      request.fields['waitTime'] = draft.waitTimeEnum;
      request.fields['visitPurpose'] = draft.visitPurposeEnum;
      request.fields['visitWith'] = draft.visitWithEnum;
      request.fields['content'] = submitted.content;
      for (int i = 0; i < draft.goodPointEnums.length; i++) {
        request.fields['goodPoints[$i]'] = draft.goodPointEnums[i];
      }
      for (final xfile in submitted.imageFiles) {
        final bytes = await xfile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: xfile.name,
          contentType: _imageMediaType(xfile.name),
        ));
      }

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      if ((response.statusCode == 401 || response.statusCode == 403) && attempt == 1) {
        try {
          await AuthService.refreshTokens();
        } catch (_) {
          await AuthService.clearTokens();
          throw const AuthExpiredException();
        }
        continue;
      }
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('리뷰 작성 실패: ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['success'] != true) {
        throw Exception(decoded['message'] ?? '리뷰 작성 실패');
      }
      return StoreReview.fromJson(decoded['data'] as Map<String, dynamic>);
    }
    throw Exception('리뷰 작성 실패');
  }

  /// PUT /stores/{storeId}/reviews/{reviewId} — 리뷰 수정 (multipart/form-data)
  /// [newImagePaths] null이면 images 필드 미전송(기존 이미지 유지),
  /// 빈 리스트면 이미지 전체 삭제, 경로 있으면 해당 파일로 교체
  static Future<StoreReview> update({
    required int storeId,
    required int reviewId,
    required Map<String, dynamic> fields,
    List<XFile>? newImageFiles,
    List<String>? keepImageUrls,
  }) async {
    for (int attempt = 1; attempt <= 2; attempt++) {
      final token = await AuthService.getAccessToken();
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiClient.baseUrl}/stores/$storeId/reviews/$reviewId'),
      );
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      // 텍스트 필드
      fields.forEach((key, value) {
        if (value == null) return;
        if (value is List) {
          for (int i = 0; i < value.length; i++) {
            request.fields['$key[$i]'] = value[i].toString();
          }
        } else {
          request.fields[key] = value.toString();
        }
      });

      // 이미지 변경 있을 때만 images 필드 전송 (null이면 서버가 기존 유지)
      if (newImageFiles != null || keepImageUrls != null) {
        // 기존 이미지 URL → bytes로 다운로드 후 첨부
        for (final url in keepImageUrls ?? []) {
          try {
            final res = await http.get(Uri.parse(url));
            final filename = url.split('/').last.split('?').first;
            request.files.add(http.MultipartFile.fromBytes(
              'images',
              res.bodyBytes,
              filename: filename,
              contentType: _imageMediaType(filename),
            ));
          } catch (_) {}
        }
        // 새 이미지
        for (final xfile in newImageFiles ?? []) {
          final bytes = await xfile.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: xfile.name,
            contentType: _imageMediaType(xfile.name),
          ));
        }
      }

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      if ((response.statusCode == 401 || response.statusCode == 403) && attempt == 1) {
        try {
          await AuthService.refreshTokens();
        } catch (_) {
          await AuthService.clearTokens();
          throw const AuthExpiredException();
        }
        continue;
      }
      if (response.statusCode != 200 && response.statusCode != 204) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(decoded?['message'] ?? '리뷰 수정 실패 (${response.statusCode})');
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['success'] != true) {
        throw Exception(decoded['message'] ?? '리뷰 수정 실패');
      }
      return StoreReview.fromJson(decoded['data'] as Map<String, dynamic>);
    }
    throw Exception('리뷰 수정 실패');
  }

  /// DELETE /stores/{storeId}/reviews/{reviewId} — 리뷰 삭제
  static Future<void> deleteReview({
    required int storeId,
    required int reviewId,
  }) async {
    await ApiClient.delete('/stores/$storeId/reviews/$reviewId');
  }

  /// POST /stores/{storeId}/reviews/receipt-verify — 영수증 OCR 검증
  static Future<Map<String, dynamic>> verifyReceipt({
    required int storeId,
    required XFile receiptImage,
  }) async {
    final bytes = await receiptImage.readAsBytes();
    // 401 시 토큰 갱신 후 1회 재시도
    for (int attempt = 1; attempt <= 2; attempt++) {
      final token = await AuthService.getAccessToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiClient.baseUrl}/stores/$storeId/reviews/receipt-verify'),
      );
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.files.add(
        http.MultipartFile.fromBytes(
          'receiptImage',
          bytes,
          filename: receiptImage.name,
          contentType: _imageMediaType(receiptImage.name),
        ),
      );

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      if ((response.statusCode == 401 || response.statusCode == 403) && attempt == 1) {
        try {
          await AuthService.refreshTokens();
        } catch (_) {
          await AuthService.clearTokens();
          throw const AuthExpiredException();
        }
        continue;
      }
      if (response.statusCode != 200) {
        throw Exception('영수증 인증 실패 (${response.statusCode})');
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['success'] != true) {
        throw Exception(decoded['message'] ?? '영수증 인증 실패');
      }
      final data = decoded['data'] as Map<String, dynamic>? ?? {};
      if (data['verified'] != true) {
        throw Exception(data['message'] ?? '영수증 인증에 실패했습니다.');
      }
      return data;
    }
    throw Exception('영수증 인증 실패');
  }
}
