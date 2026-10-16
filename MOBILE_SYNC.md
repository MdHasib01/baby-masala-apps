# Baby Care Mobile (Flutter) — Sync & Parity Tracker

This file tracks what the Flutter app in `mobile/` contains and how it maps to the web app (`frontend/`) and the shared API (`backend/`).

**Ground rules**

1. Mobile and web use **the same backend API**: the same endpoints, request bodies and response shapes. The backend is never forked for mobile.
2. Any change that touches a screen, endpoint, model or shared constant must be recorded in **§9 Change log**, so that the other client can follow.
3. If a change needs a new or changed endpoint, change `backend/` first, then update both `frontend/src/services/babyCareService.ts` and `mobile/lib/data/services/baby_care_api.dart`, then update **§4**.

---

## 1. Run it

```bash
# 1) Backend (from backend/)
npm install
npm run seed        # demo data; `npm run seed:reset` wipes first
npm run dev         # http://localhost:5000/api

# 2) Mobile (from mobile/)
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api        # Android emulator
flutter run --dart-define=API_BASE_URL=http://<PC-LAN-IP>:5000/api     # real phone on same Wi-Fi

# 3) Web (from frontend/), to compare side by side
npm run dev         # http://localhost:5173
```

| Setting | Where | Default |
|---|---|---|
| `API_BASE_URL` | `--dart-define` → `lib/core/config/env.dart` | `http://10.0.2.2:5000/api` |
| `WEB_ORIGIN` (used in "copy post link") | `--dart-define` → `env.dart` | `https://babycare.babymasala.com` |
| Plain HTTP allowed | `android/app/src/debug/AndroidManifest.xml` (debug only) | on in debug, off in release |

**Demo login:** `01712345678`, code `123456`, coupon `BABYCARE`.

Checks:
- `flutter analyze` (clean).
- `flutter test` (22 unit tests; the live test is skipped).
- `flutter build apk --debug`.
- **Live API contract test** (backend must be running):
  `flutter test test/live_api_test.dart --dart-define=LIVE_API=http://127.0.0.1:5000/api`
  - Logs in, bootstraps, and PUTs every synced list back unchanged, proving the server accepts mobile's payloads.
  - On an unseeded database it signs up `mobile.contract.test@babycare.demo` once. Override that contact with `--dart-define=LIVE_CONTACT=...`.
  - Use `127.0.0.1`, not `localhost`: on Windows `localhost` can resolve to IPv6.

**Build notes**
- `android/gradle.properties` has `kotlin.incremental=false`. Without it, Kotlin compilation of plugins fails with "Could not close incremental caches", because the project is on `D:` and the pub cache is on `C:`.
- `google_fonts` is pinned to `^6.3.3`. Version 9 depends on the separate `material_ui` package, whose `TextTheme` is a different class from the one in Flutter 3.47's material library.
- **Impeller rendering rules.** The dev emulator (Android 17, x86_64) shows these Impeller bugs: widgets disappear or maroon streaks appear. Keep the UI working there:
  - Use no blurred `BoxShadow`; use borders or tonal fills instead.
  - Use no fade or opacity animations: no `AnimatedSwitcher`, and keep `CachedNetworkImage` fade at zero.
  - Keep Flutter's default page transitions.
  - Give bars that sit next to clipped avatars a solid background.
  - To check whether a glitch is Impeller's fault, run with `--no-enable-impeller`.
- The build warns that `flutter_image_compress_common` still uses the Kotlin Gradle Plugin. The warning is harmless for now; upgrade the plugin when a built-in-Kotlin version is released.

---

## 2. Architecture (mobile ↔ web equivalents)

| Concern | Web (`frontend/src`) | Mobile (`mobile/lib`) |
|---|---|---|
| HTTP wrapper, bearer token, 401 → logout | `services/api.ts` (`apiRequest`, `tokenStore`) | `core/api/api_client.dart`, `core/api/token_store.dart` (Android Keystore through `flutter_secure_storage`) |
| Error shape `{message, code}` | `ApiError` | `core/api/api_exception.dart` (`ApiException`) |
| All endpoint calls | `services/babyCareService.ts` | `data/services/baby_care_api.dart` (**1:1, same names**) |
| Types | `types.ts` | `data/models/*.dart` (hand-written `fromJson`/`toJson`, no codegen) |
| App state (all `useState` in App.tsx) | `App.tsx` | `state/app_data.dart` + `state/app_data_controller.dart` (Riverpod `Notifier`) |
| Auth flow (`authState`) | `App.tsx` + `babyCareService.getAuthState` | `state/session_controller.dart` (`AuthStage`) |
| Debounced saves (`useServerSync`, 600 ms) | `App.tsx` | `AppDataController._set` / `_save` (600 ms, same keys) |
| Navigation (`currentScreen`, `activeTab`, `activeTimelineTarget`) | `App.tsx` state | `core/router/app_router.dart` (go_router) + `features/shell/home_tab.dart` |
| Theme colours | Tailwind hex values | `core/theme/app_colors.dart` |
| Font | Hind Siliguri (Google Fonts) | `google_fonts` → `hindSiliguriTextTheme` |
| Icons | `lucide-react` | `lucide_icons_flutter` |

