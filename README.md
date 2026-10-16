# Baby Care — Mobile (Flutter, Android)

This is the Flutter version of the Baby Care web app (`../frontend`). It uses the same backend API (`../backend`), so data stays in sync between web and mobile.

```bash
# backend first: cd ../backend && npm run seed && npm run dev
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
```

Demo login: `01712345678` · code `123456` · coupon `BABYCARE`

**Read [MOBILE_SYNC.md](MOBILE_SYNC.md) before changing anything.** It maps every screen, endpoint and model to the web app, lists the mobile-only changes, and holds the change log.
