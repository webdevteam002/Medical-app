# Person 2 — Daily Work Schedule (Day 1–80)

**Parent doc:** [PERSON_2_APPS.md](./PERSON_2_APPS.md)  
**Format:** 16 weeks · Mon–Fri · 5 days/week = 80 working days

---

## Week 1 — Flutter + Admin scaffold

| Day | Tasks |
|-----|-------|
| **Day 1** | Create Flutter project in `mobile/`; folder structure (features, core, shared); add `go_router`, `dio`, `flutter_secure_storage`; configure Windows/macOS build targets |
| **Day 2** | Create Next.js admin in `admin/`; TypeScript; Tailwind; login page layout |
| **Day 3** | Flutter: login + register UI screens; form validation (responsive layout) |
| **Day 4** | Wire Flutter login to Person 1 `POST /auth/login`; store tokens securely |
| **Day 5** | Wire admin login; dashboard shell + sidebar navigation |

---

## Week 2 — Auth completion

| Day | Tasks |
|-----|-------|
| **Day 6** | Generate `deviceId` (`device_info_plus` + UUID); send `X-Device-Id` on all requests |
| **Day 7** | Flutter: register flow; persist login state; splash → home or login |
| **Day 8** | Admin: auth guard on all routes; redirect if not logged in |
| **Day 9** | API client wrapper: auto-attach token; refresh on 401 once |
| **Day 10** | **Gate 1 prep:** demo login to team; fix UI bugs |

---

## Week 3 — Session handling

| Day | Tasks |
|-----|-------|
| **Day 11** | Flutter: handle `SESSION_REVOKED` — show dialog + logout |
| **Day 12** | Flutter: home shell — bottom nav or drawer (Study, Exams, Profile) |
| **Day 13** | Admin: users list page — table from `GET /admin/users` |
| **Day 14** | Admin: ban user + reset device buttons with confirmation |
| **Day 15** | Profile screen: show email, subscription status placeholder |

---

## Week 4 — Navigation, admin & responsive polish

| Day | Tasks |
|-----|-------|
| **Day 16** | Flutter: empty states for home tabs; responsive layout breakpoints for Desktop |
| **Day 17** | Admin: dashboard stats cards (user count placeholder) |
| **Day 18** | Error handling UI: network error, wrong password |
| **Day 19** | Loading states on login and lists |
| **Day 20** | **Gate 1 complete:** two-phone device kick test with Person 1 |

---

## Week 5 — Content browse

| Day | Tasks |
|-----|-------|
| **Day 21** | Flutter: years list from `GET /years` |
| **Day 22** | Flutter: subjects list per year |
| **Day 23** | Flutter: materials list per subject (title, type, past paper badge) |
| **Day 24** | Admin: years/subjects CRUD pages |
| **Day 25** | Admin: material upload form — multipart to Person 1 API |

---

## Week 6 — PDF viewer

| Day | Tasks |
|-----|-------|
| **Day 26** | Integrate `pdfx` (or chosen viewer); open presigned URL from API |
| **Day 27** | Watermark overlay widget (user email + ID from profile) |
| **Day 28** | Android: `FLAG_SECURE` on PDF screen (`flutter_windowmanager`) |
| **Day 29** | iOS: screenshot detection listener. Desktop: setup OS screenshot block plugins |
| **Day 30** | **Gate 2 prep:** open real PDF from Person 3 upload |

---

## Week 7 — Offline downloads

| Day | Tasks |
|-----|-------|
| **Day 31** | Download PDF to app private directory (not gallery) |
| **Day 32** | Encrypted storage for downloaded files (key from secure storage) |
| **Day 33** | Offline materials list screen — show downloaded items |
| **Day 34** | Open offline PDF in same secure viewer |
| **Day 35** | Admin: publish/unpublish toggle on materials |

---

## Week 8 — Search & bookmarks