**State management:** Riverpod 3 · **Routing:** go_router · **HTTP:** dio · **Target:** Android only.

---

## 3. Screen parity

✅ = done · 🟡 = partial / differs (see notes) · ⬜ = not built

| # | Screen | Web file | Mobile file | API used | Status |
|---|---|---|---|---|---|
| 1 | Loading / error | `App.tsx` | `features/auth/loading_screen.dart` | `GET /bootstrap` | ✅ |
| 2 | Welcome | `components/auth/WelcomeScreen.tsx` | `features/auth/welcome_screen.dart` | – | ✅ |
| 3 | Login | `components/auth/LoginScreen.tsx` | `features/auth/login_screen.dart` | `POST /auth/request-otp` (login) | ✅ |
| 4 | Sign-up | `components/auth/SignUpScreen.tsx` | `features/auth/signup_screen.dart` | `POST /auth/request-otp` (signup) | ✅ |
| 5 | Code entry (6 boxes, 59 s resend) | `components/auth/LoginVerifyScreen.tsx` | `features/auth/verify_screen.dart` | `POST /auth/verify-otp` | ✅ |
| 6 | Membership activation + demo checkout | `components/auth/MembershipActivationScreen.tsx` | `features/auth/membership_screen.dart` | `POST /auth/activate-membership`, `POST /auth/demo-purchase` | ✅ |
| 7 | Header + 5 top tabs | `components/Header.tsx` | `features/shell/home_shell.dart` | – | 🟡 **bottom navigation** with a raised centre Home button; Friends moved under "আরও" (§6 M20) |
| 8 | Profile drawer | `components/profile/ProfileDrawer.tsx` | `features/shell/more_sheet.dart` ("আরও" sheet) | `POST /auth/activate-membership` | 🟡 replaced by the More sheet; adds Address, Settings, Orders, Notifications, Admin; coupon calls the API (§6) |
| 15b | Friends screen | `components/social/FriendsScreen.tsx` (a top tab on web) | `features/friends/friends_tab.dart` (`FriendsScreen`, route `/friends`) | `PUT /sync/friends` | 🟡 full screen opened from "আরও" |
| 9 | Community feed | `tabs/CommunityTab.tsx` | `features/community/community_tab.dart`, `post_card.dart` | `/posts*` | 🟡 adds pull-to-refresh and infinite scroll (§6) |
| 10 | Create / edit post | CommunityTab modal | `features/community/post_composer.dart` | `POST /posts`, `PATCH /posts/:id` | 🟡 image picker instead of URL field; label says "+৫" |
| 11 | Comments thread | CommunityTab modal | `features/community/comments_sheet.dart` | `GET/POST /posts/:id/comments` | 🟡 re-fetches comments when opened |
| 12 | Share | CommunityTab modal | `features/community/post_actions.dart` | – | 🟡 Android share sheet replaces the fake "share to feed" |
| 13 | My Baby (main, food chart, tips, tip detail) | `tabs/MyBabyTab.tsx` | `features/baby/my_baby_tab.dart` | `PUT /sync/children` | ✅ |
| 14 | Add / edit child | MyBabyTab modal | `features/baby/child_form_sheet.dart` | `PUT /sync/children` | 🟡 date picker and photo picker |
| 15 | Friends (3 sub-tabs) | `components/social/FriendsScreen.tsx` | `features/friends/friends_tab.dart` | `PUT /sync/friends` | ✅ |
| 16 | Rewards (points, rules, leaderboard, history) | `tabs/RewardsTab.tsx` | `features/rewards/rewards_tab.dart` | `GET /rewards/leaderboard` | ✅ |
| 17 | Redeem catalog + flow | RewardsTab | `features/rewards/redeem_catalog.dart` | `POST /rewards/redeem` | ✅ |
| 18 | Contests (active, mine, winners) + entry form | RewardsTab | `rewards_tab.dart`, `contest_entry_sheet.dart` | `POST /contests/:id/submissions` | 🟡 winners come from `contest.winners`; button shows the real reward; image picker |
| 19 | Shop grid, product detail, cart, checkout, success | `tabs/ShopTab.tsx` | `features/shop/*.dart` | `PUT /me/cart`, `POST /orders` | ✅ |
| 20 | My orders | – (no web screen) | `features/shop/orders_sheet.dart` | bootstrap `orders` | 🟡 mobile only |
| 21 | Recipes (search, age chips, detail, "buy") | `tabs/RecipesTab.tsx` | `features/recipes/recipes_screen.dart` | `POST /recipes/:id/save` | 🟡 "কিনুন" opens the product sheet directly |
| 22 | Messenger (list + chat + auto-reply) | `components/social/MessengerScreen.tsx` | `features/messenger/messenger_screen.dart` | `PUT /sync/conversations`, `PUT /sync/messages` | 🟡 opening a chat clears its unread count |
| 23 | User timeline (posts / about / photos, edit profile) | `components/social/UserTimelineScreen.tsx` | `features/timeline/user_timeline_screen.dart` | `PATCH /me`, `POST /posts` | 🟡 avatar and cover via picker; saves at once and refreshes |
| 24 | Ask Doctor (live doctors, booking, questions, follow-ups) | `components/doctor/AskDoctorScreen.tsx` | `features/doctor/ask_doctor_screen.dart` | `PUT /sync/doctorQuestions` | ✅ |
| 25 | Simulated call | `components/doctor/SimulatedCallScreen.tsx` | `features/doctor/simulated_call_screen.dart` | – | ✅ |
| 26 | Notifications | `components/NotificationModal.tsx` | `features/notifications/notifications_sheet.dart` | `POST /notifications/read-all` | ✅ |
| 27 | Admin console | `components/AdminModal.tsx` | `features/admin/admin_screen.dart` | `/admin/*` | 🟡 adds post status and entry moderation; real points rules |
| 28 | Settings & privacy | `components/profile/SettingsModal.tsx` (not reachable on web) | `features/profile/settings_screen.dart` | `PATCH /me` | 🟡 reachable on mobile; adds SMS, email and share-profile toggles |
| 29 | Address manager | `components/profile/AddressManagerModal.tsx` (not reachable on web) | `features/profile/address_manager_screen.dart` | `PATCH /me` | 🟡 reachable on mobile; adds edit |

