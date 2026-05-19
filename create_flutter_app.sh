#!/bin/bash

# ============================================================
#  Flutter Clean Architecture — Project Bootstrap Script
#  Based on project guidelines: clean arch, provider, GoRouter
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
  clear
  echo -e "\n${CYAN}${BOLD}"
  echo "╔══════════════════════════════════════════════════╗"
  echo "║     Flutter Clean Architecture Bootstrap         ║"
  echo "║     Provider · GoRouter · Dio · Clean Arch       ║"
  echo "╚══════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

print_step() {
  echo -e "\n${BLUE}${BOLD}▶ $1${NC}"
}

print_success() {
  echo -e "  ${GREEN}✔ $1${NC}"
}

print_warn() {
  echo -e "  ${YELLOW}⚠ $1${NC}"
}

print_error() {
  echo -e "  ${RED}✖ $1${NC}"
}

# ── Preflight checks ────────────────────────────────────────
print_header

if ! command -v flutter &>/dev/null; then
  print_error "Flutter SDK not found. Install it from https://flutter.dev/docs/get-started/install"
  exit 1
fi
print_success "Flutter found: $(flutter --version --machine 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('frameworkVersion','?'))" 2>/dev/null || echo 'OK')"

# ── Prompt for inputs ────────────────────────────────────────
print_step "Project Configuration"

while true; do
  echo -en "\n  ${BOLD}Project name${NC} (snake_case, e.g. my_app): "
  read PROJECT_NAME
  if [[ "$PROJECT_NAME" =~ ^[a-z][a-z0-9_]*$ ]]; then
    break
  fi
  print_error "Invalid name. Use lowercase letters, numbers, underscores. Must start with a letter."
done

echo -en "  ${BOLD}Organization${NC} (e.g. com.yourcompany) [com.example]: "
read ORG_INPUT
ORG_NAME="${ORG_INPUT:-com.example}"

echo -en "  ${BOLD}Base API URL${NC} [https://your-api.com]: "
read URL_INPUT
BASE_URL="${URL_INPUT:-https://your-api.com}"

TITLE_DEFAULT=$(echo "$PROJECT_NAME" | tr '_' ' ' | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) substr($i,2)}; print}')
echo -en "  ${BOLD}App display title${NC} [$TITLE_DEFAULT]: "
read TITLE_INPUT
APP_TITLE="${TITLE_INPUT:-$TITLE_DEFAULT}"

# Derive PascalCase class prefix from project name
# e.g. my_cool_app → MyCoolApp
CLASS_PREFIX=$(echo "$PROJECT_NAME" | awk -F_ '{r=""; for(i=1;i<=NF;i++) r=r toupper(substr($i,1,1)) substr($i,2); print r}')

echo -e "\n  ${CYAN}Creating:${NC} $ORG_NAME.$PROJECT_NAME"
echo -e "  ${CYAN}API URL:${NC}  $BASE_URL"
echo -e "  ${CYAN}Title:${NC}    $APP_TITLE"
echo -en "\n  Proceed? [Y/n]: "
read CONFIRM
if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
  echo "Aborted."
  exit 0
fi

# ── Create Flutter project ───────────────────────────────────
print_step "Creating Flutter project"
flutter create --org "$ORG_NAME" --project-name "$PROJECT_NAME" "$PROJECT_NAME" --empty 2>&1 | tail -3
if [ $? -ne 0 ]; then
  print_error "flutter create failed."
  exit 1
fi
print_success "Flutter project created"

cd "$PROJECT_NAME" || exit 1

# ── Folder structure ─────────────────────────────────────────
print_step "Building folder structure"

dirs=(
  "lib/core/config"
  "lib/core/global_variables"
  "lib/core/services"
  "lib/core/widgets"
  "lib/routes"
  "lib/screens/splash"
  "lib/screens/splash/widgets"
  "lib/screens/login/models"
  "lib/screens/login/providers"
  "lib/screens/login/services"
  "lib/screens/login/widgets"
  "lib/screens/home/models"
  "lib/screens/home/providers"
  "lib/screens/home/services"
  "lib/screens/home/widgets"
  "lib/screens/settings/models"
  "lib/screens/settings/providers"
  "lib/screens/settings/services"
  "lib/screens/settings/widgets"
  "lib/theme"
  "lib/utils"
  "assets/images"
  "assets/image_icons"
)

for d in "${dirs[@]}"; do
  mkdir -p "$d"
done
print_success "Directories created"

# ── pubspec.yaml ─────────────────────────────────────────────
print_step "Writing pubspec.yaml"

cat > pubspec.yaml << PUBSPEC
name: $PROJECT_NAME
description: "$APP_TITLE — Flutter Clean Architecture"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State management
  provider: ^6.1.5+1

  # Navigation
  go_router: ^17.2.3

  # HTTP client
  dio: ^5.9.0

  # Storage
  flutter_secure_storage: ^10.0.0
  shared_preferences: ^2.5.4

  # Fonts & UI
  google_fonts: ^6.3.2
  shimmer: ^3.0.0

  # Media
  image_picker: ^1.2.2
  flutter_image_compress: ^2.4.0

  # Utilities
  intl: ^0.20.2
  connectivity_plus: ^7.0.0
  url_launcher: ^6.3.2

  # Loading states
  skeletonizer: ^1.4.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  flutter_launcher_icons: ^0.14.4

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/image_icons/
PUBSPEC

print_success "pubspec.yaml written"

# ── analysis_options.yaml ────────────────────────────────────
cat > analysis_options.yaml << 'ANALYSIS'
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_use_package_imports
    - avoid_print
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - unnecessary_const
ANALYSIS
print_success "analysis_options.yaml written"

# ── CORE FILES ────────────────────────────────────────────────
print_step "Writing core files"

# global_variables.dart
cat > lib/core/global_variables/global_variables.dart << GLOBALVARS
library;

const String baseUrl = '$BASE_URL';
const String apiKey = 'your-api-key';
const String appVersion = '1.0.0+1';
GLOBALVARS

# api_exceptions.dart
cat > lib/core/services/api_exceptions.dart << 'APIEX'
library;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}

