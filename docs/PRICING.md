# MedStudy — Subscription Plans

**Status:** LOCKED (adjust PKR amounts based on market research before launch)

---

## Plans

| Plan ID | Name | plan_type | Price (PKR/year) | Access |
|---------|------|-----------|------------------|--------|
| year-1 | Year 1 | YEAR_1 | 4,000 | Year 1 materials, exams, past papers |
| year-2 | Year 2 | YEAR_2 | 4,000 | Year 2 |
| year-3 | Year 3 | YEAR_3 | 4,000 | Year 3 |
| year-4 | Year 4 | YEAR_4 | 4,000 | Year 4 |
| year-5 | Year 5 | YEAR_5 | 4,000 | Year 5 |
| fcps-1 | FCPS Part 1 | FCPS_PART_1 | 6,000 | FCPS Part 1 library + mocks |
| fcps-2 | FCPS Part 2 | FCPS_PART_2 | 6,000 | FCPS Part 2 library + mocks |
| all-mbbs | All MBBS Years | ALL_MBBS | 15,000 | Years 1–5 |
| ultimate | Ultimate Bundle | ULTIMATE_BUNDLE | 25,000 | Everything including FCPS |

---

## RevenueCat Product Mapping

Create matching products in App Store Connect and Google Play Console. Map IDs in RevenueCat dashboard and `subscription_plans.revenuecat_product_id`.

---

## Manual Activation (Optional)

For JazzCash/Easypaisa bank transfers:

1. Student pays via bank/JazzCash
2. Sends proof via WhatsApp/support
3. Admin uses `POST /admin/subscriptions` to grant plan
4. User gets immediate access

---

## Refund Policy (Summary)

- 7-day refund window if no content downloaded (define in LEGAL.md)
- No refund after substantial usage
- App Store / Play Store refunds follow store policies

See [LEGAL.md](./LEGAL.md) for full terms.
