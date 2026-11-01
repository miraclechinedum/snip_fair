# Backend Handoff: Paying Payment Requests by Card (Option A)

> Updated: November 1, 2026
> Source of truth: `sinpfair_laravel_app/docs/PAYMENT_REQUEST_CARD_PAYMENT_OPTION_A.md`
> Status: implemented in the Flutter app. No backend change is required for this flow.

This replaces the earlier version of this document, which recommended a native card checkout on `/pay`. That recommendation is withdrawn.

---

## 1. Selected architecture

A card payment for a payment request is **two stages, each confirmed by the backend**. The request is paid only when stage 2 succeeds.

| Stage | Calls | Effect |
|---|---|---|
| 1. Card top-up | `POST /api/payment/topup`, then `GET /api/customer/payment/peach/{deposit_id}/status` | Credits the card payment to the customer's **wallet**, once. Does not pay the request. |
| 2. Wallet payment | `POST /api/payment-requests/{id}/pay` with no body | Debits the wallet, credits the stylist, marks the request `paid`, exactly once. |

**Do not enable the native payment-request card flow.** That means `POST /pay` with `{"payment_method": "card"}`, its checkout, and its card settlement/webhook path. Keep `PEACH_PAYMENT_REQUEST_CARD_ENABLED=false`. The app never sends `payment_method: card`. With the flag off, the backend answers `422 payment_method_unavailable`.

## 2. The three API calls

### 2.1 `POST /api/payment/topup`

Request: `{"type": "topup", "amount": <num>}`. `amount` must be greater than 0.

What the app sends as `amount`:
- **Card chosen:** the request's full `total_amount`. The contract says to top up at least the outstanding amount.
- **Wallet chosen but too low:** exactly the `shortfall` from the backend's `insufficient_wallet_balance` response, after the customer confirms it on a summary. The app never derives this amount by its own arithmetic.

| HTTP | Body | App behaviour |
|---|---|---|
| 200 | `{status: true, processor, deposit_id: <int>, checkoutId, redirectUrl}` | Opens `redirectUrl` in the Peach checkout and keeps `deposit_id`. |
| 400 | `{status: "false", message}` (string `"false"`: card collection disabled) | Shows the message. |
| 400 | `{status: false, message}` | Shows the message. |
| 422 | `{message, errors}` | Shows the message. |
| 401 / 404 / 5xx | — | Shows a generic "Unable to start payment". |

Each call is a **new card charge**. The app makes another one for the same payment only after the previous top-up ended `failed` or `cancelled`.

### 2.2 `GET /api/customer/payment/peach/{deposit_id}/status`

**Top-up success = HTTP 200 and `status == "successful"`.** Nothing else counts.

| Response | App behaviour |
|---|---|
| 200 `successful` | Verified. Proceeds to stage 2. |
| 200 `pending` | Keeps the deposit and polls with back-off; Check Payment Status stays available. |
| 200 `failed` / `cancelled` | Ends the attempt. The customer may start a new one. |
| 503 `unknown` (either body) | Keeps the deposit and checks again later. Never success, and never a reason to start a second top-up. |
| 404 `Payment not found` / 422 not verifiable | Ends the attempt. The customer is told the money will appear in the wallet if they were charged. |

### 2.3 `POST /api/payment-requests/{id}/pay`

No body (wallet). The request is shown as paid **only** on HTTP 200 with `code == "paid"`. The app reacts to the `code` field, not the message text:

| HTTP | `code` | App behaviour |
|---|---|---|
| 200 | `paid` | Success. Refreshes the request and the wallet. |
| 400 | `insufficient_wallet_balance` | Shows the backend's `shortfall` and offers to add exactly that by card, or to retry. |
| 400 | `already_paid` | Re-reads `GET /payment-requests/{id}`; treated as success only if that says `paid`. |
| 400 | `payment_request_not_payable`, `payment_request_expired` | Ends the attempt with the backend message. |
| 403 | `not_payer` | Ends the attempt with the backend message. |
| 409 | `card_payment_in_progress` | Shows the message; retryable. |
| 422 | `unsupported_payment_method`, `payment_method_unavailable` | Shows the message. Not expected: the app sends no body. |
| 500 | `payment_failed` | Rolled back; retryable. |

## 3. Meaning of `settled`

`settled` is `true` only on the **one** status call that credited the wallet. It is `false` on every repeat poll, and also on the first poll if Peach's webhook credited the wallet first. The app therefore **ignores `settled`** when deciding whether a top-up succeeded.

## 4. Recovery: top-up succeeded but `/pay` did not

The money is in the customer's wallet and nothing is lost.
- **Retryable failures** (`payment_failed`, `card_payment_in_progress`, network errors): the card shows "Your card payment succeeded and the money is in your wallet, but this request is not paid yet" with **Retry Payment**. Retrying calls `/pay` only, never another top-up. `/pay` is safe to retry because a request can be paid only once.
- **Insufficient balance:** shows the backend `shortfall`. The customer can add exactly that amount by card (a new top-up they confirm) or retry once the wallet holds enough.
- **Request no longer payable** (cancelled, expired, not the payer): the attempt ends, the explanation says the money stays in the wallet, and no refund is needed.

The app saves the unresolved deposit locally per customer: request ID, deposit ID, stage and time, nothing else. If the app is killed mid-payment, the next launch re-checks that deposit and continues to `/pay` without charging the card again. Logout clears these records.

## 5. Why pending and unknown are never success

A pending or unknown top-up may still complete or fail. Treating it as paid could mark a request paid that the wallet can't cover. Starting a fresh top-up could charge the card twice, since both charges would land in the wallet. So the app keeps the deposit, polls with bounded back-off (about 3 minutes), and offers **Check Payment Status** until a definitive answer arrives.

## 6. Remaining backend follow-ups

1. **Run the `payment_request_payments` migrations wherever `/pay` is served** (`2026_10_15_100000`–`100004`). `PaymentRequestLedger::payFromWallet` reads that table to detect `card_payment_in_progress`, and without it `/pay` returns 500.
2. **Keep the native card flow disabled** (see section 1).
3. **Optional consistency fix:** `PaymentController::initiate` returns `status: "false"` as a string in one error. The app tolerates it, but a boolean would match the other responses.
4. **For awareness (appointments):** the appointment settlement also returns `successful` with `settled: false` on repeat polls. The app's booking flow still requires `settled == true` and so can report "pending" when the webhook settled first. That is an app-side follow-up, not a backend bug.