The unused web components (`BottomNav.tsx`, `TopNavTabs.tsx`, `OnboardingModal.tsx`, `ProfileModal.tsx`, `PublicProfileModal.tsx`) are intentionally not ported.

---

## 4. Endpoints used by mobile

All calls are in `lib/data/services/baby_care_api.dart`. **Auth** column: 🔓 = no token needed.

| Method | Path | Dart function | Called from |
|---|---|---|---|
| POST 🔓 | `/auth/request-otp` | `requestOtp` | login, sign-up, resend |
| POST 🔓 | `/auth/verify-otp` | `verifyOtp` (stores token) | verify |
| GET | `/auth/me` | `me` | (available, unused) |
| POST | `/auth/activate-membership` | `activateMembership` | membership screen, drawer |
| POST | `/auth/demo-purchase` | `demoPurchaseMembership` | membership screen |
| GET | `/bootstrap` | `bootstrap` | start, pull-to-refresh, app resume, before synced edits |
| PATCH | `/me` | `updateProfile` | debounced user sync, edit profile (immediate) |
| PUT | `/me/cart` | `saveCart` | debounced cart sync |
| GET | `/notifications` | `notifications` | (available) |
| POST | `/notifications/read-all` | `markAllNotificationsRead` | notifications sheet |
| GET | `/posts?limit&before&topic` | `listPosts` | community infinite scroll |
| POST | `/posts` | `createPost` | composer |
| PATCH | `/posts/:id` | `updatePost` | composer (edit) |
| DELETE | `/posts/:id` | `deletePost` | post menu |
| POST | `/posts/:id/react` | `reactToPost` | like / reaction picker |
| POST | `/posts/:id/save` | `toggleSavePost` | post menu |
| POST | `/posts/:id/hide` | `hidePost` | post menu |
| POST | `/posts/:id/report` | `reportPost` | post menu |
| GET | `/posts/:id/comments` | `getComments` | comments sheet open |
| POST | `/posts/:id/comments` | `addComment` | comments sheet |
| POST | `/recipes/:id/save` | `toggleSaveRecipe` | recipes |
| GET | `/products` | `listProducts` | (available; the shop uses bootstrap) |
| GET | `/orders` | `listOrders` | (available) |
| POST | `/orders` | `placeOrder` | checkout |
| GET | `/rewards/leaderboard` | `getLeaderboard` | Rewards tab opened |
| POST | `/rewards/redeem` | `redeemGift` | redeem flow |
| POST | `/contests/:id/submissions` | `submitContestEntry` | contest entry |
| PUT | `/sync/:collection` | `syncCollection` | debounced sync (children, friends, conversations, messages, doctorQuestions) |
| GET | `/admin/overview` | `admin.overview` | admin |
| PATCH | `/admin/posts/:id` | `admin.setPostStatus` | admin (mobile only) |
| DELETE | `/admin/posts/:id` | `admin.deletePost` | admin |
| PATCH | `/admin/orders/:id` | `admin.updateOrderStatus` | admin |
| PATCH | `/admin/products/:id` | `admin.updateProduct` | admin |
| PATCH | `/admin/submissions/:id` | `admin.setSubmissionStatus` | admin (mobile only) |

