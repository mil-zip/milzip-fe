import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Primary (올리브 그린 계열) ───────────────────────────────────────────
  static const Color pressed = Color(0xFF1F2E22);

  static const Color primary = Color(0xFF293C2C);
  static const Color primary1 = Color(0xFF293C2C);

  static const Color primaryHover = Color(0xFF344B37);
  static const Color hover = Color(0xFF344B37);

  static const Color selected = Color(0xFF455F3B);
  static const Color primary2 = Color(0xFF455F3B);
  static const Color active = Color(0xFF455F3B);

  static const Color primaryAccent = Color(0xFF6B9358);
  static const Color primaryLight = Color(0xFF6B9358); // 밝은 그린 (아이콘 등)

  // ── Secondary / 서브 메인 (앰버 골드) ────────────────────────────────────
  // 올리브 그린과 군 계급장 느낌으로 페어링
  static const Color secondary = Color(0xFFFFBA31); // 서브 메인
  static const Color secondaryDark = Color(0xFFD4973A); // 진한 앰버 (텍스트·아이콘)
  static const Color secondaryBg = Color(0xFFFFF8E7); // 연한 앰버 배경

  // ── Background / Surface ─────────────────────────────────────────────────
  static const Color background = Color(0xFFF8F9F6);
  static const Color bg = Color(0xFFF8F9F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFEEF2EA);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textMain = Color(0xFF111111);
  static const Color textSub = Color(0xFF666666);
  static const Color textAccent = Color(0xFF455F3B);
  static const Color textWhite = Color(0xFFFFFFFF);

  // ── Border ───────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFDDE4D8);

  // ── Badge (밀집추천) ──────────────────────────────────────────────────────
  static const Color badge = Color(0xFFDCE8D6);
  static const Color badgeText = Color(0xFF293C2C);

  // ── Discount → secondary 계열로 통일 ────────────────────────────────────
  static const Color discountBg = secondaryBg;
  static const Color discountBorder = secondaryDark;
  static const Color discountText = Color(0xFF7A5520);
}
