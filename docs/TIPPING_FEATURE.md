# Tipping Feature — Flutter Integration Guide

> Backend: Laravel 12 · Staging: `https://appupdate.snipfair.com`  
> Auth: Laravel Sanctum (Bearer token in `Authorization` header)

---

## 1. Overview

Customers can tip a stylist **once per appointment** after the service has started (`confirmed`) or been completed (`completed`). The tip is debited from the customer's wallet and credited directly to the stylist's wallet. Both parties receive a `tip` transaction entry in their history.

---

## 2. Endpoint

```
POST /api/customer/appointment/{appointmentId}/tip
```

### Headers

| Header          | Value                    |
| --------------- | ------------------------ |
| `Authorization` | `Bearer {customerToken}` |
| `Content-Type`  | `application/json`       |
| `Accept`        | `application/json`       |

### Path Parameter

| Parameter       | Type  | Description                   |
| --------------- | ----- | ----------------------------- |
| `appointmentId` | `int` | The appointment's database ID |

### Request Body

```json
{
    "amount": 50.0
}
```

| Field    | Type      | Validation             |
| -------- | --------- | ---------------------- |
| `amount` | `numeric` | Required · min: `0.01` |

---

## 3. Responses

### 200 — Success

```json
{
    "success": true,
    "message": "Tip sent successfully. Thank you for appreciating your stylist!",
    "tip_amount": 50.0,
    "new_wallet_balance": 249.5
}
```

### 400 — Too Early to Tip (wrong appointment status)

Appointment must be `confirmed` or `completed`.

```json
{
    "success": false,
    "message": "You can only tip after the appointment has started."
}
```

### 400 — Insufficient Wallet Balance

```json
{
    "success": false,
    "message": "Insufficient wallet balance to send this tip.",
    "wallet_balance": 30.0
}
```

### 409 — Already Tipped

Only one tip is allowed per appointment.

```json
{
    "success": false,
    "message": "You have already tipped for this appointment."
}
```

### 401 — Unauthenticated

Token missing or expired. Redirect user to login.

### 404 — Appointment Not Found

Appointment does not belong to this customer.

### 422 — Validation Error

```json
{
    "message": "The amount field is required.",
    "errors": {
        "amount": ["The amount field is required."]
    }
}
```

---

## 4. Database Changes

### `appointments` table (two new nullable columns)

| Column       | Type                    | Description                                        |
| ------------ | ----------------------- | -------------------------------------------------- |
| `tip_amount` | `decimal(8,2)` nullable | Amount the customer tipped                         |
| `tipped_at`  | `timestamp` nullable    | When the tip was sent; `null` means not yet tipped |

**Logic rule:** `tipped_at !== null` means the appointment has been tipped. Check this field to show/hide the tip button.

### `transactions` table (ENUM extended)

The `type` column now includes `'tip'` alongside existing values:

```
'payment' | 'earning' | 'refund' | 'withdraw' | 'topup' | 'subscription' | 'tip' | 'other'
```

---

## 5. Dart Models

### `TipRequest`

```dart
class TipRequest {
  final double amount;
  TipRequest({required this.amount});

  Map<String, dynamic> toJson() => {'amount': amount};
}
```

### `TipResponse`

```dart
class TipResponse {
  final bool success;
  final String message;
  final double tipAmount;
  final double newWalletBalance;

  TipResponse({
    required this.success,
    required this.message,
    required this.tipAmount,
    required this.newWalletBalance,
  });

  factory TipResponse.fromJson(Map<String, dynamic> json) => TipResponse(
        success: json['success'] as bool,
        message: json['message'] as String,
        tipAmount: (json['tip_amount'] as num).toDouble(),
        newWalletBalance: (json['new_wallet_balance'] as num).toDouble(),
      );
}
```

### Extended `Appointment` model fields

Add these fields to your existing `Appointment` Dart class:

```dart
final double? tipAmount;     // null = not tipped yet
final DateTime? tippedAt;    // null = not tipped yet

// Convenience helper
bool get hasBeenTipped => tippedAt != null;

// Deserialise additions inside fromJson():
tipAmount: json['tip_amount'] != null
    ? (json['tip_amount'] as num).toDouble()
    : null,
tippedAt: json['tipped_at'] != null
    ? DateTime.parse(json['tipped_at'] as String)
    : null,
```

### `TransactionType` enum extension

```dart
enum TransactionType {
  payment,
  earning,
  refund,
  withdraw,
  topup,
  subscription,
  tip,      // ← new
  other;

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionType.other,
    );
  }

  String get displayLabel {
    return switch (this) {
      TransactionType.tip    => 'Tip',
      TransactionType.topup  => 'Top-Up',
      TransactionType.payment  => 'Payment',
      TransactionType.earning  => 'Earning',
      TransactionType.refund   => 'Refund',
      TransactionType.withdraw => 'Withdrawal',
      TransactionType.subscription => 'Subscription',
      TransactionType.other  => 'Other',
    };
  }
}
```

---

## 6. Service Layer

