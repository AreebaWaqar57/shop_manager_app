# ShopManager

A Flutter app for authentication and product management. It consumes the
[DummyJSON](https://dummyjson.com/docs) REST API with **Dio**, manages state with
**Provider / ChangeNotifier**, navigates with **GoRouter**, and stores tokens with
**flutter_secure_storage**.

## Features

- Splash screen that restores a saved session (stays logged in when offline)
- Login with validation, password toggle, loading state and clear error messages
- Product list with search, category filter, pagination (limit/skip) and pull-to-refresh
- Product details with image slider
- Add, edit and delete products (simulated by DummyJSON, see limitations)
- Profile screen and logout that clears the token and in-memory data
- Loading, empty, error and retry states on every screen
- Responsive layout (1 column on phones, a grid on wide screens), light and dark theme
- Unit and widget tests that run offline

## Tech stack

| Package | Purpose |
|---|---|
| `dio` | HTTP requests, interceptors, timeouts |
| `provider` | State management (`ChangeNotifier`) |
| `go_router` | Named routes and authentication-aware redirects |
| `flutter_secure_storage` | Secure token storage |

## Setup

```bash
git clone <repository-url>
cd shop_manager
flutter pub get
flutter run
```

Requirements: Flutter SDK with Dart 3, an Android emulator, iOS simulator or device.
Android needs `minSdk 23` for secure storage, and the `INTERNET` permission in
`android/app/src/main/AndroidManifest.xml` for release builds.

**Demo login:** use one of the demo users listed in the
[DummyJSON auth docs](https://dummyjson.com/docs/auth). Credentials are typed into the
login form and are never stored in the source code.

Run on a phone or emulator. Chrome works for most screens, but secure storage and CORS
behave differently on the web.

## Architecture

```
lib/
├── main.dart, app.dart        App start, providers, interceptors, router, theme
├── core/                      Shared code
│   ├── constants/             API URLs and timeouts
│   ├── network/               ApiClient, ApiException, interceptors
│   ├── routing/               GoRouter and redirects
│   ├── storage/               Secure token storage
│   ├── theme/                 Material 3 themes
│   ├── utils/                 Validators
│   └── widgets/               Loading, error, empty, button, text field
└── features/
    ├── auth/                  models, repository, AuthProvider, login + splash screens
    ├── products/              models, repository, ProductProvider, screens, ProductCard
    └── profile/               profile screen
```

Each layer has one job:

| Layer | Responsibility |
|---|---|
| Models | Parse JSON into typed Dart objects |
| `ApiClient` | Dio configuration and transport (timeouts, headers, error conversion) |
| Repositories | Call the API and map responses into models |
| Providers | Hold state and expose actions |
| Screens and widgets | Render state; they never call HTTP directly |

### Data flow

```
Screen --context.read()--> Provider --> Repository --> ApiClient (Dio) --> DummyJSON
Screen <--watch/Consumer/Selector-- Provider <-- models <-- JSON
                    notifyListeners()
```

1. A screen calls an action, for example `context.read<ProductProvider>().fetchProducts()`.
2. The provider sets `isLoading`, calls the repository and calls `notifyListeners()`.
3. The repository calls `ApiClient` and parses the JSON into `Product` objects.
4. The provider stores the result (or an error message) and notifies again.
5. `Consumer`, `Selector` and `context.watch()` rebuild only the widgets that need it.

## Dio networking

- **`ApiClient`** is the single Dio instance with base URL, timeouts, JSON headers and
  generic `get/post/patch/delete`. It checks the response type and throws
  "Unexpected response format" when it does not match.
- **`ApiException`** is the only error type the rest of the app sees. Raw
  `DioException`s never leave the network layer. It maps timeouts, offline, 400, 401,
  403, 404, 5xx and unknown errors to a readable message and an `ApiErrorType`.
- **`SafeLogInterceptor`** logs only method, path and status code, in debug mode only.
  Headers and bodies (passwords, tokens) are never logged.
- **`AuthInterceptor`** adds `Authorization: Bearer <token>` to requests (except login
  and refresh).
- **Write requests are never retried automatically**, because the server may already have
  processed them.

## Authentication

1. **Startup:** `AuthProvider.initSession()` reads the stored token and calls `/auth/me`.
   The splash screen is shown meanwhile.
2. **Login:** `POST /auth/login` returns an access token and a refresh token. Both are
   saved in secure storage, then the profile is loaded and the router opens the products
   screen. The button is disabled while the request runs, so double submits are ignored.
3. **Route guard:** GoRouter's `redirect` reads `AuthProvider.status`, and
   `refreshListenable: auth` re-runs it on every change. Logged-out users can only reach
   `/login`; logged-in users skip `/login` and `/splash`.
4. **Token refresh:** DummyJSON supports `POST /auth/refresh`, so on a 401 the
   interceptor refreshes **once** (concurrent 401s share one refresh) and retries safe
   GET requests only. If refresh fails, the session ends and the user returns to login.
5. **Offline at startup:** a network or server error does **not** log the user out. Only an
   authentication failure does.
6. **Logout:** clears the secure tokens, the user, and (through `onLoggedOut`) the
   `ProductProvider` data, then the router redirects to `/login`.

## Pagination, search and filters

- Pages use `limit=20` and `skip`. `loadMore()` runs when the list is near the bottom,
  appends the next page and stops when all products are loaded.
- Duplicate pagination requests are ignored while one is running.
- Search uses `/products/search?q=` and categories use `/products/category/{category}`.
  Changing either resets the list to the first page. A request counter ignores outdated
  responses if the user changes the search while a request is still running.
- Pull-to-refresh reloads the first page.

## Create, edit and delete

The add/edit form is one screen reused for both. It validates required fields, a numeric
price greater than 0, and an optional http(s) image URL. The button is disabled while
saving, and a snackbar shows success or the error. Deleting asks for confirmation first.
After a successful call the provider updates its local list.

## Tests

```bash
flutter analyze
flutter test
```

Tests use fake repositories (`test/helpers/fakes.dart`), so they are deterministic and
never use the live API.

| Area | File |
|---|---|
| Product and response JSON parsing, optional fields | `test/models/product_model_test.dart` |
| Validators | `test/utils/validators_test.dart` |
| Provider states: load, error, retry, paging, search, filter, CRUD, dispose | `test/providers/product_provider_test.dart` |
| Login validation and button behaviour | `test/widgets/login_screen_test.dart` |
| Loading, empty, error + retry, list rendering | `test/widgets/products_screen_test.dart` |

## DummyJSON limitations

- **Writes are simulated.** `POST /products/add`, `PATCH` and `DELETE` return a success
  response but **do not change server data**. The app updates its local list after a
  successful response only. Changes are lost on refresh, search, category change or restart.
- New products always get the same id (195). The app makes ids unique locally.
- Products created in the app do not exist on the server, so editing or deleting them
  updates local state only (the server would answer 404).
- Search and category filtering cannot be combined, so choosing one clears the other.
- Demo credentials and tokens are for development only.

## Implementation decisions

- Extra files beyond the suggested structure: `product_response.dart` (pagination model),
  `validators.dart` (shared form validation), `app_button.dart` / `app_text_field.dart`
  (reusable widgets), `splash_screen.dart`, `app_theme.dart`.
- `ProductProvider` stores the details of the selected product too, so all product state
  stays in one provider. `AuthProvider` is separate.
- Form-only state (text controllers, password visibility) stays local to the screens.
- The provider ignores `notifyListeners()` after disposal.
- Category in the product form is a text field for simplicity.

## Git workflow

Branch: `feature/shop-manager-app`, with small commits and a merge request for review.
No credentials, tokens or secrets are committed.