---

## 5. Data models (Dart ↔ `types.ts`)

| Dart class (file) | TS type | Notes |
|---|---|---|
| `User`, `Address`, `NotificationPrefs`, `PrivacySettings` (`user.dart`) | `User` | `toProfilePatch()` sends exactly the fields `updateProfile` sends |
| `Post`, `Comment` (`community.dart`) | `Post`, `Comment` | `Comment.authorId` exists in the API and is used on mobile |
| `Recipe` (`recipe.dart`) | `Recipe` | |
| `Product`, `CartItem`, `Order`, `GiftItem`, `GiftRedemption`, `RewardTransaction`, `LeaderboardEntry` (`commerce.dart`) | same names | `Order` also has `subtotal`, `deliveryCharge`, `notes`, `paymentMethod` and admin-only `userId`; `types.ts` leaves these out |
| `Contest`, `ContestWinner`, `ContestSubmission` (`contest.dart`) | `Contest`, `ContestSubmission` | `Contest.reward` = `pointsReward ?? 50` (backend default) |
| `NotificationItem` (`notification_item.dart`) | `NotificationItem` | |
| `FriendUser`, `Conversation`, `Message` (`social.dart`) | same names | `toJson()` = the `PUT /sync` item shape |
| `Child`, `Doctor`, `DoctorQuestion`, `FollowUp` (`medical.dart`) | `Child`, `Doctor`, `DoctorQuestion` | Status constants `dqSubmitted`, `dqWaiting`, `dqAnswered`, `dqClosed` match the backend enum |
| `BootstrapData` (`bootstrap.dart`) | `BootstrapData` | |

Dates are Bengali display labels from the server (`"২ ঘণ্টা আগে"`, `"আজ"`), the same as on the web, so the client never re-formats them.

---

## 6. Mobile-only changes (web does not have these yet)

The user decided to fix these web gaps on mobile. Port them to the web when convenient and tick them off here.