class AuthException extends ApiException {
  AuthException(super.message, [super.statusCode]);
}

class ValidationException extends ApiException {
  ValidationException(super.message);
}
APIEX

# storage_service.dart
cat > lib/core/services/storage_service.dart << 'STORAGE'
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (kDebugMode) debugPrint('[storage_service] Initialized');
  }

  // --- Tokens (secure) ---
  static Future<void> saveToken(String token) async =>
      _secureStorage.write(key: 'access_token', value: token);

  static Future<String?> getToken() async =>
      _secureStorage.read(key: 'access_token');

  static Future<void> saveRefreshToken(String token) async =>
      _secureStorage.write(key: 'refresh_token', value: token);

  static Future<String?> getRefreshToken() async =>
      _secureStorage.read(key: 'refresh_token');

  // --- User data (secure, JSON encoded) ---
  static Future<void> saveUser(Map<String, dynamic> user) async =>
      _secureStorage.write(key: 'user_data', value: jsonEncode(user));

  static Future<Map<String, dynamic>?> getUser() async {
    final json = await _secureStorage.read(key: 'user_data');
    return json != null ? jsonDecode(json) as Map<String, dynamic> : null;
  }

  // --- Non-sensitive (SharedPreferences) ---
  static Future<void> saveEmail(String email) async =>
      _prefs?.setString('last_email', email);

  static String? getEmail() => _prefs?.getString('last_email');

  static Future<void> clearEmail() async => _prefs?.remove('last_email');

  // --- Cleanup ---
  static Future<void> clear() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'user_data');
  }

  static Future<void> clearAll() async {
    await clear();
    await _prefs?.remove('last_email');
  }

  static Future<void> clearAllSecureStorage() async =>
      _secureStorage.deleteAll();

  // --- Helpers ---
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
STORAGE

# api_client.dart
cat > lib/core/services/api_client.dart << 'APICLIENT'
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../global_variables/global_variables.dart';
import 'api_exceptions.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;

  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (object) => debugPrint('Dio: $object'),
        ),
      );
    }
  }

  static void initialize() {
    _instance ??= ApiClient._();
    if (kDebugMode) {
      debugPrint('[api_client] Initialized with base URL: $baseUrl');
    }
  }

  static ApiClient get instance {
    if (_instance == null) {
      throw Exception('[api_client] Not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    if (kDebugMode) debugPrint('[api_client] Auth token set');
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
    if (kDebugMode) debugPrint('[api_client] Auth token cleared');
  }

  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      if (kDebugMode) debugPrint('[api_client] GET $endpoint');
      return await _dio.get(endpoint,
          queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      if (kDebugMode) debugPrint('[api_client] POST $endpoint');
      return await _dio.post(endpoint,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      if (kDebugMode) debugPrint('[api_client] PUT $endpoint');
      return await _dio.put(endpoint,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      if (kDebugMode) debugPrint('[api_client] PATCH $endpoint');
      return await _dio.patch(endpoint,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      if (kDebugMode) debugPrint('[api_client] DELETE $endpoint');
      return await _dio.delete(endpoint,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException error) {
    if (kDebugMode) {
      debugPrint('[api_client] Error: ${error.type} — ${error.message}');
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Request timeout. Please try again.');
      case DioExceptionType.connectionError:
        return NetworkException('No internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = _extractErrorMessage(error.response?.data);
        if (statusCode == 401) {
          return AuthException(message ?? 'Invalid credentials.', statusCode);
        }
        if (statusCode == 400) {
          return ValidationException(message ?? 'Invalid request.');
        }
        if (statusCode == 404) {
          return ApiException(message ?? 'Not found.', statusCode);
        }
        if (statusCode != null && statusCode >= 500) {
          return ApiException('Server error. Try again later.', statusCode);
        }
        return ApiException(message ?? 'An error occurred.', statusCode);
      case DioExceptionType.cancel:
        return ApiException('Request cancelled.');
      default:
        return ApiException('Unexpected error: ${error.message}');
    }
  }

  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      if (data['errors'] is List) {
        final errors = data['errors'] as List;
        if (errors.isNotEmpty && errors.first is Map<String, dynamic>) {
          final msg =
              (errors.first as Map<String, dynamic>)['message'] as String?;
          if (msg != null && msg.isNotEmpty) return msg;
        }
      }
      return data['message'] as String? ??
          data['error'] as String? ??
          data['msg'] as String?;
    }
    if (data is String) return data;
    return null;
  }
}
APICLIENT

print_success "Core service files written"

# ── THEME ─────────────────────────────────────────────────────
print_step "Writing theme"

cat > lib/theme/app_theme.dart << 'THEME'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // --- Colors ---
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8);

  static const Color secondary = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFF8B5CF6);
  static const Color secondaryDark = Color(0xFF6D28D9);

  // Gray scale
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFE9EAEB);
  static const Color grey300 = Color(0xFFD3D7DA);
  static const Color grey400 = Color(0xFFA4A7AE);
  static const Color grey500 = Color(0xFF717680);
  static const Color grey600 = Color(0xFF535862);
  static const Color grey700 = Color(0xFF414651);
  static const Color grey800 = Color(0xFF252837);
  static const Color grey900 = Color(0xFF101828);

  // Semantic
  static const Color error = Color(0xFFD92D20);
  static const Color warning = Color(0xFFF79009);
  static const Color success = Color(0xFF12B76A);
  static const Color info = Color(0xFF0086C9);

  // Text
  static const Color textPrimary = grey900;
  static const Color textSecondary = grey600;
  static const Color textTertiary = grey500;
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Backgrounds
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFF9F9F9);
  static const Color inputBackground = Color(0xFFF9F7F9);

  // Borders
  static const Color border = grey200;
  static const Color borderLight = grey100;
  static const Color borderDark = grey300;

  // --- Text Styles ---
  static TextStyle get headlineLarge => GoogleFonts.interTight(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: 1.2,
      );

  static TextStyle get headlineMedium => GoogleFonts.interTight(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: 1.3,
      );

  static TextStyle get headlineSmall => GoogleFonts.interTight(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.3,
      );

  static TextStyle get bodyLarge => GoogleFonts.interTight(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.4,
      );

  static TextStyle get bodyMedium => GoogleFonts.interTight(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.4,
      );

  static TextStyle get bodySmall => GoogleFonts.interTight(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textTertiary,
        height: 1.4,
      );

  static TextStyle get buttonText => GoogleFonts.interTight(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textOnPrimary,
        height: 1.2,
      );

  // --- Border Radius ---
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // --- Spacing ---
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // --- ThemeData ---
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryLight,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: textOnPrimary,
        onSurface: textPrimary,
      ),
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTightTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: primary,
        elevation: 0,
        titleTextStyle: headlineMedium.copyWith(color: primary),
        iconTheme: const IconThemeData(color: primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: primary),
      iconTheme: const IconThemeData(color: primary),
    );
  }
}
THEME

