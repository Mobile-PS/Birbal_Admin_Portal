# Birbal Advice Admin

Admin portal for Birbal Advice insurance. One Flutter codebase runs on web and mobile. HTTP goes through Dio and uses the same API host and response envelope as the customer app.

## Run

```bash
# Web
flutter run -d chrome

# Phone or emulator
flutter run
```

Point at another API without editing source:

```bash
flutter run -d chrome --dart-define=BASE_URL=https://your-host/api/v1
```

The default base URL is `https://birbaladvice.com/api/v1`.

API calls are enabled (`AppConfig.disableApiCalls = false`). Login uses `/auth/otp/request` and `/auth/otp/verify`. The dashboard loads counts from `GET /admin/dashboard`. Customers load from `GET /admin/dashboard/userDetails` with `filter`, `page`, and `size`. Inquiries load from `GET /inquiries` with `page` and `size`. Products load from `GET /admin/dashboard/categories`. Category toggles use `PATCH /admin/dashboard/categories/{code}/toggle`. Add Product uses `POST /createInsuranceCategory`. Opening a product loads plans from `GET /insurance-plans` with `category` set to the product code. Add Plan uses `POST /createInsurerData`. Add Policy (from a customer) uses `POST /policies`.

Wide screens keep a side menu. Tablet width collapses it to icons. Phones use a drawer.

`ApiClient` wraps Dio (`get`, `post`, `put`, `patch`, `delete`). Failures throw `ApiException`, using the server `message` when the body matches the shared envelope. A saved access token is sent as `Authorization: Bearer ...`.
