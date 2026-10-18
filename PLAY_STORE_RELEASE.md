# Google Play release checklist — Baby Care by Baby Masala

Package: `com.nuktatechnology.baby_care` · Publisher: Nukta Technologies · Support: smnr7770@gmail.com

Do the steps in order. The listing points at web pages and a live API, so **deploy the backend and the web site before you submit.**

---

## 1. Deploy first (server)

1. **Backend** (`backend/`): deploy the current code and set these on the server:
   - `DEMO_MODE=false`. It is off when unset, but set it explicitly anyway.
   - `ADMIN_CONTACTS=smnr7770@gmail.com`
   - `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `EMAIL_FROM`. With Gmail, use an **App Password**. `EMAIL_FROM` only shows `support@babymasalabd.com` if that address is a verified "Send mail as" alias of the Gmail account; otherwise mail comes from the Gmail address.
   - `SMS_ENABLED=false`
   - `REVIEW_CONTACT` and `REVIEW_OTP`, copied from your local `backend/.env`.
   - Remove `DEMO_OTP` and `MEMBERSHIP_COUPON` if they are set.
   - Run `npm install`, because there are new dependencies: nodemailer, helmet and express-rate-limit.
2. **Remove the demo data** from the production database:
   - Run `npm run prune-demo` (a dry run that lists what it would delete), check the list, then run `npm run prune-demo -- --apply`.
   - This deletes the demo admin `01712345678`, the five demo mothers and the sample feed.
   - Never run `npm run seed:demo` against production.
3. **Web** (`frontend/`): run `npm run build` and upload `dist/`. Then check that these open:
   - https://babymasalabd.com/privacy-policy.html
   - https://babymasalabd.com/terms.html
   - https://babymasalabd.com/delete-account.html
4. **Smoke test the live API:**
   - Sign up in the release APK with a real email and check that the code arrives. Look in the spam folder too.
   - Then delete that test account from Settings.

## 2. Build

```bash
cd mobile
# bump the build number for every upload: version: 1.0.0+1 -> 1.0.0+2 ...
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

- Upload `build/app/outputs/bundle/release/app-release.aab`.
- Keep the matching `build/symbols/` folder; it is needed to read obfuscated crash stack traces.
- Signing uses `android/key.properties` and `android/upload-keystore.jks`.
  - **Back up both files** somewhere safe outside this PC, for example a password manager plus an encrypted drive. Every future update must be signed with this key.
  - Both files are gitignored. Never commit them.
- In Play Console, accept **Play App Signing**. Google then holds the app signing key, and a lost upload key can be reset.
- To check the bundle's signature:

```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab   # Owner: CN=Nukta Technologies
```

## 3. Store listing

| Field | Value |
|---|---|
| App name | Baby Care by Baby Masala |
| Short description (bn) | শিশুর পুষ্টি, বয়সভিত্তিক খাবারের চার্ট, রেসিপি ও মায়েদের কমিউনিটি। |
| Short description (en) | Baby food charts, recipes, parenting tips and a community for mothers. |
| Category | Parenting |
| Contact email | smnr7770@gmail.com |
| Website | https://babymasalabd.com |
| Privacy policy | https://babymasalabd.com/privacy-policy.html |

**Full description (bn):**

> বেবি কেয়ার বাই বেবি মসলা: বাংলাদেশের মায়েদের জন্য একটি ফ্রি অ্যাপ।
> • শিশুর বয়স অনুযায়ী খাবারের চার্ট ও প্যারেন্টিং টিপস
> • সহজ ও পুষ্টিকর রেসিপি
> • মায়েদের কমিউনিটি: অভিজ্ঞতা শেয়ার করুন, প্রশ্ন করুন
> • Baby Masala-র পণ্য অর্ডার করুন (ক্যাশ অন ডেলিভারি)
> • পোস্ট, কমেন্ট ও কেনাকাটায় পয়েন্ট জিতে গিফট নিন, কনটেস্টে অংশ নিন
>
> সতর্কতা: অ্যাপের তথ্য সাধারণ জ্ঞানের জন্য, এটি চিকিৎসা পরামর্শের বিকল্প নয়।

**Full description (en):**