print_success "app_theme.dart written"

# ── RESPONSIVE HELPER ─────────────────────────────────────────
cat > lib/utils/responsive_helper.dart << 'RESPONSIVE'
import 'package:flutter/material.dart';

class ResponsiveHelper {
  final BuildContext context;
  late final MediaQueryData _mediaQuery;
  late final double _screenWidth;
  late final double _screenHeight;

  ResponsiveHelper(this.context) {
    _mediaQuery = MediaQuery.of(context);
    _screenWidth = _mediaQuery.size.width;
    _screenHeight = _mediaQuery.size.height;
  }

  // ── Breakpoints ──────────────────────────────────────────────
  static const double _mobileMax = 600;
  static const double _desktopMin = 1200;

  // ── Device detection ─────────────────────────────────────────
  bool get isSmallMobile => _screenWidth < 350;
  bool get isMobile => _screenWidth < _mobileMax;
  bool get isTablet =>
      _screenWidth >= _mobileMax &&
      _screenWidth < _desktopMin &&
      !isIPad;

  /// iPad detected by shortestSide (physical device heuristic).
  bool get isIPad {
    final shortest = _mediaQuery.size.shortestSide;
    return shortest >= 600 && shortest < 900 && _screenWidth < _desktopMin;
  }

  bool get isDesktop => _screenWidth >= _desktopMin;
  bool get isAnyTablet => isIPad || isTablet;

  // ── Raw dimensions ────────────────────────────────────────────
  double get screenWidth => _screenWidth;
  double get screenHeight => _screenHeight;
  double get statusBarHeight => _mediaQuery.padding.top;
  double get bottomSafeArea => _mediaQuery.padding.bottom;

  // ── Percentage helpers ────────────────────────────────────────
  double wp(double percentage) => (_screenWidth * percentage) / 100;
  double hp(double percentage) => (_screenHeight * percentage) / 100;

  // ── Scaled font size ──────────────────────────────────────────
  double sp(double size) => size * _scaleFactor;
  double get _scaleFactor {
    if (isSmallMobile) return 0.85;
    if (isMobile) return 1.0;
    if (isTablet) return 1.15;
    if (isIPad) return 1.2;
    return 1.3; // desktop
  }

  // ── Spacing (height-relative — use these first) ───────────────
  double get spacingXS => hp(0.5);
  double get spacingS => hp(1.0);
  double get spacingM => hp(2.0);
  double get spacingL => hp(3.0);
  double get spacingXL => hp(4.0);
  double get spacingXXL => hp(6.0);

  // ── Common layout getters ─────────────────────────────────────
  EdgeInsets get defaultPadding {
    if (isMobile) return EdgeInsets.symmetric(horizontal: wp(4), vertical: hp(2));
    if (isTablet) return EdgeInsets.symmetric(horizontal: wp(5), vertical: hp(2.5));
    if (isIPad) return EdgeInsets.symmetric(horizontal: wp(6), vertical: hp(3));
    return EdgeInsets.symmetric(horizontal: wp(8), vertical: hp(4));
  }

  EdgeInsets get inputContentPadding {
    if (isMobile) return const EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  }

  /// Max width for form/card content — center + constrain on large screens.
  double get formWidth {
    if (isMobile) return _screenWidth * 0.9;
    if (isTablet) return 600.0;
    if (isIPad) return 650.0;
    return 700.0;
  }

  double get maxFormWidth {
    if (isMobile) return double.infinity;
    if (isTablet) return 600.0;
    if (isIPad) return 650.0;
    return 700.0;
  }

  double get buttonHeight {
    if (isMobile) return hp(6);
    if (isTablet) return hp(7);
    return hp(8);
  }

  double get formElementHeight {
    if (isMobile) return 56.0;
    return 64.0;
  }

  double get defaultBorderRadius {
    if (isMobile) return 12.0;
    if (isTablet) return 14.0;
    if (isIPad) return 14.0;
    return 16.0;
  }

  double get defaultIconSize {
    if (isMobile) return sp(24);
    if (isTablet) return sp(26);
    if (isIPad) return sp(28);
    return sp(32);
  }

  int get gridColumns {
    if (isMobile) return 1;
    if (isAnyTablet) return 2;
    return 3;
  }

  /// Returns adaptive column count based on preferred item width.
  int getAdaptiveColumns(double itemWidth) {
    return (_screenWidth / itemWidth).floor().clamp(1, 6);
  }

