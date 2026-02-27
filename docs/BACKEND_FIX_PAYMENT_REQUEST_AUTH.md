# Backend Fix: Payment Request Authorization (403)

> Date: February 27, 2026
> Priority: **Critical** — Customers cannot view payment requests in chat

---

## Problem

When a **customer (payer)** tries to view a payment request in the chat conversation, the API returns:

```
GET /api/payment-requests/1
Status: 403
{"message":"You are not authorized to view this payment request."}
```

The customer is the `payer` on the payment request, but the authorization check only allows the `requester` (stylist) to view it.

---

## Root Cause

The authorization logic in the `show` method (either in `PaymentRequestController` or `PaymentRequestPolicy`) only checks `requester_id` against the authenticated user, but does **not** check `payer_id`.

---

## Fix

### Option A: If using a Policy (`PaymentRequestPolicy.php`)

```php
public function view(User $user, PaymentRequest $paymentRequest): bool
{
    // Both the requester (stylist) AND the payer (customer) should be able to view
    return $user->id === $paymentRequest->requester_id
        || $user->id === $paymentRequest->payer_id;
}
```

### Option B: If using inline authorization in Controller (`PaymentRequestController.php`)

```php
public function show(PaymentRequest $paymentRequest)
{
    // BEFORE (broken):
    // if ($paymentRequest->requester_id !== auth()->id()) {
    //     abort(403, 'You are not authorized to view this payment request.');
    // }

    // AFTER (fixed):
    if ($paymentRequest->requester_id !== auth()->id()
        && $paymentRequest->payer_id !== auth()->id()) {
        abort(403, 'You are not authorized to view this payment request.');
    }

    return response()->json([
        'data' => new PaymentRequestResource($paymentRequest),
    ]);
}
```

---

## Audit Other Endpoints

Apply the same dual-check (`requester_id` OR `payer_id`) to **all** payment request endpoints that use authorization:

| Endpoint                                       | Who should access                      |
| ---------------------------------------------- | -------------------------------------- |
| `GET /api/payment-requests/{id}`               | requester OR payer                     |
| `POST /api/payment-requests/{id}/accept`       | payer only                             |
| `POST /api/payment-requests/{id}/decline`      | payer only                             |
| `POST /api/payment-requests/{id}/pay`          | payer only                             |
| `POST /api/payment-requests/{id}/cancel`       | requester only                         |
| `GET /api/conversations/{id}/payment-requests` | either participant in the conversation |

Make sure the **view/show** action allows both parties while the **action** endpoints (accept/decline/pay/cancel) remain restricted to the correct role.

---

## How to Verify

1. Login as **customer** (payer)
2. Call `GET /api/payment-requests/1` with the customer's Bearer token
3. Should return `200` with the full payment request object
4. The Flutter app will then render the payment request card in the chat
