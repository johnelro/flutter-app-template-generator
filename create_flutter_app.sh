#!/bin/bash

# ============================================================
#  Flutter Clean Architecture Template Generator
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
  echo "║       Flutter Clean Template Generator           ║"
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

# ── Home screen layout choice ────────────────────────────────
echo -e "\n  ${BOLD}Home screen layout:${NC}"
echo "    1) Plain screen  — simple AppBar + body (current default)"
echo "    2) Bottom nav    — main shell with floating nav bar + multiple tab screens"
echo -en "  Choose [1/2] (default: 1): "
read LAYOUT_CHOICE
LAYOUT_CHOICE="${LAYOUT_CHOICE:-1}"

HOME_LAYOUT="plain"
TAB_COUNT=0
if [[ "$LAYOUT_CHOICE" == "2" ]]; then
  HOME_LAYOUT="tabnav"
  while true; do
    echo -en "  ${BOLD}Number of tab screens${NC} (2–5): "
    read TAB_COUNT_INPUT
    if [[ "$TAB_COUNT_INPUT" =~ ^[2-5]$ ]]; then
      TAB_COUNT=$TAB_COUNT_INPUT
      break
    fi
    print_error "Please enter a number between 2 and 5."
  done
  echo -e "  ${CYAN}Layout:${NC}  Bottom nav with $TAB_COUNT tab screens"
else
  echo -e "  ${CYAN}Layout:${NC}  Plain home screen"
fi

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

# ── Android permissions ───────────────────────────────────────
print_step "Patching Android permissions"
ANDROID_MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$ANDROID_MANIFEST" ]; then
  python3 - "$ANDROID_MANIFEST" << 'PYEOF'
import re, sys
path = sys.argv[1]
with open(path) as f: content = f.read()
permissions = [
    '<uses-permission android:name="android.permission.INTERNET"/>',
    '<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>',
    '<uses-permission android:name="android.permission.CAMERA"/>',
    '<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>',
    '<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>',
]
block = '\n'.join(f'    {p}' for p in permissions) + '\n'
# Insert just before <application
if '<uses-permission' not in content:
    content = content.replace('<application', block + '<application', 1)
    with open(path, 'w') as f: f.write(content)
    print('  ✔ Permissions added to AndroidManifest.xml')
else:
    print('  ✔ Permissions already present in AndroidManifest.xml')
PYEOF
  print_success "Android manifest patched"
else
  print_warn "AndroidManifest.xml not found — skipping (expected for --empty create)"
fi

# ── iOS Info.plist usage descriptions ─────────────────────────
print_step "Patching iOS Info.plist"
IOS_PLIST="ios/Runner/Info.plist"
if [ -f "$IOS_PLIST" ]; then
  python3 - "$IOS_PLIST" << 'PYEOF'
import sys, re
path = sys.argv[1]
with open(path) as f: content = f.read()
entries = {
    'NSCameraUsageDescription': 'This app needs camera access to take photos.',
    'NSPhotoLibraryUsageDescription': 'This app needs photo library access to select images.',
    'NSPhotoLibraryAddUsageDescription': 'This app needs permission to save photos to your library.',
    'NSMicrophoneUsageDescription': 'This app needs microphone access for video recording.',
}
added = []
for key, val in entries.items():
    if key not in content:
        inject = f'\t<key>{key}</key>\n\t<string>{val}</string>'
        content = re.sub(r'(<dict>)', r'\1\n' + inject, content, count=1)
        added.append(key)
with open(path, 'w') as f: f.write(content)
if added:
    print('  ✔ Added: ' + ', '.join(added))
else:
    print('  ✔ All Info.plist keys already present')
PYEOF
  print_success "iOS Info.plist patched"
else
  print_warn "Info.plist not found — skipping"
fi

# ── macOS entitlements (network sandbox) ──────────────────────
print_step "Patching macOS entitlements"
for ENTITLEMENTS in \
  "macos/Runner/DebugProfile.entitlements" \
  "macos/Runner/Release.entitlements"; do
  if [ -f "$ENTITLEMENTS" ]; then
    python3 - "$ENTITLEMENTS" << 'PYEOF'
import sys, re
path = sys.argv[1]
with open(path) as f: content = f.read()
entries = {
    'com.apple.security.network.client': '<true/>',
    'com.apple.security.network.server': '<true/>',
}
added = []
for key, val in entries.items():
    if key not in content:
        inject = f'\t<key>{key}</key>\n\t{val}'
        content = re.sub(r'(<dict>)', r'\1\n' + inject, content, count=1)
        added.append(key)
with open(path, 'w') as f: f.write(content)
label = path.split('/')[-1]
if added:
    print(f'  ✔ {label}: added {", ".join(added)}')
else:
    print(f'  ✔ {label}: network keys already present')
PYEOF
  else
    print_warn "$ENTITLEMENTS not found — skipping (not a macOS project or not yet created)"
  fi
done
print_success "macOS entitlements patched"

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
  "assets/fonts"
)

for d in "${dirs[@]}"; do
  mkdir -p "$d"
done

# Extra folders for bottom-nav tab layout
if [[ "$HOME_LAYOUT" == "tabnav" ]]; then
  mkdir -p "lib/screens/home/widgets"
  for i in $(seq 1 "$TAB_COUNT"); do
    mkdir -p "lib/screens/home/screens/screen${i}/models"
    mkdir -p "lib/screens/home/screens/screen${i}/providers"
    mkdir -p "lib/screens/home/screens/screen${i}/services"
    mkdir -p "lib/screens/home/screens/screen${i}/widgets"
  done
fi
print_success "Directories created"

# ── pubspec.yaml ─────────────────────────────────────────────
print_step "Writing pubspec.yaml"