  // ── Text style getters ────────────────────────────────────────
  TextStyle get headlineLarge => TextStyle(
    fontSize: sp(32),
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  TextStyle get headlineMedium => TextStyle(
    fontSize: sp(28),
    fontWeight: FontWeight.bold,
    height: 1.3,
  );
  TextStyle get titleLarge => TextStyle(
    fontSize: sp(22),
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  TextStyle get titleMedium => TextStyle(
    fontSize: sp(16),
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  TextStyle get bodyLarge => TextStyle(
    fontSize: sp(16),
    fontWeight: FontWeight.normal,
    height: 1.4,
  );
  TextStyle get bodyMedium => TextStyle(
    fontSize: sp(14),
    fontWeight: FontWeight.normal,
    height: 1.4,
  );
  TextStyle get bodySmall => TextStyle(
    fontSize: sp(12),
    fontWeight: FontWeight.normal,
    height: 1.4,
  );
  TextStyle get labelSmall => TextStyle(
    fontSize: sp(11),
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // ── Static shortcuts ──────────────────────────────────────────
  static bool isMobileDevice(BuildContext context) =>
      MediaQuery.of(context).size.width < _mobileMax;

  static bool isTabletDevice(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= _mobileMax && w < _desktopMin;
  }
}
RESPONSIVE

print_success "responsive_helper.dart written"

# ── AUTH PROVIDER ─────────────────────────────────────────────
print_step "Writing auth & routing"

cat > lib/screens/login/providers/auth_main_provider.dart << 'AUTHPROVIDER'
import 'package:flutter/foundation.dart';
import '../../../core/services/api_exceptions.dart';
import '../../../core/services/storage_service.dart';
import '../services/auth_api_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthMainProvider extends ChangeNotifier {
  final AuthApiService authApiService;

  AuthMainProvider({required this.authApiService});

  // --- State ---
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  String? _userEmail;
  String _userRole = '';

  // --- Getters ---
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get userEmail => _userEmail;
  String get userRole => _userRole;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Role helpers — extend for your roles
  bool get isAdmin => _userRole == 'ADMIN';

  // ── Check stored session on startup ──────────────────────
  Future<void> checkAuthStatus() async {
    if (kDebugMode) debugPrint('[auth_main_provider] checkAuthStatus: checking');
    _setStatus(AuthStatus.loading);
    try {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        final userData = await StorageService.getUser();
        _userEmail = userData?['email'] as String?;
        _userRole = userData?['role'] as String? ?? '';
        _setStatus(AuthStatus.authenticated);
        if (kDebugMode) {
          debugPrint('[auth_main_provider] checkAuthStatus: authenticated');
        }
      } else {
        _setStatus(AuthStatus.unauthenticated);
        if (kDebugMode) {
          debugPrint('[auth_main_provider] checkAuthStatus: no token found');
        }
      }
    } catch (e) {
      _setStatus(AuthStatus.unauthenticated);
      if (kDebugMode) debugPrint('[auth_main_provider] checkAuthStatus error: $e');
    }
  }

  // ── Sign in ───────────────────────────────────────────────
  Future<bool> signIn({required String email, required String password}) async {
    _setStatus(AuthStatus.loading);
    _clearError();
    try {
      if (kDebugMode) debugPrint('[auth_main_provider] signIn: $email');
      final result = await authApiService.login(email: email, password: password);

      await StorageService.saveToken(result['token'] as String);
      await StorageService.saveUser(result['user'] as Map<String, dynamic>);
      await StorageService.saveEmail(email);

      _userEmail = email;
      _userRole = (result['user'] as Map<String, dynamic>)['role'] as String? ?? '';
      _setStatus(AuthStatus.authenticated);

      if (kDebugMode) {
        debugPrint('[auth_main_provider] signIn: success, role=$_userRole');
      }
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setStatus(AuthStatus.unauthenticated);
      if (kDebugMode) debugPrint('[auth_main_provider] signIn auth error: ${e.message}');
      return false;
    } on NetworkException catch (e) {
      _setError('Network error. Please check your connection.');
      _setStatus(AuthStatus.unauthenticated);
      if (kDebugMode) debugPrint('[auth_main_provider] signIn network error: ${e.message}');
      return false;
    } on ApiException catch (e) {
      _setError(e.message);
      _setStatus(AuthStatus.unauthenticated);
      if (kDebugMode) debugPrint('[auth_main_provider] signIn api error: ${e.message}');
      return false;
    } catch (e) {
      _setError('Unexpected error. Please try again.');
      _setStatus(AuthStatus.unauthenticated);
      if (kDebugMode) debugPrint('[auth_main_provider] signIn unexpected error: $e');
      return false;
    }
  }

  // ── Sign out ──────────────────────────────────────────────
  Future<void> signOut() async {
    if (kDebugMode) debugPrint('[auth_main_provider] signOut');
    await StorageService.clear();
    _userEmail = null;
    _userRole = '';
    _setStatus(AuthStatus.unauthenticated);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // --- Private helpers ---
  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() => _errorMessage = null;
}
AUTHPROVIDER

# auth_api_service.dart
cat > lib/screens/login/services/auth_api_service.dart << 'AUTHAPISERVICE'
import 'package:flutter/foundation.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/api_exceptions.dart';

class AuthApiService {
  final ApiClient apiClient;

  AuthApiService({required this.apiClient});

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) debugPrint('[auth_api_service] login: $email');

      final response = await apiClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      if (kDebugMode) debugPrint('[auth_api_service] login: success');
      return data;
    } on ApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('[auth_api_service] login unexpected error: $e');
      throw ApiException('[auth_api_service] Unexpected error during login');
    }
  }

  Future<void> logout() async {
    try {
      if (kDebugMode) debugPrint('[auth_api_service] logout');
      await apiClient.post('/auth/logout');
    } on ApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('[auth_api_service] logout error: $e');
    }
  }
}
AUTHAPISERVICE

print_success "Auth provider and service written"

# ── ROUTING ───────────────────────────────────────────────────
cat > lib/routes/auth_route_notifier.dart << 'AUTHNOTIFIER'
import 'package:flutter/foundation.dart';
import '../screens/login/providers/auth_main_provider.dart';

class AuthRouteNotifier extends ValueNotifier<bool> {
  final AuthMainProvider _authProvider;
  late final VoidCallback _listener;
  bool _isInitialized = false;

  AuthRouteNotifier(this._authProvider)
      : super(_authProvider.isAuthenticated) {
    _listener = _onAuthChange;
    _authProvider.addListener(_listener);

    Future.delayed(const Duration(milliseconds: 100), () {
      _isInitialized = true;
    });
  }

  void _onAuthChange() {
    final isAuthenticated = _authProvider.isAuthenticated;
    final isLoading = _authProvider.isLoading;

    if (kDebugMode) {
      if (!_isInitialized || isLoading || value == isAuthenticated) return;
    }

    if (value != isAuthenticated) {
      if (kDebugMode) {
        debugPrint(
            '[auth_route_notifier] auth changed to $isAuthenticated');
      }
      value = isAuthenticated;
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_listener);
    super.dispose();
  }
}
AUTHNOTIFIER