```dart
class TipException implements Exception {
  final String message;
  final String type; // 'already_tipped' | 'insufficient_balance' | 'too_early' | 'unknown'
  final double? walletBalance; // present when type == 'insufficient_balance'

  TipException({required this.message, required this.type, this.walletBalance});
}

class AppointmentService {
  final Dio _dio; // your configured Dio instance with base URL + auth interceptor

  Future<TipResponse> sendTip({
    required int appointmentId,
    required double amount,
  }) async {
    try {
      final response = await _dio.post(
        '/customer/appointment/$appointmentId/tip',
        data: TipRequest(amount: amount).toJson(),
      );
      return TipResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final body = e.response?.data as Map<String, dynamic>?;
      final message = body?['message'] as String? ?? 'Something went wrong.';
      final statusCode = e.response?.statusCode;

      if (statusCode == 409) {
        throw TipException(message: message, type: 'already_tipped');
      }
      if (statusCode == 400) {
        final walletBalance = body?['wallet_balance'] != null
            ? (body!['wallet_balance'] as num).toDouble()
            : null;
        final type = walletBalance != null ? 'insufficient_balance' : 'too_early';
        throw TipException(message: message, type: type, walletBalance: walletBalance);
      }
      throw TipException(message: message, type: 'unknown');
    }
  }
}
```

---

## 7. UI Integration

### Show/hide the Tip button

The tip button should be visible **only** when both conditions are true:

- Appointment status is `confirmed` OR `completed`
- `appointment.hasBeenTipped` is `false` (i.e. `tipped_at == null`)

```dart
bool get shouldShowTipButton {
  final tippableStatuses = {'confirmed', 'completed'};
  return tippableStatuses.contains(appointment.status) &&
      !appointment.hasBeenTipped;
}
```

Once a tip is sent successfully, update the local appointment object with the returned `tip_amount` and set `tipped_at` to `DateTime.now()` so the button disappears immediately without a full refresh.

### Tip Amount Dialog

```dart
Future<double?> showTipDialog(BuildContext context, double walletBalance) {
  final controller = TextEditingController();
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 24,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Send a Tip', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Wallet balance: R${walletBalance.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Tip amount (R)',
            prefixText: 'R ',
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            final value = double.tryParse(controller.text.trim());
            if (value != null && value > 0) Navigator.pop(context, value);
          },
          child: const Text('Send Tip'),
        ),
        const SizedBox(height: 16),
      ]),
    ),
  );
}
```

### Sending the tip (widget handler)

```dart
Future<void> onTipButtonPressed(BuildContext context) async {
  final amount = await showTipDialog(context, currentWalletBalance);
  if (amount == null) return;

  try {
    final result = await appointmentService.sendTip(
      appointmentId: appointment.id,
      amount: amount,
    );

    // Update local state so button disappears immediately
    setState(() {
      appointment = appointment.copyWith(
        tipAmount: result.tipAmount,
        tippedAt: DateTime.now(),
      );
      currentWalletBalance = result.newWalletBalance;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  } on TipException catch (e) {
    String userMessage = e.message;
    if (e.type == 'insufficient_balance' && e.walletBalance != null) {
      userMessage = 'Insufficient balance (R${e.walletBalance!.toStringAsFixed(2)} available).';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(userMessage), backgroundColor: Colors.red),
    );
  }
}
```

---

## 8. Transaction History Rendering

When displaying the wallet transaction list, handle `TransactionType.tip` entries:

```dart
// Customer side — debit
// transaction.description == "Tip sent to {stylist name} for appointment #{booking_id}"

// Stylist side — credit
// transaction.description == "Tip received from {customer name} for appointment #{booking_id}"

Widget buildTransactionTile(Transaction tx) {
  final isTip = tx.type == TransactionType.tip;
  return ListTile(
    leading: Icon(
      isTip ? Icons.volunteer_activism : Icons.receipt_long,
      color: isTip ? Colors.amber : null,
    ),
    title: Text(tx.description ?? tx.type.displayLabel),
    subtitle: Text(tx.createdAt.toLocal().toString()),
    trailing: Text(
      'R${tx.amount.toStringAsFixed(2)}',
      style: TextStyle(
        // Customer perspective: tip is a debit (red)
        // Stylist perspective: tip is a credit (green)
        color: tx.type == TransactionType.tip
            ? Colors.amber
            : Colors.green,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
```

---

## 9. Push Notification (Stylist)

The stylist receives a push notification immediately after a tip is sent:

| Field | Value                                      |
| ----- | ------------------------------------------ |
| Title | `You received a tip! 🎁`                   |
| Body  | `{CustomerName} sent you a R{amount} tip.` |

No action is required from the stylist — it is informational only.

---

## 10. Appointment Status State Machine

| Status       | Can tip? | Notes                                 |
| ------------ | -------- | ------------------------------------- |
| `processing` | ✗        | Deposit payment pending               |
| `pending`    | ✗        | Awaiting stylist approval             |
| `approved`   | ✗        | Stylist approved, not yet started     |
| `confirmed`  | ✓        | Meetup verified — service in progress |
| `completed`  | ✓        | Service finished                      |
| `canceled`   | ✗        | Appointment was rejected/canceled     |
| `escalated`  | ✗        | Under dispute                         |

---

## 11. Quick Reference

```
POST /api/customer/appointment/{id}/tip
Body:  { "amount": 50.00 }
Auth:  Bearer {customerToken}

200 → { success, message, tip_amount, new_wallet_balance }
400 → too early OR insufficient balance (+ wallet_balance field)
409 → already tipped
422 → validation error (amount missing/invalid)
```