cat > pubspec.yaml << PUBSPEC
name: $PROJECT_NAME
description: "$APP_TITLE — Flutter Clean Architecture"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.11.5 <4.0.0'

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

  # Serialization
  json_annotation: ^4.12.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  flutter_launcher_icons: ^0.14.4

  # Code generation
  build_runner: ^2.4.14
  json_serializable: ^6.8.0
  flutter_gen_runner: ^5.9.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/image_icons/

# ── App icon generation (flutter_launcher_icons) ─────────────────
flutter_icons:
  android: true
  ios: true
  image_path: "assets/images/app_icon.png"
  min_sdk_android: 21
  web:
    generate: false

# ── Asset code generation (flutter_gen) ───────────────────────────
flutter_gen:
  output: lib/gen/
  line_length: 120
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

# ── CONNECTIVITY SERVICE ──────────────────────────────────────
print_step "Writing ConnectivityService + OfflineBanner"

cat > lib/core/services/connectivity_service.dart << 'CONNECTIVITY'
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._();
  static ConnectivityService get instance => _instance;

  ConnectivityService._();

  bool _isOnline = true;
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> init() async {
    final results = await Connectivity().checkConnectivity();
    _isOnline = _evaluate(results);
    if (kDebugMode) debugPrint('[connectivity_service] initial: $_isOnline');

    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final online = _evaluate(results);
      if (online != _isOnline) {
        _isOnline = online;
        if (kDebugMode) debugPrint('[connectivity_service] changed: $_isOnline');
        notifyListeners();
      }
    });
  }

  bool _evaluate(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
CONNECTIVITY

cat > lib/core/widgets/offline_banner.dart << 'OFFLINEBANNER'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';

/// Wraps [child] and shows a dismissible offline banner at the top
/// whenever [ConnectivityService.isOffline] is true.
///
/// Usage in MaterialApp.router → builder:
/// ```dart
/// builder: (context, child) => OfflineBanner(child: child ?? const SizedBox()),
/// ```
class OfflineBanner extends StatelessWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: connectivity.isOffline ? null : 0,
              child: connectivity.isOffline
                  ? Material(
                      color: Colors.transparent,
                      child: Container(
                        width: double.infinity,
                        color: const Color(0xFFD92D20),
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 16,
                        ),
                        child: const SafeArea(
                          bottom: false,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_off_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'No internet connection',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
OFFLINEBANNER

print_success "ConnectivityService + OfflineBanner written"

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
  static const double _mobileMax  = 600;
  static const double _desktopMin = 1200;

  // ── Device detection ─────────────────────────────────────────
  bool get isSmallMobile => _screenWidth < 350;
  bool get isMobile      => _screenWidth < _mobileMax;

  /// True for any iPad — including large models like the 13-inch iPad M3
  /// whose shortestSide is ~1024 px (larger than the old 900-cap).
  /// Detection rule: physical device (non-web), shortestSide ≥ 600 px,
  /// and screen is NOT in true desktop territory (width < desktopMin).
  bool get isIPad {
    // On Flutter Web every platform reports the browser viewport, not a
    // physical device — skip the iPad heuristic there.
    if (_isWeb) return false;
    final shortest = _mediaQuery.size.shortestSide;
    // ≥ 600 covers all iPads (mini → 13-inch Pro/M3).
    // < _desktopMin keeps a MacBook/external-monitor from matching.
    return shortest >= 600 && _screenWidth < _desktopMin;
  }

  /// Generic Android/Windows tablet: landscape width in [600, 1200),
  /// but NOT an iPad.
  bool get isTablet =>
      _screenWidth >= _mobileMax &&
      _screenWidth < _desktopMin &&
      !isIPad;

  bool get isDesktop    => _screenWidth >= _desktopMin;
  bool get isAnyTablet  => isIPad || isTablet;

  /// True when running on Flutter Web (used to skip native device heuristics).
  bool get _isWeb {
    // identical(0, 0.0) is false on the VM, true on dart2js/DDC (web).
    // ignore: unnecessary_type_check
    return identical(0, 0.0);
  }

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
    if (isMobile)      return 1.0;
    if (isTablet)      return 1.1;
    if (isIPad)        return 1.15;
    // Desktop / web browser: keep sizes close to mobile baseline so text
    // doesn't balloon on wide viewports. 1.05 gives a subtle size bump
    // without the oversized look of the old 1.3 factor.
    return 1.05;
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
    if (isMobile) return EdgeInsets.symmetric(horizontal: wp(4),  vertical: hp(2));
    if (isTablet) return EdgeInsets.symmetric(horizontal: wp(5),  vertical: hp(2.5));
    if (isIPad)   return EdgeInsets.symmetric(horizontal: wp(4),  vertical: hp(2.5));
    // Desktop/web: use a fixed max rather than a % so wide screens don't
    // get enormous gutters. Content is also constrained by maxFormWidth.
    return const EdgeInsets.symmetric(horizontal: 24, vertical: 24);
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
    if (isMobile) return 48.0;
    if (isTablet) return 52.0;
    return 56.0;
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
    if (isMobile)  return sp(24);
    if (isTablet)  return sp(24);
    if (isIPad)    return sp(26);
    return sp(24); // desktop/web — same as mobile baseline, scale factor handles the rest
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

# ── USER MODEL ────────────────────────────────────────────────
cat > lib/screens/login/models/user_model.dart << 'USERMODEL'
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  // Convenience helpers used by AuthMainProvider
  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  String get displayName => name.isNotEmpty ? name : email;
}
USERMODEL

print_success "UserModel written (lib/screens/login/models/user_model.dart)"

cat > lib/screens/login/providers/auth_main_provider.dart << 'AUTHPROVIDER'
import 'package:flutter/foundation.dart';
import '../../../core/services/api_exceptions.dart';
import '../../../core/services/storage_service.dart';
import '../models/user_model.dart';
import '../services/auth_api_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthMainProvider extends ChangeNotifier {
  final AuthApiService authApiService;

  AuthMainProvider({required this.authApiService});

  // --- State ---
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  UserModel? _currentUser;

  // --- Getters ---
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  String? get userEmail => _currentUser?.email;
  String get userRole => _currentUser?.role ?? '';
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // ── Check stored session on startup ──────────────────────
  Future<void> checkAuthStatus() async {
    if (kDebugMode) debugPrint('[auth_main_provider] checkAuthStatus: checking');
    _setStatus(AuthStatus.loading);
    try {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        final userData = await StorageService.getUser();
        if (userData != null) {
          _currentUser = UserModel.fromJson(userData);
        }
        _setStatus(AuthStatus.authenticated);
        if (kDebugMode) {
          debugPrint('[auth_main_provider] checkAuthStatus: authenticated as ${_currentUser?.email}');
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

      final userJson = result['user'] as Map<String, dynamic>;
      await StorageService.saveUser(userJson);
      _currentUser = UserModel.fromJson(userJson);
      await StorageService.saveEmail(email);

      _setStatus(AuthStatus.authenticated);
      if (kDebugMode) {
        debugPrint('[auth_main_provider] signIn: success, role=${_currentUser?.role}');
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

  // ── Register ───────────────────────────────────────────────
  Future<bool> register({required String name, required String email, required String password}) async {
    _setStatus(AuthStatus.loading);
    _clearError();
    try {
      if (kDebugMode) debugPrint('[auth_main_provider] register: $email');
      final result = await authApiService.register(name: name, email: email, password: password);

      await StorageService.saveToken(result['token'] as String);

      final userJson = result['user'] as Map<String, dynamic>;
      await StorageService.saveUser(userJson);
      _currentUser = UserModel.fromJson(userJson);
      await StorageService.saveEmail(email);

      _setStatus(AuthStatus.authenticated);
      if (kDebugMode) {
        debugPrint('[auth_main_provider] register: success, role=${_currentUser?.role}');
      }
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setStatus(AuthStatus.unauthenticated);
      if (kDebugMode) debugPrint('[auth_main_provider] register auth error: ${e.message}');
      return false;
    } on NetworkException catch (e) {
      _setError('Network error. Please check your connection.');
      _setStatus(AuthStatus.unauthenticated);
      if (kDebugMode) debugPrint('[auth_main_provider] register network error: ${e.message}');
      return false;
    } on ApiException catch (e) {
      _setError(e.message);
      _setStatus(AuthStatus.unauthenticated);
      if (kDebugMode) debugPrint('[auth_main_provider] register api error: ${e.message}');
      return false;
    } catch (e) {
      _setError('Unexpected error. Please try again.');
      _setStatus(AuthStatus.unauthenticated);
      if (kDebugMode) debugPrint('[auth_main_provider] register unexpected error: $e');
      return false;
    }
  }

  // ── Sign out ──────────────────────────────────────────────
  Future<void> signOut() async {
    if (kDebugMode) debugPrint('[auth_main_provider] signOut');
    await StorageService.clear();
    _currentUser = null;
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

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) debugPrint('[auth_api_service] register: $email');

      final response = await apiClient.post(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      if (kDebugMode) debugPrint('[auth_api_service] register: success');
      return data;
    } on ApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('[auth_api_service] register unexpected error: $e');
      throw ApiException('[auth_api_service] Unexpected error during registration');
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

if [[ "$HOME_LAYOUT" == "tabnav" ]]; then
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
        // MainScreen is the tab-nav shell, exported as home_screen.dart
        path: '/home',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
APPROUTES
else
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
fi

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
  final String title;
  final String subtitle;

  const LoginHeader({
    super.key,
    this.title = 'Welcome back',
    this.subtitle = 'Sign in to continue',
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.bolt_rounded,
            size: responsive.sp(40),
            color: AppTheme.primary,
          ),
        ),
        SizedBox(height: responsive.spacingM),
        Text(
          title,
          style: AppTheme.headlineMedium.copyWith(
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        SizedBox(height: responsive.spacingXS),
        Text(
          subtitle,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          height: responsive.formElementHeight,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(fontSize: responsive.sp(14)),
            decoration: InputDecoration(
              labelText: 'Email',
              contentPadding: responsive.inputContentPadding,
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
          ),
        ),
        SizedBox(height: responsive.spacingM),
        SizedBox(
          width: double.infinity,
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
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

# login/widgets/auth_transition.dart
cat > lib/screens/login/widgets/auth_transition.dart << AUTHTRANSITION
import 'package:flutter/material.dart';

class AuthTransition extends StatelessWidget {
  final AnimationController controller;
  final bool isLoginMode;
  final Widget child;

  const AuthTransition({
    super.key,
    required this.controller,
    required this.isLoginMode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final curve = CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOutCubic,
        );

        return FadeTransition(
          opacity: isLoginMode
              ? Tween<double>(begin: 1.0, end: 0.0).animate(curve)
              : Tween<double>(begin: 0.0, end: 1.0).animate(curve),
          child: SlideTransition(
            position: isLoginMode
                ? Tween<Offset>(
                    begin: Offset.zero,
                    end: const Offset(-0.02, 0),
                  ).animate(curve)
                : Tween<Offset>(
                    begin: const Offset(0.02, 0),
                    end: Offset.zero,
                  ).animate(curve),
            child: child,
          ),
        );
      },
    );
  }
}
AUTHTRANSITION

# login/widgets/register_form.dart
cat > lib/screens/login/widgets/register_form.dart << REGISTERFORM
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:${PROJECT_NAME}/screens/login/providers/auth_main_provider.dart';
import 'package:${PROJECT_NAME}/theme/app_theme.dart';
import 'package:${PROJECT_NAME}/utils/responsive_helper.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    final provider = context.read<AuthMainProvider>();
    final success = await provider.register(name: name, email: email, password: password);
    if (success && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          height: responsive.formElementHeight,
          child: TextFormField(
            controller: _nameController,
            style: TextStyle(fontSize: responsive.sp(14)),
            decoration: InputDecoration(
              labelText: 'Full Name',
              contentPadding: responsive.inputContentPadding,
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
          ),
        ),
        SizedBox(height: responsive.spacingM),
        SizedBox(
          width: double.infinity,
          height: responsive.formElementHeight,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(fontSize: responsive.sp(14)),
            decoration: InputDecoration(
              labelText: 'Email',
              contentPadding: responsive.inputContentPadding,
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
          ),
        ),
        SizedBox(height: responsive.spacingM),
        SizedBox(
          width: double.infinity,
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
          ),
        ),
        SizedBox(height: responsive.spacingM),
        SizedBox(
          width: double.infinity,
          height: responsive.formElementHeight,
          child: TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscurePassword,
            style: TextStyle(fontSize: responsive.sp(14)),
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              contentPadding: responsive.inputContentPadding,
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
          ),
        ),
        SizedBox(height: responsive.spacingL),
        _RegisterButton(onPressed: _onRegister),
      ],
    );
  }
}

class _RegisterButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _RegisterButton({required this.onPressed});

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
                    'Create Account',
                    style: TextStyle(fontSize: responsive.sp(16)),
                  ),
          ),
        );
      },
    );
  }
}
REGISTERFORM