cat > lib/routes/app_routes.dart << 'APPROUTES'
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/login/providers/auth_main_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/settings/settings_screen.dart';
import 'auth_route_notifier.dart';

GoRouter createAppRouter(AuthMainProvider authProvider) {
  final authRouteNotifier = AuthRouteNotifier(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authRouteNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isLoading =
          authProvider.status == AuthStatus.initial ||
          authProvider.status == AuthStatus.loading;

      if (state.uri.path == '/splash') return null;

      if (kDebugMode && isLoading) {
        debugPrint(
            '[app_routes] skipping redirect during loading: ${state.uri.path}');
        return null;
      }

      final isLoginRoute = state.uri.path == '/login';

      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
APPROUTES

print_success "Routing files written"

# ── SCREENS ───────────────────────────────────────────────────
print_step "Writing screens"

# splash/widgets/splash_content.dart
cat > lib/screens/splash/widgets/splash_content.dart << SPLASHCONTENT
import 'package:flutter/material.dart';
import 'package:${PROJECT_NAME}/theme/app_theme.dart';
import 'package:${PROJECT_NAME}/utils/responsive_helper.dart';

class SplashContent extends StatelessWidget {
  const SplashContent({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.bolt_rounded,
          size: responsive.sp(80),
          color: AppTheme.textOnPrimary,
        ),
        SizedBox(height: responsive.spacingM),
        SizedBox(
          width: responsive.sp(32),
          height: responsive.sp(32),
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textOnPrimary),
            strokeWidth: 2,
          ),
        ),
      ],
    );
  }
}
SPLASHCONTENT

# splash_screen.dart
cat > lib/screens/splash/splash_screen.dart << SPLASH
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:${PROJECT_NAME}/screens/login/providers/auth_main_provider.dart';
import 'package:${PROJECT_NAME}/theme/app_theme.dart';
import 'package:${PROJECT_NAME}/screens/splash/widgets/splash_content.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final authProvider = context.read<AuthMainProvider>();
    if (authProvider.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(child: SplashContent()),
    );
  }
}
SPLASH

# login/widgets/login_header.dart
cat > lib/screens/login/widgets/login_header.dart << LOGINHEADER
import 'package:flutter/material.dart';
import 'package:${PROJECT_NAME}/theme/app_theme.dart';
import 'package:${PROJECT_NAME}/utils/responsive_helper.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.bolt_rounded, size: responsive.sp(48), color: AppTheme.primary),
        SizedBox(height: responsive.spacingS),
        Text('Welcome back', style: AppTheme.headlineMedium),
        SizedBox(height: responsive.spacingXS),
        Text('Sign in to continue', style: AppTheme.bodyMedium),
      ],
    );
  }
}
LOGINHEADER

# login/widgets/login_form.dart
cat > lib/screens/login/widgets/login_form.dart << LOGINFORM
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:${PROJECT_NAME}/screens/login/providers/auth_main_provider.dart';
import 'package:${PROJECT_NAME}/theme/app_theme.dart';
import 'package:${PROJECT_NAME}/utils/responsive_helper.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }
    final provider = context.read<AuthMainProvider>();
    final success = await provider.signIn(email: email, password: password);
    if (success && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Column(
      children: [
        SizedBox(
          height: responsive.formElementHeight,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(fontSize: responsive.sp(14)),
            decoration: InputDecoration(
              labelText: 'Email',
              contentPadding: responsive.inputContentPadding,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
        ),
        SizedBox(height: responsive.spacingM),
        SizedBox(
          height: responsive.formElementHeight,
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(fontSize: responsive.sp(14)),
            decoration: InputDecoration(
              labelText: 'Password',
              contentPadding: responsive.inputContentPadding,
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ),
        SizedBox(height: responsive.spacingL),
        _SignInButton(onPressed: _onSignIn),
      ],
    );
  }
}

class _SignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Consumer<AuthMainProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          width: double.infinity,
          height: responsive.buttonHeight,
          child: ElevatedButton(
            onPressed: provider.isLoading ? null : onPressed,
            child: provider.isLoading
                ? SizedBox(
                    height: responsive.sp(20),
                    width: responsive.sp(20),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.textOnPrimary,
                    ),
                  )
                : Text(
                    'Sign In',
                    style: TextStyle(fontSize: responsive.sp(16)),
                  ),
          ),
        );
      },
    );
  }
}
LOGINFORM

# login/widgets/login_error.dart
cat > lib/screens/login/widgets/login_error.dart << LOGINERROR
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:${PROJECT_NAME}/screens/login/providers/auth_main_provider.dart';
import 'package:${PROJECT_NAME}/theme/app_theme.dart';
import 'package:${PROJECT_NAME}/utils/responsive_helper.dart';