| Day | Tasks |
|-----|-------|
| **Day 36** | Search bar on materials list; debounced API call |
| **Day 37** | Bookmark add/remove API integration |
| **Day 38** | Bookmarks screen in Flutter |
| **Day 39** | Pull-to-refresh on lists |
| **Day 40** | Blur/hide PDF when app goes to background (both platforms) |

---

## Week 9 — Exam list & start

| Day | Tasks |
|-----|-------|
| **Day 41** | Flutter: exams list by subject/year |
| **Day 42** | Exam detail screen: duration, question count, start button |
| **Day 43** | Start exam API; navigate to exam session screen |
| **Day 44** | Question display: stem, options, select answer |
| **Day 45** | Countdown timer — persistent across questions |

---

## Week 10 — Exam UI (part 2)

| Day | Tasks |
|-----|-------|
| **Day 46** | Question palette grid (answered / flagged / current) |
| **Day 47** | Mark for review; skip; previous/next navigation |
| **Day 48** | Submit confirmation dialog; call submit API |
| **Day 49** | Results screen: score, %, time taken |
| **Day 50** | **Gate 3 prep:** full exam with Person 1 grading API |

---

## Week 11 — Exam review & admin questions

| Day | Tasks |
|-----|-------|
| **Day 51** | Review screen: each question + explanation + correct answer |
| **Day 52** | Exam history list |
| **Day 53** | Admin: question create/edit form |
| **Day 54** | Admin: CSV import UI — upload file, show success/errors |
| **Day 55** | Admin: exam builder — pick questions, set duration, publish |

---

## Week 12 — Payments

| Day | Tasks |
|-----|-------|
| **Day 56** | Integrate RevenueCat `purchases_flutter` |
| **Day 57** | Paywall screen: show plans from store + entitlement check |
| **Day 58** | Lock content screens when no subscription |
| **Day 59** | Admin: subscriptions list + manual grant form |
| **Day 60** | **Gate 4 prep:** test purchase flow (sandbox) |

---

## Week 13 — Beta builds

| Day | Tasks |
|-----|-------|
| **Day 61** | Android release APK/AAB; Windows/macOS desktop release builds |
| **Day 62** | iOS TestFlight build (Apple Developer account) |
| **Day 63** | Point app to Person 1 staging API |
| **Day 64** | Send builds to Person 3; list all screen names for their audit |
| **Day 65** | Fix P0 bugs from Person 3 first test pass |

---

## Week 14 — Beta fixes

| Day | Tasks |
|-----|-------|
| **Day 66** | Fix content display bugs Person 3 reported |
| **Day 67** | Fix exam UX issues from student beta |
| **Day 68** | Performance: lazy load lists; image caching for question images |
| **Day 69** | Admin UX improvements from Person 3 feedback |
| **Day 70** | **Gate 5:** stable beta build for 20 students |

---

## Week 15 — Design polish (from Person 3)

| Day | Tasks |
|-----|-------|
| **Day 71** | Receive Person 3 Figma v2 + change checklist |
| **Day 72** | Apply theme: colors, typography, spacing |
| **Day 73** | Polish: onboarding, empty states, loading skeletons |
| **Day 74** | Polish: exam timer, results, review screens |
| **Day 75** | Polish: admin tables and upload feedback |

---

## Week 16 — Store launch

| Day | Tasks |
|-----|-------|
| **Day 76** | Add Person 3 store screenshots to listings |
| **Day 77** | Submit Google Play production release |
| **Day 78** | Submit App Store for review |
| **Day 79** | Point production build to Person 1 prod API |
| **Day 80** | **Gate 7 — Launch:** apps live; monitor crashes (Firebase Crashlytics optional) |

---

## Daily routine (every day)

- [ ] Test on **Mobile (Android/iOS)** and **Desktop (macOS/Windows)** before EOD
- [ ] Note any missing API endpoints for Person 1
- [ ] Push code; tag Person 3 when admin/upload ready for content