> Baby Care by Baby Masala is a free app for mothers in Bangladesh:
> • age-based baby food charts and parenting tips
> • simple, nutritious recipes
> • a community of mothers to share experiences and ask questions
> • order Baby Masala products with cash on delivery
> • earn points for posts, comments and purchases, redeem gifts and join contests
>
> Note: the information in the app is general guidance, not medical advice.

**Graphics you still need to make:**
- App icon, 512×512 PNG: use `assets/images/logo.png` (it is already 512×512).
- Feature graphic, 1024×500 PNG/JPG.
- At least 2 phone screenshots (1080×1920 recommended), for example Home feed, My Baby, Recipes, Shop and Rewards. Don't show real users' personal data.

## 4. App content (Policy → App content)

| Section | Answer |
|---|---|
| **Privacy policy** | https://babymasalabd.com/privacy-policy.html |
| **Ads** | No, the app contains no ads |
| **App access** | "All or some functionality is restricted." Add instructions: *Tap "লগইন করুন", enter email `<REVIEW_CONTACT>`, tap "কোড পাঠান", then enter code `<REVIEW_OTP>`.* The values are in `backend/.env`. On first use, choose "অ্যাকাউন্ট খুলুন" (sign up) with the same email and code, or create the account yourself before submitting. |
| **Content rating** | Fill in the IARC questionnaire honestly: users can interact and share user-generated content (posts, comments, photos); physical goods can be bought; no violence, sexual content, gambling or drugs. |
| **Target audience** | **18 and over only.** The app is for parents, not children. Do not opt into the Families program. |
| **News app** | No |
| **COVID-19 apps** | No |
| **Data safety** | See section 5 |
| **Government app** | No |
| **Financial features** | None |
| **Health apps** | If asked, the app offers general nutrition and parenting information. It is not a medical device, offers no diagnosis or treatment, and shows a medical disclaimer (About screen, Terms, My Baby food chart). |
| **Advertising ID** | No. The app does not use it, and the merged manifest has no `AD_ID` permission. |

## 5. Data safety form

**Overview answers:**
- Does the app collect or share user data? **Yes.**
- Is all data encrypted in transit? **Yes** (HTTPS only; release builds block cleartext).
- Can users request deletion? **Yes.** Deletion URL: https://babymasalabd.com/delete-account.html. The app also has Settings → অ্যাকাউন্ট মুছে ফেলুন.
- Data shared with third parties? **No.** MongoDB Atlas, Cloudinary and Gmail SMTP are service providers acting on our behalf, which Play does not count as "sharing".

**Data types collected.** None of them are shared, and none are processed ephemerally.

| Category → type | Required? | Purposes |
|---|---|---|
| Personal info → Name | Required | App functionality, Account management |
| Personal info → Email address | Required | App functionality, Account management |
| Personal info → Phone number | Optional (delivery) | App functionality |
| Personal info → Address | Optional (delivery) | App functionality |
| Personal info → Other info (bio, area, date of birth, child's name and date of birth) | Optional | App functionality |
| Health and fitness → Health info (child allergies) | Optional | App functionality |
| Photos and videos → Photos | Optional | App functionality |
| Photos and videos → Videos | Optional | App functionality |
| Financial info → Purchase history (orders, gift redemptions) | Optional | App functionality |
| App activity → Other user-generated content (posts, comments, contest entries, complaints) | Optional | App functionality |

**Not collected:** location, contacts, messages (SMS/email), audio, files and docs, calendar, web browsing, app interactions or analytics, crash logs, diagnostics, device or other IDs.

## 6. Release

1. Go to **Testing → Internal testing**, create a release, upload the `.aab`, and add your own Gmail as a tester.
2. Install it from the Play testing link and run through the app: sign up with the email code → Home, My Baby, Recipes, Shop (COD order), Rewards → Settings → Privacy, Terms, About and Licenses → delete the test account.
3. New personal developer accounts must run a **closed test with at least 12 testers for 14 days** before production access. Organisation accounts are exempt. Plan for this.
4. Go to **Production → Create release**, upload the same or a newer `.aab` (higher build number), and roll out.

## 7. Before every later update

- Bump `version:` in `pubspec.yaml`; the `+N` build number must always increase.
- Update `legalUpdated` in `lib/data/static/legal_texts.dart` and the web pages if the policy text changes, and keep both in sync.
- Run `flutter analyze` and `flutter test`, then build the app bundle with the same upload key.