class LoginError extends StatelessWidget {
  const LoginError({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Consumer<AuthMainProvider>(
      builder: (context, provider, _) {
        if (provider.errorMessage == null) return const SizedBox.shrink();
        return Container(
          padding: EdgeInsets.all(responsive.spacingS),
          decoration: BoxDecoration(
            color: AppTheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(responsive.defaultBorderRadius),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppTheme.error,
                size: responsive.sp(16),
              ),
              SizedBox(width: responsive.spacingS),
              Expanded(
                child: Text(
                  provider.errorMessage!,
                  style: TextStyle(
                    fontSize: responsive.sp(12),
                    color: AppTheme.error,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
LOGINERROR

# login_screen.dart
cat > lib/screens/login/login_screen.dart << LOGINSCREEN
import 'package:flutter/material.dart';
import 'package:${PROJECT_NAME}/theme/app_theme.dart';
import 'package:${PROJECT_NAME}/utils/responsive_helper.dart';
import 'package:${PROJECT_NAME}/screens/login/widgets/login_header.dart';
import 'package:${PROJECT_NAME}/screens/login/widgets/login_form.dart';
import 'package:${PROJECT_NAME}/screens/login/widgets/login_error.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: _maxContentWidth(responsive),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _horizontalPadding(responsive),
                          vertical: _verticalPadding(responsive),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const LoginHeader(),
                            SizedBox(height: responsive.spacingXL),
                            const LoginForm(),
                            SizedBox(height: responsive.spacingM),
                            const LoginError(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _horizontalPadding(ResponsiveHelper r) {
    if (r.isMobile) return 20.0;
    if (r.isTablet) return 24.0;
    if (r.isIPad) return 28.0;
    return 32.0;
  }

  double _verticalPadding(ResponsiveHelper r) {
    if (r.isMobile) return 16.0;
    if (r.isTablet) return 20.0;
    if (r.isIPad) return 24.0;
    return 28.0;
  }

  double _maxContentWidth(ResponsiveHelper r) {
    if (r.isMobile) return double.infinity;
    if (r.isTablet) return 560.0;
    if (r.isIPad) return 620.0;
    return 680.0;
  }
}
LOGINSCREEN

# home/widgets/home_body.dart
cat > lib/screens/home/widgets/home_body.dart << HOMEBODY
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:${PROJECT_NAME}/screens/login/providers/auth_main_provider.dart';
import 'package:${PROJECT_NAME}/theme/app_theme.dart';
import 'package:${PROJECT_NAME}/utils/responsive_helper.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _maxWidth(responsive)),
        child: Padding(
          padding: responsive.defaultPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: responsive.sp(72),
                color: AppTheme.success,
              ),
              SizedBox(height: responsive.spacingM),
              Text(
                'Start here.',
                style: TextStyle(
                  fontSize: _titleSize(responsive),
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: responsive.spacingS),
              Text(
                'Add your features using ./new_feature.sh',
                style: TextStyle(
                  fontSize: _subtitleSize(responsive),
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: responsive.spacingXL),
              SizedBox(
                width: double.infinity,
                height: responsive.buttonHeight,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.logout, size: responsive.sp(18)),
                  label: Text(
                    'Sign Out',
                    style: TextStyle(fontSize: responsive.sp(16)),
                  ),
                  onPressed: () async {
                    await context.read<AuthMainProvider>().signOut();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _titleSize(ResponsiveHelper r) {
    if (r.isMobile) return r.sp(20);
    if (r.isTablet) return r.sp(22);
    if (r.isIPad) return r.sp(23);
    return r.sp(24);
  }

  double _subtitleSize(ResponsiveHelper r) {
    if (r.isMobile) return r.sp(14);
    if (r.isTablet) return r.sp(15);
    if (r.isIPad) return r.sp(15);
    return r.sp(16);
  }

  double _maxWidth(ResponsiveHelper r) {
    if (r.isMobile) return double.infinity;
    if (r.isTablet) return 560.0;
    if (r.isIPad) return 620.0;
    return 680.0;
  }
}
HOMEBODY

# home_screen.dart
cat > lib/screens/home/home_screen.dart << HOMESCREEN
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:${PROJECT_NAME}/utils/responsive_helper.dart';
import 'package:${PROJECT_NAME}/screens/home/widgets/home_body.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Home', style: TextStyle(fontSize: responsive.sp(18))),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, size: responsive.defaultIconSize),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: const HomeBody(),
    );
  }
}
HOMESCREEN

# settings/widgets/settings_body.dart
cat > lib/screens/settings/widgets/settings_body.dart << SETTINGSBODY
import 'package:flutter/material.dart';
import 'package:${PROJECT_NAME}/theme/app_theme.dart';
import 'package:${PROJECT_NAME}/utils/responsive_helper.dart';

class SettingsBody extends StatelessWidget {
  const SettingsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _maxWidth(responsive)),
        child: Padding(
          padding: responsive.defaultPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.settings_outlined,
                size: responsive.sp(56),
                color: AppTheme.textTertiary,
              ),
              SizedBox(height: responsive.spacingM),
              Text(
                'Start this new feature.',
                style: TextStyle(
                  fontSize: _titleSize(responsive),
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _titleSize(ResponsiveHelper r) {
    if (r.isMobile) return r.sp(18);
    if (r.isTablet) return r.sp(20);
    if (r.isIPad) return r.sp(20);
    return r.sp(22);
  }

  double _maxWidth(ResponsiveHelper r) {
    if (r.isMobile) return double.infinity;
    if (r.isTablet) return 560.0;
    if (r.isIPad) return 620.0;
    return 680.0;
  }
}
SETTINGSBODY

# settings_screen.dart
cat > lib/screens/settings/settings_screen.dart << SETTINGS
import 'package:flutter/material.dart';
import 'package:${PROJECT_NAME}/utils/responsive_helper.dart';
import 'package:${PROJECT_NAME}/screens/settings/widgets/settings_body.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontSize: responsive.sp(18))),
      ),
      body: const SettingsBody(),
    );
  }
}
SETTINGS

print_success "Screens written"

# ── MAIN.DART ─────────────────────────────────────────────────
print_step "Writing main.dart"

cat > lib/main.dart << MAINDART
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/services/api_client.dart';
import 'core/services/storage_service.dart';
import 'routes/app_routes.dart';
import 'screens/login/providers/auth_main_provider.dart';
import 'screens/login/services/auth_api_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService.init();
  ApiClient.initialize();

  final apiClient = ApiClient.instance;
  final authApiService = AuthApiService(apiClient: apiClient);
  final authProvider = AuthMainProvider(authApiService: authApiService);

  await authProvider.checkAuthStatus();

  runApp(
    MultiProvider(
      providers: [
        // Auth: pre-created, passed via .value()
        ChangeNotifierProvider.value(value: authProvider),

        // Feature providers — add yours here:
        // ChangeNotifierProvider(create: (_) => YourFeatureProvider()),
      ],
      child: MyApp(authProvider: authProvider),
    ),
  );
}

class MyApp extends StatefulWidget {
  final AuthMainProvider authProvider;
  const MyApp({super.key, required this.authProvider});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(widget.authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: '$APP_TITLE',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }
}
MAINDART

print_success "main.dart written"

# ── FEATURE BOILERPLATE TEMPLATE ──────────────────────────────
print_step "Writing new_feature generator script"

cat > new_feature.sh << 'NEWFEATURE'
#!/bin/bash
# Usage: ./new_feature.sh feature_name
# Creates a complete feature scaffold inside lib/screens/

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

if [ -z "$1" ]; then
  echo -e "${RED}Usage: ./new_feature.sh <feature_name>${NC}"
  echo "  Example: ./new_feature.sh products"
  exit 1
fi

FEATURE="$1"
CLASS=$(echo "$FEATURE" | awk -F_ '{r=""; for(i=1;i<=NF;i++) r=r toupper(substr($i,1,1)) substr($i,2); print r}')
DEST="lib/screens/$FEATURE"

if [ -d "$DEST" ]; then
  echo -e "${RED}Feature '$FEATURE' already exists at $DEST${NC}"
  exit 1
fi

echo -e "${YELLOW}Creating feature: $FEATURE (class prefix: $CLASS)${NC}"

mkdir -p "$DEST/models" "$DEST/providers" "$DEST/services" "$DEST/widgets"

# --- Model ---
cat > "$DEST/models/${FEATURE}_model.dart" << EOF
class ${CLASS}Model {
  final String id;
  final String name;
  final ${CLASS}Status status;
  final DateTime createdAt;

  const ${CLASS}Model({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
  });

  factory ${CLASS}Model.fromJson(Map<String, dynamic> json) {
    return ${CLASS}Model(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: ${CLASS}Status.fromString(json['status'] as String? ?? ''),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'status': status.value,
    'createdAt': createdAt.toIso8601String(),
  };
}

enum ${CLASS}Status {
  active,
  inactive,
  unknown;

  String get value {
    switch (this) {
      case ${CLASS}Status.active: return 'active';
      case ${CLASS}Status.inactive: return 'inactive';
      case ${CLASS}Status.unknown: return 'unknown';
    }
  }

  static ${CLASS}Status fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active': return ${CLASS}Status.active;
      case 'inactive': return ${CLASS}Status.inactive;
      default: return ${CLASS}Status.unknown;
    }
  }
}
EOF

# --- Provider ---
cat > "$DEST/providers/${FEATURE}_provider.dart" << EOF
import 'package:flutter/foundation.dart';
import '../../../core/services/api_exceptions.dart';
import '../models/${FEATURE}_model.dart';
import '../services/${FEATURE}_api_service.dart';

class ${CLASS}Provider extends ChangeNotifier {
  bool _isLoading = false;
  bool _hasInitialized = false;
  String? _errorMessage;
  List<${CLASS}Model> _items = [];

