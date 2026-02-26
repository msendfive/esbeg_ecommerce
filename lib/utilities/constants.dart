import 'package:flutter/material.dart';

// ─── BASE URL ────────────────────────────────────────────────────────────────

const String kBaseUrl = 'http://192.168.2.35:8000';

String getBrandLogoUrl(String path) => '$kBaseUrl/storage/$path';

// ─── API ENDPOINTS ───────────────────────────────────────────────────────────

const String kBrandEndpoint = '$kBaseUrl/api/brand';
const String kCategoryEndpoint = '$kBaseUrl/api/category';
const String kProductEndpoint = '$kBaseUrl/api/product';

// ─── COLORS ──────────────────────────────────────────────────────────────────

const Color kPrimaryColor = Color(0xFF0E2861); // Deep navy – main brand colour
const Color kSecondaryColor = Color(
  0xFF1A3A8F,
); // Slightly lighter navy for hover / active states
const Color kAccentColor = Color(
  0xFFE8B84B,
); // Gold accent for highlights / CTAs
const Color kScaffoldBgColor = Color(0xFFF8F9FA); // Off-white page background
const Color kSurfaceColor = Colors.white; // Card / sheet surfaces
const Color kBorderColor = Color(0xFFE0E0E0); // Subtle dividers and borders
const Color kTextPrimaryColor = Color(0xFF1A1A2E); // Near-black body text
const Color kTextSecondaryColor = Color(0xFF6B7280); // Muted labels / captions
const Color kErrorColor = Color(0xFFE53E3E); // Validation / error states

// ─── ASSETS – IMAGES ─────────────────────────────────────────────────────────

const String kSizeGuideImage = 'assets/images/size_guide.png';

// ─── ASSETS – LOGOS ──────────────────────────────────────────────────────────

const String kEsbegLogo = 'assets/logo/esbeg_logo.png';
const String kGoogleLogo = 'assets/logo/google_logo.png';
const String kInstagramLogo = 'assets/logo/instagram_logo.png';
const String kWhatsappLogo = 'assets/logo/whatsapp_logo.png';

// ─── SPACING ─────────────────────────────────────────────────────────────────

const double kSpaceXS = 4.0;
const double kSpaceSM = 8.0;
const double kSpaceMD = 12.0;
const double kSpaceLG = 16.0;
const double kSpaceXL = 20.0;
const double kSpace2XL = 24.0;
const double kSpace3XL = 32.0;

// ─── BORDER RADII ────────────────────────────────────────────────────────────

const double kRadiusSM = 8.0;
const double kRadiusMD = 14.0;
const double kRadiusLG = 16.0;
const double kRadiusXL = 20.0;

// ─── SECTION HEADER ──────────────────────────────────────────────────────────
// Reusable accent-bar + title row used by every home section.

Widget kSectionHeader(String title) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: kSpaceXL),
  child: Row(
    children: [
      Container(
        width: 4,
        height: 24,
        decoration: BoxDecoration(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: kSpaceMD),
      Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: kTextPrimaryColor,
        ),
      ),
    ],
  ),
);