# login/widgets/login_branding_side.dart
cat > lib/screens/login/widgets/login_branding_side.dart << BRANDINGSIDE
import 'package:flutter/material.dart';
import 'package:${PROJECT_NAME}/theme/app_theme.dart';
import 'package:${PROJECT_NAME}/utils/responsive_helper.dart';

class LoginBrandingSide extends StatelessWidget {
  final bool isLoginMode;
  const LoginBrandingSide({super.key, required this.isLoginMode});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Container(
      color: AppTheme.primary,
      width: double.infinity,
      child: Padding(
        padding: responsive.defaultPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.bolt_rounded,
                size: responsive.sp(80), color: Colors.white),
            SizedBox(height: responsive.spacingL),
            Text(
              'You app name here',
              style: AppTheme.headlineLarge.copyWith(color: Colors.white),
            ),
            SizedBox(height: responsive.spacingS),
            Text(
              isLoginMode
                  ? 'The fastest way to manage your workflow.'
                  : 'Join thousands of professionals today.',
              style: AppTheme.bodyLarge
                  .copyWith(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
BRANDINGSIDE

# login/widgets/login_auth_side.dart
cat > lib/screens/login/widgets/login_auth_side.dart << AUTHSIDE
import 'package:flutter/material.dart';
import 'package:${PROJECT_NAME}/theme/app_theme.dart';
import 'package:${PROJECT_NAME}/utils/responsive_helper.dart';
import 'package:${PROJECT_NAME}/screens/login/widgets/login_header.dart';
import 'package:${PROJECT_NAME}/screens/login/widgets/login_form.dart';
import 'package:${PROJECT_NAME}/screens/login/widgets/register_form.dart';
import 'package:${PROJECT_NAME}/screens/login/widgets/login_error.dart';
import 'package:${PROJECT_NAME}/screens/login/widgets/auth_transition.dart';

class LoginAuthSide extends StatelessWidget {
  final bool isLoginMode;
  final AnimationController animationController;
  final VoidCallback onToggleMode;
  final ResponsiveHelper responsive;

  const LoginAuthSide({
    super.key,
    required this.isLoginMode,
    required this.animationController,
    required this.onToggleMode,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.background,
            AppTheme.grey100,
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: responsive.maxFormWidth,
          ),
          child: SingleChildScrollView(
            padding: responsive.defaultPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LoginHeader(
                  title: isLoginMode ? 'Welcome back' : 'Create account',
                  subtitle: isLoginMode
                      ? 'Sign in to continue'
                      : 'Join us to get started',
                ),
                SizedBox(height: responsive.spacingXL),
                AuthTransition(
                  controller: animationController,
                  isLoginMode: isLoginMode,
                  child: isLoginMode
                      ? const LoginForm(key: ValueKey('login'))
                      : const RegisterForm(key: ValueKey('register')),
                ),
                SizedBox(height: responsive.spacingM),
                Center(
                  child: TextButton(
                    onPressed: onToggleMode,
                    child: Text(
                      isLoginMode
                          ? "Don't have an account? Register"
                          : "Already have an account? Login",
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacingM),
                const LoginError(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
AUTHSIDE

# login_screen.dart
cat > lib/screens/login/login_screen.dart << LOGINSCREEN
import 'package:flutter/material.dart';
import 'package:${PROJECT_NAME}/theme/app_theme.dart';
import 'package:${PROJECT_NAME}/utils/responsive_helper.dart';
import 'package:${PROJECT_NAME}/screens/login/widgets/login_branding_side.dart';
import 'package:${PROJECT_NAME}/screens/login/widgets/login_auth_side.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoginMode = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
    if (_isLoginMode) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    // Split screen only makes sense when there is enough horizontal room.
    // Below 900px, we use a single-column layout to avoid squishing either side.
    final isWideScreen = responsive.screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Row(
          children: [
            if (isWideScreen)
              Expanded(
                flex: _getBrandingFlex(responsive),
                child: LoginBrandingSide(isLoginMode: _isLoginMode),
              ),
            Expanded(
              flex: isWideScreen ? _getAuthFlex(responsive) : 10,
              child: LoginAuthSide(
                isLoginMode: _isLoginMode,
                animationController: _animationController,
                onToggleMode: _toggleMode,
                responsive: responsive,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getBrandingFlex(ResponsiveHelper r) {
    if (r.screenWidth < 1200) return 5;
    return 6;
  }

  int _getAuthFlex(ResponsiveHelper r) {
    if (r.screenWidth < 1200) return 5;
    return 4;
  }
}
LOGINSCREEN

# ── HOME SCREEN(S) — conditional on layout choice ─────────────
if [[ "$HOME_LAYOUT" == "plain" ]]; then

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

else
# ── BOTTOM NAV LAYOUT ─────────────────────────────────────────

# Build tab screen names array (screen1, screen2, ...)
TAB_NAMES=()
TAB_CLASSES=()
for i in $(seq 1 "$TAB_COUNT"); do
  TAB_NAMES+=("screen${i}")
  TAB_CLASSES+=("Screen${i}")
done

# 1) floating_nav_bar.dart widget
#    Key design rules matching the reference project:
#    - Outer container: dark pill (grey900), shadow, shrink-wraps via mainAxisSize.min + Center
#    - Unselected: icon only, grey400 colour
#    - Selected: icon + label, white text/icon, AppTheme.primary pill highlight
#    - Container does NOT stretch full width — it hugs content
cat > lib/screens/home/widgets/floating_nav_bar.dart << FLOATNAV
import 'package:flutter/material.dart';
import 'package:${PROJECT_NAME}/theme/app_theme.dart';
import 'package:${PROJECT_NAME}/utils/responsive_helper.dart';

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final ResponsiveHelper responsive;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    // Center + intrinsicWidth so the pill hugs its content regardless of
    // how wide the Positioned left/right anchor is.
    return Center(
      child: IntrinsicWidth(
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.grey900,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: _getOuterPaddingH(responsive),
            vertical: _getOuterPaddingV(responsive),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_tabs.length, (index) {
              final selected = index == currentIndex;
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _getTabGap(responsive),
                ),
                child: GestureDetector(
                  onTap: () => onTabChanged(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(
                      horizontal: selected
                          ? _getSelectedPaddingH(responsive)
                          : _getUnselectedPaddingH(responsive),
                      vertical: _getPillPaddingV(responsive),
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected
                              ? _tabs[index].activeIcon
                              : _tabs[index].icon,
                          size: _getIconSize(responsive),
                          color: selected
                              ? Colors.white
                              : AppTheme.grey400,
                        ),
                        if (selected) ...[
                          SizedBox(width: _getLabelGap(responsive)),
                          Text(
                            _tabs[index].label,
                            style: TextStyle(
                              fontSize: _getLabelSize(responsive),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── Tab definitions ────────────────────────────────────────
  static const _tabs = [
FLOATNAV

# Append tab entries with filled/outlined icon pairs
for i in $(seq 1 "$TAB_COUNT"); do
  case $i in
    1) ICON="Icons.home_outlined"          ACTIVE="Icons.home_rounded"               LABEL="Screen 1" ;;
    2) ICON="Icons.search_outlined"        ACTIVE="Icons.search_rounded"             LABEL="Screen 2" ;;
    3) ICON="Icons.add_circle_outline"     ACTIVE="Icons.add_circle"                 LABEL="Screen 3" ;;
    4) ICON="Icons.notifications_outlined" ACTIVE="Icons.notifications_rounded"      LABEL="Screen 4" ;;
    5) ICON="Icons.person_outline"         ACTIVE="Icons.person_rounded"             LABEL="Screen 5" ;;
  esac
cat >> lib/screens/home/widgets/floating_nav_bar.dart << TABENTRY
    _NavTab(icon: $ICON, activeIcon: $ACTIVE, label: '$LABEL'),
TABENTRY
done

cat >> lib/screens/home/widgets/floating_nav_bar.dart << FLOATNAV2
  ];

  // ── Responsive sizing ──────────────────────────────────────

  /// Outer container horizontal padding (left/right of the whole pill group)
  double _getOuterPaddingH(ResponsiveHelper r) {
    if (r.isMobile) return 6.0;
    if (r.isTablet) return 8.0;
    if (r.isIPad) return 10.0;
    return 12.0;
  }

  /// Outer container vertical padding (top/bottom of the whole pill group)
  double _getOuterPaddingV(ResponsiveHelper r) {
    if (r.isMobile) return 6.0;
    if (r.isTablet) return 7.0;
    if (r.isIPad) return 8.0;
    return 9.0;
  }

  /// Horizontal gap between each tab item
  double _getTabGap(ResponsiveHelper r) {
    if (r.isMobile) return 2.0;
    if (r.isTablet) return 3.0;
    if (r.isIPad) return 4.0;
    return 4.0;
  }

  /// Horizontal padding inside the selected (icon + label) pill
  double _getSelectedPaddingH(ResponsiveHelper r) {
    if (r.isMobile) return 16.0;
    if (r.isTablet) return 18.0;
    if (r.isIPad) return 20.0;
    return 22.0;
  }

  /// Horizontal padding around the unselected icon
  double _getUnselectedPaddingH(ResponsiveHelper r) {
    if (r.isMobile) return 12.0;
    if (r.isTablet) return 13.0;
    if (r.isIPad) return 14.0;
    return 15.0;
  }

  /// Vertical padding inside each tab pill (selected and unselected)
  double _getPillPaddingV(ResponsiveHelper r) {
    if (r.isMobile) return 10.0;
    if (r.isTablet) return 11.0;
    if (r.isIPad) return 12.0;
    return 13.0;
  }

  double _getIconSize(ResponsiveHelper r) {
    if (r.isMobile) return r.sp(22);
    if (r.isTablet) return r.sp(23);
    if (r.isIPad) return r.sp(24);
    return r.sp(25);
  }

  /// Gap between icon and label inside selected tab
  double _getLabelGap(ResponsiveHelper r) {
    if (r.isMobile) return 7.0;
    if (r.isTablet) return 8.0;
    if (r.isIPad) return 9.0;
    return 10.0;
  }

  double _getLabelSize(ResponsiveHelper r) {
    if (r.isMobile) return r.sp(13);
    if (r.isTablet) return r.sp(14);
    if (r.isIPad) return r.sp(14);
    return r.sp(15);
  }
}

class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
FLOATNAV2

# 2) Generate each tab screen file
for i in $(seq 1 "$TAB_COUNT"); do
  SNAME="screen${i}"
  SCLASS="Screen${i}Screen"

cat > "lib/screens/home/screens/${SNAME}/${SNAME}_screen.dart" << TABSCREEN
import 'package:flutter/material.dart';
import 'package:${PROJECT_NAME}/theme/app_theme.dart';
import 'package:${PROJECT_NAME}/utils/responsive_helper.dart';

/// Screen $i tab content — rendered inside MainScreen.
/// Add your models, providers, services, and widgets here.
class $SCLASS extends StatelessWidget {
  const $SCLASS({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Center(
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
                'Screen $i',
                style: TextStyle(
                  fontSize: _getTitleSize(responsive),
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: responsive.spacingS),
              Text(
                'Build your feature here.',
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
    );
  }

  double _getTitleSize(ResponsiveHelper r) {
    if (r.isMobile) return r.sp(18);
    if (r.isTablet) return r.sp(20);
    if (r.isIPad) return r.sp(20);
    return r.sp(22);
  }

  double _getSubtitleSize(ResponsiveHelper r) {
    if (r.isMobile) return r.sp(13);
    if (r.isTablet) return r.sp(14);
    if (r.isIPad) return r.sp(14);
    return r.sp(15);
  }

  double _getMaxWidth(ResponsiveHelper r) {
    if (r.isMobile) return double.infinity;
    if (r.isTablet) return 560.0;
    if (r.isIPad) return 620.0;
    return 680.0;
  }
}
TABSCREEN

done

# 3) Build the _buildCurrentScreen switch cases and imports dynamically
SWITCH_CASES=""
TAB_IMPORTS=""
for i in $(seq 1 "$TAB_COUNT"); do
  SNAME="screen${i}"
  SCLASS="Screen${i}Screen"
  TAB_IMPORTS+="import 'package:${PROJECT_NAME}/screens/home/screens/${SNAME}/${SNAME}_screen.dart';\n"
  SWITCH_CASES+="      case $((i-1)):\n        return const $SCLASS();\n"
done

# 4) header.dart widget — app title left, settings icon right
#    Mirrors the reference project's widgets/header.dart exactly.
cat > lib/screens/home/widgets/header.dart << HEADERWIDGET
import 'package:flutter/material.dart';
import 'package:${PROJECT_NAME}/theme/app_theme.dart';
import 'package:${PROJECT_NAME}/utils/responsive_helper.dart';

/// Shared header shown across all tabs in MainScreen.
/// Title is left-aligned; settings icon is right-aligned.
/// The header intentionally fills its parent width — do NOT wrap
/// it in Center/ConstrainedBox at the call-site; horizontal padding
/// is handled by the parent Padding widget in home_screen.dart.
class Header extends StatelessWidget {
  final ResponsiveHelper responsive;
  final VoidCallback onSettingsTap;

  const Header({
    super.key,
    required this.responsive,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$APP_TITLE',
          style: TextStyle(
            fontSize: _getTitleSize(responsive),
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.settings_outlined,
            size: _getIconSize(responsive),
            color: AppTheme.textPrimary,
          ),
          onPressed: onSettingsTap,
        ),
      ],
    );
  }

  double _getTitleSize(ResponsiveHelper r) {
    if (r.isMobile) return r.sp(22);
    if (r.isTablet) return r.sp(22);
    if (r.isIPad)   return r.sp(23);
    // Desktop / web: don't inflate beyond a comfortable reading size
    return r.sp(22);
  }

  double _getIconSize(ResponsiveHelper r) {
    if (r.isMobile) return r.sp(22);
    if (r.isTablet) return r.sp(22);
    if (r.isIPad)   return r.sp(23);
    return r.sp(22);
  }
}
HEADERWIDGET

# 5) home_screen.dart — MainScreen shell, structure mirrors reference main_screen.dart
#    Uses Header widget, same Padding/Center/ConstrainedBox/Column structure,
#    same responsive values as the reference file.
cat > lib/screens/home/home_screen.dart << MAINSCREEN
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:${PROJECT_NAME}/utils/responsive_helper.dart';
import 'package:${PROJECT_NAME}/screens/home/widgets/header.dart';
import 'package:${PROJECT_NAME}/screens/home/widgets/floating_nav_bar.dart';
MAINSCREEN

# Append per-tab screen imports
for i in $(seq 1 "$TAB_COUNT"); do
  SNAME="screen${i}"
  echo "import 'package:${PROJECT_NAME}/screens/home/screens/${SNAME}/${SNAME}_screen.dart';" \
    >> lib/screens/home/home_screen.dart
done

cat >> lib/screens/home/home_screen.dart << MAINSCREEN2

/// Main screen shell with floating bottom navigation bar.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main content area ───────────────────────────────
            Column(
              children: [
                // Fixed header across all tabs
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _getHorizontalPadding(responsive),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: _getTopSpacing(responsive)),
                      Header(
                        responsive: responsive,
                        onSettingsTap: () {
                          context.push('/settings');
                        },
                      ),
                      SizedBox(height: _getHeaderBottomSpacing(responsive)),
                    ],
                  ),
                ),

                // Tab content area
                Expanded(child: _buildCurrentScreen()),
              ],
            ),

            // ── Floating bottom navigation bar ──────────────────
            Positioned(
              left: _getNavBarHorizontalPadding(responsive),
              right: _getNavBarHorizontalPadding(responsive),
              bottom: _getNavBarBottomPadding(responsive),
              child: FloatingNavBar(
                currentIndex: _currentIndex,
                onTabChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                responsive: responsive,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
MAINSCREEN2

# Append switch cases
for i in $(seq 1 "$TAB_COUNT"); do
  SCLASS="Screen${i}Screen"
  echo "      case $((i-1)):" >> lib/screens/home/home_screen.dart
  echo "        return const $SCLASS();" >> lib/screens/home/home_screen.dart
done

cat >> lib/screens/home/home_screen.dart << MAINSCREEN3
      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================================================
  // RESPONSIVE HELPER METHODS  (mirrors reference main_screen.dart exactly)
  // ==========================================================================

  double _getHorizontalPadding(ResponsiveHelper r) {
    if (r.isMobile) return 16.0;
    if (r.isTablet) return 20.0;
    if (r.isIPad)   return 24.0;
    // Desktop/web: fixed px so it doesn't scale up with viewport width
    return 28.0;
  }

  double _getTopSpacing(ResponsiveHelper r) {
    if (r.isMobile) return 0.0;
    if (r.isTablet) return 20.0;
    if (r.isIPad)   return 24.0;
    return 24.0;
  }

  double _getHeaderBottomSpacing(ResponsiveHelper r) {
    if (r.isMobile) return 16.0;
    if (r.isTablet) return 20.0;
    if (r.isIPad)   return 20.0;
    return 20.0;
  }

  double _getNavBarHorizontalPadding(ResponsiveHelper r) {
    if (r.isMobile) return 20.0;
    if (r.isTablet) return 32.0;
    if (r.isIPad) return 48.0;
    return 64.0;
  }

  double _getNavBarBottomPadding(ResponsiveHelper r) {
    if (r.isMobile) return 10.0;
    if (r.isTablet) return 16.0;
    if (r.isIPad) return 20.0;
    return 24.0;
  }
}
MAINSCREEN3

fi  # end HOME_LAYOUT conditional

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
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: responsive.sp(18),
            color: AppTheme.textPrimary,
          ),
        ),
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
import 'core/services/connectivity_service.dart';
import 'core/services/storage_service.dart';
import 'core/widgets/offline_banner.dart';
import 'routes/app_routes.dart';
import 'screens/login/providers/auth_main_provider.dart';
import 'screens/login/services/auth_api_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService.init();
  ApiClient.initialize();
  await ConnectivityService.instance.init();

  final apiClient = ApiClient.instance;
  final authApiService = AuthApiService(apiClient: apiClient);
  final authProvider = AuthMainProvider(authApiService: authApiService);

  await authProvider.checkAuthStatus();

  runApp(
    MultiProvider(
      providers: [
        // Connectivity (singleton, pre-created)
        ChangeNotifierProvider.value(value: ConnectivityService.instance),

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
      // OfflineBanner wraps every screen automatically
      builder: (context, child) =>
          OfflineBanner(child: child ?? const SizedBox()),
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

# ── TEST SCAFFOLD ─────────────────────────────────────────────
print_step "Writing test scaffold"

mkdir -p test/core/services test/screens/login

# test/core/services/storage_service_test.dart
cat > test/core/services/storage_service_test.dart << 'STORAGETEST'
import 'package:flutter_test/flutter_test.dart';

// StorageService uses flutter_secure_storage + SharedPreferences which
// require platform channels. In unit tests, stub out the platform layer
// or use an integration test. These are placeholder tests showing the
// pattern — replace with proper mocks (e.g. via mockito) as needed.

void main() {
  group('StorageService', () {
    test('isLoggedIn returns false when no token is stored', () {
      // TODO: mock FlutterSecureStorage and SharedPreferences,
      // then verify StorageService.isLoggedIn() == false.
      expect(true, isTrue); // placeholder
    });

    test('saveToken / getToken round-trips correctly', () {
      // TODO: mock secure storage and assert token is retrievable.
      expect(true, isTrue); // placeholder
    });

    test('clear removes token and user data', () {
      // TODO: store then clear, assert getToken() == null.
      expect(true, isTrue); // placeholder
    });
  });
}
STORAGETEST

# test/core/services/api_exceptions_test.dart
cat > test/core/services/api_exceptions_test.dart << 'APIEXTEST'
import 'package:flutter_test/flutter_test.dart';

// ApiException lives in lib/core/services/api_exceptions.dart.
// Import it here once the package name is known (replace MY_APP).
// import 'package:MY_APP/core/services/api_exceptions.dart';

void main() {
  group('ApiException', () {
    test('toString returns message', () {
      // final ex = ApiException('Something went wrong', 500);
      // expect(ex.toString(), 'Something went wrong');
      expect(true, isTrue); // placeholder
    });

    test('NetworkException is an ApiException', () {
      // final ex = NetworkException('No internet');
      // expect(ex, isA<ApiException>());
      expect(true, isTrue); // placeholder
    });

    test('AuthException carries statusCode', () {
      // final ex = AuthException('Unauthorized', 401);
      // expect(ex.statusCode, 401);
      expect(true, isTrue); // placeholder
    });
  });
}
APIEXTEST

# test/screens/login/auth_main_provider_test.dart
cat > test/screens/login/auth_main_provider_test.dart << 'AUTHTEST'
import 'package:flutter_test/flutter_test.dart';

// Replace MY_APP with the actual package name once generated.
// import 'package:MY_APP/screens/login/providers/auth_main_provider.dart';
// import 'package:MY_APP/screens/login/models/user_model.dart';
// import 'package:MY_APP/screens/login/services/auth_api_service.dart';
// import 'package:mockito/mockito.dart';

// @GenerateMocks([AuthApiService])
// import 'auth_main_provider_test.mocks.dart';

void main() {
  group('AuthMainProvider', () {
    test('initial status is AuthStatus.initial', () {
      // final mockService = MockAuthApiService();
      // final provider = AuthMainProvider(authApiService: mockService);
      // expect(provider.status, AuthStatus.initial);
      // expect(provider.currentUser, isNull);
      expect(true, isTrue); // placeholder
    });

    test('signIn sets currentUser and status to authenticated on success', () async {
      // when(mockService.login(email: anyNamed('email'), password: anyNamed('password')))
      //     .thenAnswer((_) async => {
      //       'token': 'tok123',
      //       'user': {'id': '1', 'name': 'Test', 'email': 'a@b.com', 'role': 'USER'},
      //     });
      // final success = await provider.signIn(email: 'a@b.com', password: 'pass');
      // expect(success, isTrue);
      // expect(provider.isAuthenticated, isTrue);
      // expect(provider.currentUser, isA<UserModel>());
      // expect(provider.currentUser!.email, 'a@b.com');
      expect(true, isTrue); // placeholder
    });

    test('signOut clears currentUser and sets unauthenticated', () async {
      // await provider.signOut();
      // expect(provider.isAuthenticated, isFalse);
      // expect(provider.currentUser, isNull);
      expect(true, isTrue); // placeholder
    });

    test('isAdmin returns true when user role is ADMIN', () {
      // Simulate a logged-in admin by injecting state via signIn mock.
      expect(true, isTrue); // placeholder
    });
  });
}
AUTHTEST

print_success "Test scaffold written (test/)"

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
import 'package:json_annotation/json_annotation.dart';

part '${FEATURE}_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ${CLASS}Model {
  final String id;
  final String name;
  final String status;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  const ${CLASS}Model({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
  });

  factory ${CLASS}Model.fromJson(Map<String, dynamic> json) =>
      _\$${CLASS}ModelFromJson(json);

  Map<String, dynamic> toJson() => _\$${CLASS}ModelToJson(this);
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

# ── Auto-run code generation ──────────────────────────────────
echo -e "\n${BLUE}${BOLD}▶ Running build_runner...${NC}"
dart run build_runner build
if [ $? -eq 0 ]; then
  echo -e "  ${GREEN}✔ Code generation complete (${FEATURE}_model.g.dart generated)${NC}"
else
  echo -e "  ${YELLOW}⚠ build_runner had issues. Run manually: dart run build_runner build${NC}"
fi

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

# ── CODE GENERATION (build_runner + flutter_gen) ─────────────
print_step "Running build_runner (json_serializable + flutter_gen)"
dart run build_runner build 2>&1
if [ $? -eq 0 ]; then
  print_success "Code generation complete (*.g.dart + lib/gen/)"
else
  print_warn "build_runner had issues. Run manually: dart run build_runner build"
fi

# ── APP ICON GENERATION ───────────────────────────────────────
print_step "Generating app icons (flutter_launcher_icons)"
if [ -f "assets/images/app_icon.png" ]; then
  dart run flutter_launcher_icons 2>&1
  if [ $? -eq 0 ]; then
    print_success "App icons generated"
  else
    print_warn "flutter_launcher_icons had issues. Run manually after adding assets/images/app_icon.png"
  fi
else
  print_warn "No app_icon.png found at assets/images/ — skipping icon generation."
  print_warn "Add a 1024×1024 PNG as assets/images/app_icon.png, then run: dart run flutter_launcher_icons"
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
echo "  ✔ AuthMainProvider + signIn/register/signOut/checkAuthStatus"
echo "  ✔ Splash → Login/Register → Home flow"
echo "  ✔ LoginScreen: BrandingSide + AuthSide (split into own files)"
echo "  ✔ AuthTransition animation + RegisterForm"
echo "  ✔ main.dart wired up"
echo "  ✔ ConnectivityService + OfflineBanner (auto-shown on every screen)"
echo "  ✔ Android permissions (INTERNET, CAMERA, READ_MEDIA_IMAGES)"
echo "  ✔ iOS Info.plist usage descriptions (camera, photo library)"
echo "  ✔ macOS entitlements (network.client + network.server for sandbox)"
echo "  ✔ json_serializable + build_runner (*.g.dart code generation)"
echo "  ✔ UserModel (@JsonSerializable) — used by AuthMainProvider + StorageService"
echo "  ✔ flutter_gen (lib/gen/ typed asset references)"
echo "  ✔ flutter_launcher_icons config (add app_icon.png to run)"
echo "  ✔ Test scaffold (test/core/ + test/screens/login/)"
if [[ "$HOME_LAYOUT" == "tabnav" ]]; then
echo "  ✔ MainScreen shell with floating nav bar + $TAB_COUNT tab screens (Screen 1 … Screen $TAB_COUNT)"
else
echo "  ✔ Plain HomeScreen (AppBar + body)"
fi
echo ""
echo -e "  ${BOLD}Next steps:${NC}"
echo "  1. Update lib/core/global_variables/global_variables.dart (apiKey)"
echo "  2. Update lib/screens/login/services/auth_api_service.dart (your endpoint)"
echo "  3. Add assets/images/app_icon.png (1024×1024), then: dart run flutter_launcher_icons"
echo "  4. Run: ./new_feature.sh <name>   to scaffold any new feature (build_runner runs automatically)"
echo "  6. Run: flutter run"
echo ""