  bool get isLoading => _isLoading;
  bool get hasInitialized => _hasInitialized;
  String? get errorMessage => _errorMessage;
  List<${CLASS}Model> get items => List.unmodifiable(_items);

  Future<void> initialize() async {
    _setLoading(true);
    _clearError();
    try {
      if (kDebugMode) debugPrint('[${FEATURE}_provider] initialize: fetching data');
      _items = await ${CLASS}ApiService.fetchItems();
      if (kDebugMode) debugPrint('[${FEATURE}_provider] loaded \${_items.length} items');
    } on AuthException catch (e) {
      _setError('Authentication failed: \${e.message}');
      if (kDebugMode) debugPrint('[${FEATURE}_provider] auth error: \${e.message}');
    } on NetworkException catch (e) {
      _setError('Network error. Please check your connection.');
      if (kDebugMode) debugPrint('[${FEATURE}_provider] network error: \${e.message}');
    } on ApiException catch (e) {
      _setError('Failed to load: \${e.message}');
      if (kDebugMode) debugPrint('[${FEATURE}_provider] api error: \${e.message}');
    } catch (e) {
      _setError('Unexpected error. Please try again.');
      if (kDebugMode) debugPrint('[${FEATURE}_provider] unexpected error: \$e');
    } finally {
      _hasInitialized = true;
      _setLoading(false);
    }
  }

  Future<void> refreshData() async => initialize();

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() => _errorMessage = null;
}
EOF

# --- API Service ---
cat > "$DEST/services/${FEATURE}_api_service.dart" << EOF
import 'package:flutter/foundation.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/api_exceptions.dart';
import '../../../core/services/storage_service.dart';
import '../models/${FEATURE}_model.dart';

class ${CLASS}ApiService {
  static Future<List<${CLASS}Model>> fetchItems({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      if (kDebugMode) debugPrint('[${FEATURE}_api_service] fetchItems: page=\$page');

      final token = await StorageService.getToken();
      if (token == null) throw AuthException('[${FEATURE}_api_service] No auth token');
      ApiClient.instance.setAuthToken(token);

      final response = await ApiClient.instance.get(
        '/${FEATURE}s',
        queryParameters: {'page': page, 'limit': limit},
      );

      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>)
          .map((e) => ${CLASS}Model.fromJson(e as Map<String, dynamic>))
          .toList();

      if (kDebugMode) debugPrint('[${FEATURE}_api_service] loaded \${items.length} items');
      return items;
    } on ApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('[${FEATURE}_api_service] unexpected error: \$e');
      throw ApiException('[${FEATURE}_api_service] Unexpected error fetching items');
    }
  }

  static Future<void> createItem(Map<String, dynamic> payload) async {
    try {
      if (kDebugMode) debugPrint('[${FEATURE}_api_service] createItem');
      final token = await StorageService.getToken();
      if (token == null) throw AuthException('[${FEATURE}_api_service] No auth token');
      ApiClient.instance.setAuthToken(token);
      await ApiClient.instance.post('/${FEATURE}s', data: payload);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('[${FEATURE}_api_service] Unexpected error creating item');
    }
  }
}
EOF

# --- Screen (placeholder — start here) ---
PKG=$(grep '^name:' pubspec.yaml | awk '{print $2}')
cat > "$DEST/${FEATURE}_screen.dart" << EOF
import 'package:flutter/material.dart';
import 'package:${PKG}/theme/app_theme.dart';
import 'package:${PKG}/utils/responsive_helper.dart';

