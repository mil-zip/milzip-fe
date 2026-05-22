import '../models/certificate.dart';

List<Certificate> getDummyCertificates() {
  return [
    Certificate(
      id: 1,
      examName: 'TOEIC',
      originalPrice: 52500,
      discountPrice: 26250,
      discountRate: 50,
      eligibility: '현역 군인 (육군, 해군, 공군, 해병대)',
      requiredDoc: '군인 신분증, 휴가증',
    ),
    Certificate(
      id: 2,
      examName: 'TOEIC Speaking',
      originalPrice: 77000,
      discountPrice: 61600,
      discountRate: 20,
      eligibility: '현역 군인 (육군, 해군, 공군, 해병대)',
      requiredDoc: '군인 신분증, 휴가증',
    ),
    Certificate(
      id: 3,
      examName: 'TEPS',
      originalPrice: 49000,
      discountPrice: 24500,
      discountRate: 50,
      eligibility: '현역 군인 (육군, 해군, 공군, 해병대)',
      requiredDoc: '군인 신분증, 휴가증',
    ),
    Certificate(
      id: 4,
      examName: 'G-TELP',
      originalPrice: 69300,
      discountPrice: 36200,
      discountRate: 48,
      eligibility: '현역 군인 (육군, 해군, 공군, 해병대)',
      requiredDoc: '군인 신분증, 휴가증',
    ),
  ];
}