| # | Change | Mobile file | Web change needed | Ported to web? |
|---|---|---|---|---|
| M1 | Settings screen reachable from the drawer (adds SMS, email and share-profile toggles) | `app_drawer.dart`, `settings_screen.dart` | add a button in `ProfileDrawer.tsx` that opens `SettingsModal` | ⬜ |
| M2 | Address manager reachable from the drawer, with edit | `app_drawer.dart`, `address_manager_screen.dart` | add a button that opens `AddressManagerModal` | ⬜ |
| M3 | Drawer coupon calls `POST /auth/activate-membership` | `app_drawer.dart` | `ProfileDrawer.handleActivateCoupon` only checks `'BABYCARE'` on the client | ⬜ |
| M4 | Admin button only when `user.isAdmin` | `home_shell.dart` | `Header.tsx` shows it to everyone | ⬜ |
| M5 | Post button says "+৫ পয়েন্ট" (the server gives +5, or +10 for video) | `post_composer.dart` | `CommunityTab.tsx` says "+২০" | ⬜ |
| M6 | Contest button shows the contest's real reward (`pointsReward ?? 50`) | `rewards_tab.dart` | `RewardsTab.tsx` hard-codes "+৫০" | ⬜ |
| M7 | Winners come from `contest.winners` (falls back to the web's hard-coded list) | `rewards_tab.dart` | `RewardsTab.tsx` | ⬜ |
| M8 | Photos picked from the camera or gallery, compressed, sent as `data:image/jpeg;base64,...` | `core/utils/image_data_url.dart` | the web still uses URL text fields. The web shows these data URLs fine, so nothing breaks. | ⬜ (optional) |
| M9 | Opening a chat clears its `unreadCount` | `messenger_screen.dart` | `MessengerScreen.tsx` never clears it | ⬜ |
| M10 | Timeline for a non-friend uses the avatar from their posts (web shows the viewer's own avatar) | `user_timeline_screen.dart` | `UserTimelineScreen.tsx` `resolvedFriend` fallback | ⬜ |
| M11 | Timeline matches posts by `authorId` when known (web matches by name) | `user_timeline_screen.dart`, `post_card.dart` | the web compares `authorName` | ⬜ |
| M12 | "My orders" sheet | `orders_sheet.dart` | no screen on the web | ⬜ |
| M13 | Admin: post status (approve/pending/reject) and contest-entry moderation; real points rules | `admin_screen.dart` | `AdminModal.tsx` | ⬜ |
| M14 | Community: pull-to-refresh and infinite scroll past the 100 bootstrap posts (`GET /posts?before=`) | `community_tab.dart` | the web loads only the bootstrap posts | ⬜ |
| M15 | Comments re-fetched (`GET /posts/:id/comments`) when the thread opens | `comments_sheet.dart` | the web uses bootstrap comments only | ⬜ |
| M16 | Food chart / recipe suggestions open that recipe's detail (web opens the recipe list) | `my_baby_tab.dart`, `recipes_screen.dart` | `MyBabyTab.onSelectRecipe` | ⬜ |
| M17 | Edit profile saves at once (not debounced) and re-bootstraps, so posts show the new name and avatar | `user_timeline_screen.dart` | the web relies on the debounced `PATCH /me` | ⬜ |
| M18 | Ages and counts use Bengali digits (`৯ মাস`), where the web shows Latin digits | `core/utils/bn_digits.dart` | cosmetic | ⬜ |
| M19 | "Save chart" shows a toast instead of `alert()` | `my_baby_tab.dart` | – | n/a |
| M20 | **Navigation redesign.** Bottom bar: মাই বেবি · রিওয়ার্ডস · **হোম** (raised gradient circle in the centre, gold ring when active) · শপ (cart badge) · আরও. "আরও" opens a sheet holding every drawer option: profile card (→ own timeline), points and child shortcuts, ফ্রেন্ডস, মেসেঞ্জার, ডাক্তার, রেসিপি, নোটিফিকেশন, আমার অর্ডার, পয়েন্ট ও গিফট, ঠিকানা, সেটিংস, অ্যাডমিন (admins only), membership coupon, logout. The top bar shows the avatar (→ own timeline), the wordmark or tab title, and the messenger and bell buttons. The drawer was removed. | `home_shell.dart`, `more_sheet.dart`, `home_tab.dart` | Optional: the web is desktop/mobile-web, so it can keep its top tabs | n/a |
| M21 | Modern visual pass: light app bars with maroon titles, 20 px cards, 14 px inputs and buttons, 28 px sheets with a grab handle, card-style notifications, segmented Friends sub-tabs. The palette is unchanged. | `app_theme.dart`, `common.dart`, screens | – | n/a |

Things deliberately kept **the same as the web** (demo behaviour):
- The long-press reaction picker sends the same like toggle for every emoji, because the API has no reaction types.
- Tip bookmarks are local only, because there is no endpoint.
- The food chart meals are hard-coded.
- The messenger auto-reply after 2 s is kept.
- The doctor reply text is canned.
- The call is simulated.
- The ৳50 delivery note in the redeem flow is kept.

---

## 7. Content copied from the web (not served by the API)

**If you change one copy, change the other.** It would be better to move these to the backend later (see §8).

| Content | Web source | Mobile copy |
|---|---|---|
| Age tips (`INITIAL_AGE_TIPS`) | `frontend/src/data/mockData.ts` | `lib/data/static/age_tips.dart` |
| Tips list (`INITIAL_TIPS`) | `frontend/src/tabs/MyBabyTab.tsx` | `lib/data/static/tips.dart` |
| Food chart meals and day names | `frontend/src/tabs/MyBabyTab.tsx` (inline JSX) | `lib/data/static/tips.dart` (`foodChartMeals`, `daysOfWeek`) |
| Shop categories `সব / হার্বস ও স্পাইস / কম্বো প্যাক` | `ShopTab.tsx` | `shop_tab.dart` |
| Recipe age filters | `RecipesTab.tsx` | `recipes_screen.dart` |
| Doctor question categories | `AskDoctorScreen.tsx` | `ask_doctor_screen.dart` |
| Address districts | `AddressManagerModal.tsx` | `address_manager_screen.dart` |
| Brand colours | Tailwind classes | `core/theme/app_colors.dart` |
| Business rules mirrored on the client (the server stays the authority) | `ShopTab.tsx` (delivery ৳60, free over ৳1000), `RewardsTab.tsx` (balance formula) | `data/models/commerce.dart` (`deliveryFor`, `pointsFor`), `state/app_data.dart` (`earnedPoints`, `spentPoints`) |

---

## 8. How sync works (and its limits)

**Two kinds of data:**

1. **Server-enforced actions.** Posts, likes, comments, saves, orders, redemptions, contest entries, membership and admin actions each call their own endpoint. The response (often with a `rewardTx`) updates local state. Both clients always agree on these after a refresh.
2. **Client-owned lists.** `user` (profile, addresses, settings), `cart`, `children`, `friends`, `conversations`, `messages` and `doctorQuestions`.
   - Any change is saved **600 ms after the last edit**. The **whole list** goes to `PUT /sync/:collection` (or `PATCH /me` / `PUT /me/cart`), the same as the web's `useServerSync`.
   - The server **replaces** the list, so **the last write wins**.

**Mobile measures to avoid overwriting web edits:**
- On **app resume** it re-runs `GET /bootstrap` (`app.dart` → `AppDataController.refresh`).
- When the app goes to the **background**, pending saves are flushed at once (`flush()`).
- **Before every refresh**, pending saves are flushed first, so local edits are not lost.
- **Before opening an editor** for a synced list (add/edit child, new doctor question, address manager), it re-fetches quietly (`refreshQuietly()`).
- **Pull-to-refresh** is available on every tab.

**Known limits** (both clients):
- There is no real-time push. Changes made on the web show up on mobile after resume or pull-to-refresh.
- There are no `updatedAt` or ETags. If both clients edit the same list within seconds, the later save wins.
- Friends and messages are per-user demo copies. They are not a real social graph, and messages do not reach the other person.

**Backend improvements that would help both clients** (not done; the backend is unchanged):
- Return `updatedAt` and accept `If-Match` on `PUT /sync/:collection`.
- Return ISO `createdAt` next to the Bengali labels.
- Serve age tips and tips from an endpoint.
- Add an upload endpoint (object storage) instead of base64 in JSON.

---

## 9. Change log

Add a dated entry for **every** mobile change that affects screens, API usage, models or shared content. Mark whether the web needs the same change.

| Date | Change | Files | Web follow-up? |
|---|---|---|---|
| 2026-10-17 | Bottom navigation with a centre Home circle, "আরও" More sheet (replaces the drawer), Friends as its own route, modern theme pass (§6 M20–M21). Impeller-safe: no blurred shadows, no fade/opacity animations (`AnimatedSwitcher`, image fade-in), no zoom page transitions, solid background behind the top bar. | `features/shell/*`, `friends_tab.dart`, `app_theme.dart`, `common.dart`, `net_image.dart`, `notifications_sheet.dart`, `messenger_screen.dart`, `admin_screen.dart`, `app_router.dart` | No (mobile-only UX) |
| 2026-10-17 | Welcome logo: replaced the blurred `BoxShadow` with a border. On the Android emulator's Impeller backend the blur made the heart, badge and wordmark disappear. `ApiClient` now `debugPrint`s the underlying `DioException` on network errors. | `welcome_screen.dart`, `api_client.dart` | No |
| 2026-10-16 | Initial Flutter app: all 29 screens/overlays in §3, the API client mirroring `babyCareService.ts`, Riverpod store with 600 ms debounced sync, resume refresh, image picker uploads, 22 unit tests | `mobile/**` | See §6 M1–M19 |

---

## 10. Checklist for future changes

- [ ] Did you add or change an endpoint? Update `baby_care_api.dart`, `babyCareService.ts`, `backend/README.md` and §4.
- [ ] Did you add a field to a model? Update the Dart model (`fromJson` + `toJson` if it's synced), `types.ts` and §5.
- [ ] Did you change copied content (§7)? Change both copies.
- [ ] Is it a mobile-only UX change? Add it to §6 with "Ported to web? ⬜".
- [ ] Add a row to §9.
- [ ] Run `flutter analyze` and `flutter test`.