class ${CLASS}Screen extends StatelessWidget {
  const ${CLASS}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${CLASS}',
          style: TextStyle(fontSize: responsive.sp(18)),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _getMaxWidth(responsive)),
          child: Padding(
            padding: responsive.defaultPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.construction_outlined,
                  size: responsive.sp(56),
                  color: AppTheme.textTertiary,
                ),
                SizedBox(height: responsive.spacingM),
                Text(
                  'Start this new feature.',
                  style: TextStyle(
                    fontSize: _getTitleSize(responsive),
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacingS),
                Text(
                  'Add your models, provider, service, and widgets.',
                  style: TextStyle(
                    fontSize: _getSubtitleSize(responsive),
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _getTitleSize(ResponsiveHelper responsive) {
    if (responsive.isMobile) return responsive.sp(18);
    if (responsive.isTablet) return responsive.sp(20);
    if (responsive.isIPad) return responsive.sp(20);
    return responsive.sp(22);
  }

  double _getSubtitleSize(ResponsiveHelper responsive) {
    if (responsive.isMobile) return responsive.sp(13);
    if (responsive.isTablet) return responsive.sp(14);
    if (responsive.isIPad) return responsive.sp(14);
    return responsive.sp(15);
  }

  double _getMaxWidth(ResponsiveHelper responsive) {
    if (responsive.isMobile) return double.infinity;
    if (responsive.isTablet) return 560.0;
    if (responsive.isIPad) return 620.0;
    return 680.0;
  }
}
EOF


chmod +x "$0"

# Convert relative imports to package: imports for the new feature files
PKG=$(grep '^name:' pubspec.yaml | awk '{print $2}')
if command -v python3 &>/dev/null && [ -n "$PKG" ]; then
  python3 - "$PKG" "$DEST" << 'PYEOF'
import re, os, sys
pkg, feature_dir = sys.argv[1], sys.argv[2]
lib_dir = os.path.abspath('lib')
for root, _, files in os.walk(feature_dir):
    for fname in files:
        if not fname.endswith('.dart'): continue
        fpath = os.path.join(root, fname)
        with open(fpath) as f: content = f.read()
        def fix(m, fpath=fpath):
            rel = m.group(1)
            if rel.startswith('package:') or rel.startswith('dart:'):
                return m.group(0)
            abs_path = os.path.normpath(os.path.join(os.path.dirname(fpath), rel))
            lib_rel = os.path.relpath(abs_path, lib_dir)
            return f"import 'package:{pkg}/{lib_rel}'"
        result = re.sub(r"import '([^']+\.dart)'", fix, content)
        if result != content:
            with open(fpath, 'w') as f: f.write(result)
PYEOF
fi

echo -e "\n${GREEN}✔ Feature '$FEATURE' created at $DEST${NC}"
echo -e "${YELLOW}  Next steps:${NC}"
echo "  1. Register in main.dart:    ChangeNotifierProvider(create: (_) => ${CLASS}Provider())"
echo "  2. Add route in app_routes.dart:  GoRoute(path: '/${FEATURE}', builder: (_, __) => const ${CLASS}Screen())"
echo ""
NEWFEATURE

chmod +x new_feature.sh
print_success "new_feature.sh generator written"

# ── CONVERT RELATIVE IMPORTS → PACKAGE IMPORTS ───────────────
print_step "Converting to package: imports"
python3 - "$PROJECT_NAME" lib << 'PYEOF'
import re, os, sys
pkg, lib_dir = sys.argv[1], os.path.abspath(sys.argv[2])
for root, _, files in os.walk(lib_dir):
    for fname in files:
        if not fname.endswith('.dart'): continue
        fpath = os.path.join(root, fname)
        with open(fpath) as f: content = f.read()
        def fix(m, fpath=fpath):
            rel = m.group(1)
            # Skip already-resolved imports
            if rel.startswith('package:') or rel.startswith('dart:'):
                return m.group(0)
            abs_path = os.path.normpath(os.path.join(os.path.dirname(fpath), rel))
            lib_rel = os.path.relpath(abs_path, lib_dir)
            return f"import 'package:{pkg}/{lib_rel}'"
        # Match ALL .dart imports (bare, ./, ../ — anything not already package:/dart:)
        result = re.sub(r"import '([^']+\.dart)'", fix, content)
        if result != content:
            with open(fpath, 'w') as f: f.write(result)
            print(f'  \u2714 {os.path.relpath(fpath, lib_dir)}')
PYEOF
print_success "Package imports applied"

# ── INSTALL DEPENDENCIES ──────────────────────────────────────
print_step "Installing dependencies (flutter pub get)"
flutter pub get
if [ $? -ne 0 ]; then
  print_warn "flutter pub get had issues. Check pubspec.yaml and retry manually."
else
  print_success "Dependencies installed"
fi

# ── FLUTTER ANALYZE ───────────────────────────────────────────
print_step "Running flutter analyze"
flutter analyze --no-pub 2>&1
ANALYZE_EXIT=$?
if [ $ANALYZE_EXIT -eq 0 ]; then
  print_success "flutter analyze: No issues!"
else
  print_warn "flutter analyze found issues. Review above and fix before coding."
fi

# ── DONE ──────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════╗"
echo "║              Setup Complete! 🎉                  ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "  ${CYAN}Project:${NC}      $PROJECT_NAME/"
echo -e "  ${CYAN}API URL:${NC}      $BASE_URL"
echo ""
echo -e "  ${BOLD}What's ready:${NC}"
echo "  ✔ Full clean architecture folder structure"
echo "  ✔ ApiClient (Dio singleton)"
echo "  ✔ StorageService (secure + SharedPrefs)"
echo "  ✔ AppTheme + ResponsiveHelper"
echo "  ✔ GoRouter + AuthRouteNotifier"
echo "  ✔ AuthMainProvider + signIn/signOut/checkAuthStatus"
echo "  ✔ Splash → Login → Home flow"
echo "  ✔ main.dart wired up"
echo ""
echo -e "  ${BOLD}Next steps:${NC}"
echo "  1. Update lib/core/global_variables/global_variables.dart (apiKey)"
echo "  2. Update lib/screens/login/services/auth_api_service.dart (your endpoint)"
echo "  3. Run: ./new_feature.sh <name>   to scaffold any new feature"
echo "  4. Run: flutter run"
echo ""
