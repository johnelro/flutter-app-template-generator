# Flutter Clean Architecture Bootstrap

A single shell script that scaffolds a production-ready Flutter project in under two minutes — fully wired, lint-clean, and ready to build features immediately.

---

## What It Does

Running `create_flutter_app.sh` interactively asks four questions, then generates a complete project:

- Full clean-architecture folder structure
- All core services pre-written (`ApiClient`, `StorageService`, `api_exceptions`)
- `AppTheme` with design tokens (colors, typography, spacing, radii)
- `ResponsiveHelper` — full responsive API for mobile / tablet / iPad / desktop
- `GoRouter` with `AuthRouteNotifier` and auth-aware redirect
- `AuthMainProvider` with `checkAuthStatus` / `signIn` / `signOut`
- Splash → Login → Home flow that runs immediately
- `main.dart` fully wired with `MultiProvider`
- `pubspec.yaml` with all dependencies at latest stable versions
- All imports converted to `package:` URIs automatically
- `flutter analyze` runs at the end — target is zero issues

A second script, `new_feature.sh`, is generated inside every project and scaffolds any new feature in one command.

---

## Requirements

| Tool | Minimum |
|------|---------|
| Flutter SDK | 3.19+ (stable channel) |
| Dart | 3.3+ |
| Bash | 3.2+ (macOS default works) |
| Python 3 | Any version (for the import fixer) |

---

## Usage

### 1. Clone or download

```bash
git clone https://github.com/your-username/flutter-clean-arch-bootstrap.git
cd flutter-clean-arch-bootstrap
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
|--------|---------|
| Project name (snake_case) | `my_app` |
| Organization | `com.yourcompany` |
| Base API URL | `https://api.yourcompany.com` |
| App display title | `My App` (defaults to title-cased project name) |

The script then creates `my_app/`, installs dependencies, converts all imports, and runs `flutter analyze`.

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

## Adding a Feature

Every generated project includes `new_feature.sh`. Run it from inside the project root:

```bash
./new_feature.sh products
```

This creates:

```
lib/screens/products/
├── models/           ← empty, ready for products_model.dart
├── providers/        ← products_provider.dart (full ChangeNotifier boilerplate)
├── services/         ← products_api_service.dart (fetch + create stubs)
├── widgets/          ← empty, ready for your widgets
└── products_screen.dart  ← placeholder screen ("Start this new feature.")
```

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
|---------|---------|---------|
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
| `flutter_lints` | ^5.0.0 | Lint rules (dev) |
| `flutter_launcher_icons` | ^0.14.4 | App icon generation (dev) |

---

## Architecture

```
lib/
├── main.dart                          # App entry point, MultiProvider, GoRouter
├── core/
│   ├── global_variables/              # baseUrl, apiKey, appVersion
│   ├── services/
│   │   ├── api_client.dart            # Dio singleton — all HTTP goes here
│   │   ├── api_exceptions.dart        # ApiException hierarchy
│   │   └── storage_service.dart       # Secure + SharedPrefs storage
│   └── widgets/                       # Widgets shared across 2+ features
├── routes/
│   ├── app_routes.dart                # All GoRouter routes
│   └── auth_route_notifier.dart       # Auth-aware refresh notifier
├── screens/
│   ├── splash/
│   ├── login/
│   │   ├── providers/auth_main_provider.dart
│   │   ├── services/auth_api_service.dart
│   │   └── login_screen.dart
│   ├── home/home_screen.dart
│   ├── settings/settings_screen.dart
│   └── [feature]/                     # Each feature is self-contained
│       ├── models/
│       ├── providers/
│       ├── services/
│       ├── widgets/
│       └── [feature]_screen.dart
├── theme/app_theme.dart               # All colors, text styles, ThemeData
└── utils/responsive_helper.dart       # Device detection + responsive sizing
```

### Core Principles

1. **Feature-based** — every feature owns its models, provider, service, and widgets
2. **UI only in widgets** — no API calls, no business logic in widget files
3. **One provider per feature** — focused `ChangeNotifier`, max 300 lines
4. **Service layer for all I/O** — API calls and storage live in service classes
5. **`package:` imports everywhere** — enforced automatically by the import fixer
6. **`flutter analyze` always clean** — no warnings, no deprecations

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

Device detection: `isMobile` · `isTablet` · `isIPad` · `isDesktop` · `isAnyTablet`

Spacing getters: `spacingXS` `spacingS` `spacingM` `spacingL` `spacingXL` `spacingXXL`

Text style getters: `headlineLarge` · `headlineMedium` · `titleLarge` · `titleMedium` · `bodyLarge` · `bodyMedium` · `bodySmall` · `labelSmall`

For custom dimensions, add a private `_get*()` method with 4 branches:

```dart
double _getCardPadding(ResponsiveHelper r) {
  if (r.isMobile) return 12.0;
  if (r.isTablet) return 14.0;
  if (r.isIPad) return 15.0;
  return 16.0;   // desktop
}
```

### Skeleton Loading (skeletonizer)

Use `Skeletonizer` on first load (`!provider.hasInitialized`). Pass real card widgets fed fake model instances — never build placeholder boxes:

```dart
Widget _buildSkeletonLoader(ResponsiveHelper responsive) {
  final fakeItems = List.generate(
    5,
    (i) => ProductModel(id: 'fake-$i', name: 'Loading product', status: ProductStatus.unknown, createdAt: DateTime.now()),
  );

  return Skeletonizer(
    enabled: true,
    child: Column(
      children: fakeItems.map((item) => ProductItemCard(item: item, responsive: responsive)).toList(),
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

## Project Checklist

After running the script, the following are already done:

- [x] Folder structure
- [x] `global_variables.dart` (update `apiKey`)
- [x] `app_theme.dart`
- [x] `responsive_helper.dart`
- [x] `api_exceptions.dart`
- [x] `storage_service.dart`
- [x] `api_client.dart`
- [x] `AuthMainProvider` + `AuthRouteNotifier`
- [x] `main.dart` wired
- [x] GoRouter configured
- [x] All imports converted to `package:` URIs
- [x] `flutter analyze` clean

Still to do manually:

- [ ] Set real `apiKey` in `global_variables.dart`
- [ ] Update `/auth/login` endpoint + response shape in `auth_api_service.dart`
- [ ] Replace placeholder hex colors in `app_theme.dart` with your brand palette
- [ ] Configure `flutter_launcher_icons` and generate app icons

---

## License

MIT — use freely in personal and commercial projects.
