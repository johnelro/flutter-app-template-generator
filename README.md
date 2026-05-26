# Flutter Clean Template Generator

A single shell script that scaffolds a production-ready Flutter project in under two minutes — fully wired, lint-clean, and ready to build features immediately.

---

## What It Does

Running `create_flutter_app.sh` interactively asks five questions, then generates a complete project:

- Full clean-architecture folder structure
- All core services pre-written (`ApiClient`, `StorageService`, `ConnectivityService`, `api_exceptions`)
- `AppTheme` with design tokens (colors, typography, spacing, radii)
- `ResponsiveHelper` — full responsive API for mobile / tablet / iPad / desktop (see [ResponsiveHelper](#responsivehelper) below)
- **Home screen layout choice** — plain single screen *or* floating bottom nav bar with 2–5 tab screens (see [Home Screen Layout](#home-screen-layout) below)
- `GoRouter` with `AuthRouteNotifier` and auth-aware redirect
- `AuthMainProvider` with `checkAuthStatus` / `signIn` / `register` / `signOut`
- `UserModel` with `@JsonSerializable` — wired into `AuthMainProvider` and `StorageService`
- `OfflineBanner` — animated offline indicator shown automatically on every screen
- `Splash` → `Login` / `Register` → `Home` flow that runs immediately
- `main.dart` fully wired with `MultiProvider`
- `pubspec.yaml` with all dependencies at latest stable versions
- Android permissions auto-injected (`INTERNET`, `CAMERA`, `READ_MEDIA_IMAGES`)
- iOS `Info.plist` usage descriptions auto-injected (camera, photo library)
- macOS entitlements auto-patched (`network.client`, `network.server`)
- `flutter_launcher_icons` config ready — drop in your PNG and run one command
- Code generation wired (`json_serializable` + `flutter_gen`) — run `build_runner` once
- Test scaffold generated (`test/core/` + `test/screens/login/`)
- All imports converted to `package:` URIs automatically
- `flutter analyze` runs at the end — target is zero issues

A second script, `new_feature.sh`, is generated inside every project and scaffolds any new feature in one command.

---

## Requirements

| Tool | Minimum |
| ---- | ------- |
| Flutter SDK | 3.44+ (stable channel) |
| Dart | 3.11.5+ |
| Bash | 3.2+ (macOS default works) |
| Python 3 | Any version (for the import fixer and platform patchers) |

### Platform Compatibility

| Platform | Supported | Notes |
| -------- | --------- | ----- |
| macOS | ✅ Native | Works out of the box |
| Linux | ✅ Native | Works out of the box |
| Windows | ⚠️ Needs setup | Requires WSL 2, Git Bash, or Cygwin (see below) |

### Windows Setup

The script is Bash — Windows has no Bash shell by default. The generated Flutter project works perfectly on Windows; it's only the generator script that needs a Bash environment to run.

**Option 1 — WSL 2 (recommended)**

Install WSL 2 with Ubuntu from the Microsoft Store, then run everything inside the Ubuntu terminal:

```bash
chmod +x create_flutter_app.sh
./create_flutter_app.sh
```

Full Linux compatibility — the most reliable option.

**Option 2 — Git Bash**

Ships with [Git for Windows](https://git-scm.com/download/win). Works for most of the script but requires Python 3 to be installed separately and available in your PATH.

**Option 3 — Cygwin**

Full POSIX layer for Windows. Works but is heavier to install than the other two options.

> **Tip:** After generating the project in WSL 2 or Git Bash, you can open and develop it normally in VS Code or Android Studio on Windows.

---

## Usage

### 1. Clone or download

```bash
git clone https://github.com/johnelro/flutter-app-complete-generator.git
cd flutter-app-complete-generator
```

### 2. Make it executable

```bash
chmod +x create_flutter_app.sh
```

### 3. Run it

```bash
./create_flutter_app.sh
```

You will be prompted for:

| Prompt | Example |
| ------ | ------- |
| Project name (snake_case) | `my_app` |
| Organisation | `com.yourcompany` |
| Base API URL | `https://api.yourcompany.com` |
| App display title | `My App` (defaults to title-cased project name) |
| Home screen layout | `1` Plain screen · `2` Bottom nav with tabs |

When you choose **Bottom nav**, you are also asked for the number of tab screens (2–5).

The script then creates `my_app/`, installs dependencies, runs code generation, patches platform files, and runs `flutter analyze`.

### 4. Finish setup

Two values need your real credentials before you run the app:

```dart
// lib/core/global_variables/global_variables.dart
const String apiKey = 'your-api-key';   // ← replace

// lib/screens/login/services/auth_api_service.dart
// Update the endpoint path and response shape to match your API
```

### 5. Run

```bash
cd my_app
flutter run
```

---

## Code Generation

The project uses `build_runner` to generate two things automatically:

| What | Output | Trigger |
| ---- | ------ | ------- |
| `json_serializable` | `*.g.dart` next to each model | Adding or changing a model |
| `flutter_gen` | `lib/gen/assets.gen.dart` | Adding a file to `assets/` |

**One-shot** (CI, after `git pull`, before release):
```bash
dart run build_runner build
```

**Watch mode** (while coding — reruns on every save):
```bash
dart run build_runner watch
```

Run `build_runner` after:
- Adding any image or file to `assets/`
- Changing any field in an existing `@JsonSerializable` model

> **Note:** Running `./new_feature.sh` now triggers `build_runner` automatically — no manual step needed for new features.

---

## App Icon

Drop a `1024×1024` PNG at `assets/images/app_icon.png`, then run:

```bash
dart run flutter_launcher_icons
```

This generates icons for Android (adaptive) and iOS. The `flutter_icons:` config is already in `pubspec.yaml`.

---

## Adding a Feature

Every generated project includes `new_feature.sh`. Run it from inside the project root:

```bash
./new_feature.sh products
```

This creates:

```
lib/screens/products/
├── models/products_model.dart         ← @JsonSerializable, part file ready
├── providers/products_provider.dart   ← full ChangeNotifier boilerplate
├── services/products_api_service.dart ← fetch + create stubs
├── widgets/                           ← empty, ready for your widgets
└── products_screen.dart               ← placeholder screen
```

Code generation runs **automatically** right after scaffolding — `new_feature.sh` calls `dart run build_runner build` for you, so the model's `.g.dart` is ready immediately.

Then follow the two printed next steps:

```dart
// 1. Register provider in lib/main.dart
ChangeNotifierProvider(create: (_) => ProductsProvider()),

// 2. Add route in lib/routes/app_routes.dart
GoRoute(
  path: '/products',
  builder: (_, __) => const ProductsScreen(),
),
```

---

## Technology Stack

| Package | Version | Purpose |
| ------- | ------- | ------- |
| `provider` | ^6.1.5+1 | State management |
| `go_router` | ^17.2.3 | Navigation |
| `dio` | ^5.9.0 | HTTP client |
| `flutter_secure_storage` | ^10.0.0 | Encrypted token storage |
| `shared_preferences` | ^2.5.4 | Non-sensitive local storage |
| `google_fonts` | ^6.3.2 | Typography |
| `skeletonizer` | ^1.4.3 | Skeleton loading states |
| `shimmer` | ^3.0.0 | Shimmer effects |
| `image_picker` | ^1.2.2 | Media selection |
| `flutter_image_compress` | ^2.4.0 | Image compression |
| `intl` | ^0.20.2 | Internationalisation |
| `connectivity_plus` | ^7.0.0 | Network status |
| `url_launcher` | ^6.3.2 | URL / deep link handling |
| `json_annotation` | ^4.12.0 | Model serialization annotations |
| `flutter_lints` | ^5.0.0 | Lint rules (dev) |
| `flutter_launcher_icons` | ^0.14.4 | App icon generation (dev) |
| `build_runner` | ^2.4.14 | Code generation runner (dev) |
| `json_serializable` | ^6.8.0 | `fromJson`/`toJson` generation (dev) |
| `flutter_gen_runner` | ^5.9.0 | Typed asset class generation (dev) |

---

## Architecture

```
lib/
├── main.dart                          # Entry point, MultiProvider, GoRouter, OfflineBanner
├── gen/                               # Auto-generated by flutter_gen — do not edit
│   └── assets.gen.dart                # Typed asset references (Assets.images.logo)
├── core/
│   ├── global_variables/              # baseUrl, apiKey, appVersion
│   ├── services/
│   │   ├── api_client.dart            # Dio singleton — all HTTP goes here
│   │   ├── api_exceptions.dart        # ApiException hierarchy
│   │   ├── connectivity_service.dart  # Real-time online/offline ChangeNotifier
│   │   └── storage_service.dart       # Secure + SharedPrefs storage
│   └── widgets/
│       └── offline_banner.dart        # Auto-shown banner on connectivity loss
├── routes/
│   ├── app_routes.dart                # All GoRouter routes
│   └── auth_route_notifier.dart       # Auth-aware refresh notifier
├── screens/
│   ├── splash/
│   ├── login/
│   │   ├── models/user_model.dart     # @JsonSerializable UserModel
│   │   ├── providers/auth_main_provider.dart
│   │   ├── services/auth_api_service.dart
│   │   └── login_screen.dart
│   ├── home/                          # Layout depends on choice made during setup:
│   │   │
│   │   │  ── Plain screen layout ──────────────────────────────────
│   │   └── home_screen.dart           # Simple AppBar + body
│   │
│   │      ── Bottom nav layout ────────────────────────────────────
│   │   ├── home_screen.dart           # MainScreen shell (tab state, Scaffold)
│   │   ├── widgets/
│   │   │   ├── header.dart            # App title (left) + settings icon (right)
│   │   │   └── floating_nav_bar.dart  # Animated floating pill nav bar
│   │   └── screens/
│   │       ├── screen1/screen1_screen.dart
│   │       ├── screen2/screen2_screen.dart
│   │       └── ...                    # One folder per tab (2–5)
│   │
│   ├── settings/settings_screen.dart
│   └── [feature]/                     # Each feature is self-contained
│       ├── models/                    # @JsonSerializable model + .g.dart
│       ├── providers/
│       ├── services/
│       ├── widgets/
│       └── [feature]_screen.dart
├── theme/app_theme.dart               # All colors, text styles, ThemeData
└── utils/responsive_helper.dart       # Device detection + responsive sizing

test/
├── core/services/
│   ├── storage_service_test.dart
│   └── api_exceptions_test.dart
└── screens/login/
    └── auth_main_provider_test.dart

assets/
├── images/                            # Place app_icon.png (1024×1024) here
├── image_icons/
└── fonts/                             # Bundled fonts (avoids runtime fetch)
```

### Core Principles

1. **Feature-based** — every feature owns its models, provider, service, and widgets
2. **UI only in widgets** — no API calls, no business logic in widget files
3. **One provider per feature** — focused `ChangeNotifier`, max 300 lines
4. **Service layer for all I/O** — API calls and storage live in service classes
5. **`package:` imports everywhere** — enforced automatically by the import fixer
6. **`flutter analyze` always clean** — no warnings, no deprecations

### Models — `@JsonSerializable`

Every model generated by `new_feature.sh` uses `json_serializable`. You annotate fields and let `build_runner` write the parsing code:

```dart
import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart'; // generated — do not edit

@JsonSerializable()
class ProductModel {
  final String id;
  final String name;
  final String status;
  final DateTime createdAt;

  const ProductModel({ ... });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}
```

After any model change, regenerate:
```bash
dart run build_runner build
```

### Assets — `flutter_gen`

After running `build_runner`, reference assets with full type safety and IDE auto-complete:

```dart
// Before (crashes silently on typo)
Image.asset('assets/images/logo.png')

// After (compile error on typo — much safer)
Image.asset(Assets.images.logo.path)
```

### Connectivity

`ConnectivityService` is a singleton `ChangeNotifier` initialized in `main()`. The `OfflineBanner` widget is wired into `MaterialApp.router`'s `builder` so it appears on every screen without any per-screen code. Access connectivity state anywhere:

```dart
final isOnline = context.read<ConnectivityService>().isOnline;
```

### Home Screen Layout

The script offers two layouts during setup:

**Option 1 — Plain screen** (default)

A simple `Scaffold` with an `AppBar` and a body. Good for apps where the home screen is a single destination.

```
lib/screens/home/
└── home_screen.dart   ← AppBar + body placeholder
```

**Option 2 — Bottom nav with floating nav bar**

A `MainScreen` shell that hosts 2–5 tab screens behind a floating pill-style navigation bar. The number of tabs is chosen during setup.

```
lib/screens/home/
├── home_screen.dart              ← MainScreen shell (tab state, Scaffold)
├── widgets/
│   ├── header.dart               ← shared app-title / settings header
│   └── floating_nav_bar.dart     ← animated floating pill nav bar
└── screens/
    ├── screen1/screen1_screen.dart
    ├── screen2/screen2_screen.dart
    └── ...                       ← one folder per tab (up to 5)
```

The `FloatingNavBar` auto-generates icon pairs (filled/outlined) and labels for each tab. Switch to it at any time by re-running the generator for a new project — or manually drop in `floating_nav_bar.dart` and the tab screen folder structure.

---

### ResponsiveHelper

Every screen reads device type and sizes from `ResponsiveHelper`:

```dart
@override
Widget build(BuildContext context) {
  final responsive = ResponsiveHelper(context);

  return Padding(
    padding: responsive.defaultPadding,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: responsive.maxFormWidth),
      child: Text(
        'Title',
        style: TextStyle(fontSize: responsive.sp(18)),
      ),
    ),
  );
}
```

#### Device detection

| Getter | True when |
| ------ | --------- |
| `isMobile` | width < 600 px |
| `isTablet` | width 600–1199 px, not an iPad (Android / Windows tablets) |
| `isIPad` | physical device, `shortestSide` ≥ 600 px, width < 1200 px — covers **all** iPad models including iPad 13" (~1024 px shortest side) |
| `isDesktop` | width ≥ 1200 px |
| `isAnyTablet` | `isIPad \|\| isTablet` |

> **Note on iPad M3 13":** earlier versions capped `isIPad` at `shortestSide < 900`, which caused the 13-inch model to fall through to `isTablet`. The cap has been removed — any physical device with `shortestSide ≥ 600` is treated as iPad. Flutter Web bypasses the heuristic entirely (browser viewports are not physical devices).

#### Scale factors

| Device | `sp()` multiplier |
| ------ | ---------------- |
| Small mobile (< 350 px) | 0.85× |
| Mobile | 1.0× |
| Tablet | 1.1× |
| iPad | 1.15× |
| Desktop / Web | 1.05× |

The desktop factor was reduced from the previous 1.3× to 1.05× to prevent font and icon sizes from ballooning on wide browser viewports.

#### Spacing getters: `spacingXS` `spacingS` `spacingM` `spacingL` `spacingXL` `spacingXXL`

#### Text style getters: `headlineLarge` · `headlineMedium` · `titleLarge` · `titleMedium` · `bodyLarge` · `bodyMedium` · `bodySmall` · `labelSmall`

For custom dimensions, add a private `_get*()` method with 4 branches:

```dart
double _getCardPadding(ResponsiveHelper r) {
  if (r.isMobile) return 12.0;
  if (r.isTablet) return 14.0;
  if (r.isIPad)   return 15.0;
  return 16.0;   // desktop / web
}
```

### Skeleton Loading (skeletonizer)

Use `Skeletonizer` on first load (`!provider.hasInitialized`). Pass real card widgets fed fake model instances — never build placeholder boxes:

```dart
Widget _buildSkeletonLoader(ResponsiveHelper responsive) {
  final fakeItems = List.generate(
    5,
    (i) => ProductModel(
      id: 'fake-$i',
      name: 'Loading product',
      status: 'active',
      createdAt: DateTime.now(),
    ),
  );

  return Skeletonizer(
    enabled: true,
    child: Column(
      children: fakeItems
          .map((item) => ProductItemCard(item: item, responsive: responsive))
          .toList(),
    ),
  );
}
```

Use it:

```dart
!provider.hasInitialized
    ? _buildSkeletonLoader(responsive)
    : ProductList(responsive: responsive),
```

---

## Platform Setup

The script automatically patches all three platforms during generation. Here's what each gets:

### Android — `AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
```

### iOS — `Info.plist`
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select images.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs permission to save photos to your library.</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for video recording.</string>
```

### macOS — `DebugProfile.entitlements` + `Release.entitlements`
```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
```

Without `network.client` on macOS, any outbound HTTP/S call (API, fonts, etc.) fails with `errno = 1 — Operation not permitted` due to the App Sandbox.

---

## Project Checklist

After running the script, the following are already done:

- [x] Folder structure
- [x] `global_variables.dart` (update `apiKey`)
- [x] `app_theme.dart`
- [x] `responsive_helper.dart`
- [x] `api_exceptions.dart`
- [x] `storage_service.dart`
- [x] `api_client.dart`
- [x] `connectivity_service.dart` + `offline_banner.dart`
- [x] `UserModel` (`@JsonSerializable`)
- [x] `AuthMainProvider` + `AuthRouteNotifier`
- [x] `main.dart` wired
- [x] GoRouter configured
- [x] **Home screen layout** — plain screen or floating bottom nav (chosen during setup)
- [x] Android permissions injected
- [x] iOS `Info.plist` usage descriptions injected
- [x] macOS entitlements patched
- [x] `flutter_launcher_icons` config in `pubspec.yaml`
- [x] `build_runner` + `json_serializable` + `flutter_gen` configured
- [x] Test scaffold (`test/core/` + `test/screens/login/`)
- [x] All imports converted to `package:` URIs
- [x] `flutter analyze` clean

Still to do manually:

- [ ] Set real `apiKey` in `global_variables.dart`
- [ ] Update `/auth/login` and `/auth/register` endpoints in `auth_api_service.dart`
- [ ] Replace placeholder hex colors in `app_theme.dart` with your brand palette
- [ ] Add `assets/images/app_icon.png` (1024×1024), then run `dart run flutter_launcher_icons`
- [ ] Run `dart run build_runner build` after first clone

---

## License

MIT — use freely in personal and commercial projects.