# Payment Request Feature - API Documentation

> Generated: February 22, 2026  
> Backend: Laravel 12 (Snipfair)  
> Frontend: Flutter (Dart)  
> Purpose: Reference for Flutter mobile app integration

---

## Feature Overview

Payment Requests allow **stylists** to request additional payments from **customers** within the chat interface. The request appears as a special message type in the conversation.

### Flow

1. Stylist creates a payment request in a conversation
2. Customer receives it as a special message in chat (with push notification)
3. Customer can: **Accept**, **Decline**, or **Pay directly**
4. Payment is processed from customer's wallet balance
5. Real-time updates via WebSocket + Firebase push notifications

---

## Database Schema

### `messages` table (extended)

```
| Column      | Type         | Description                              |
|-------------|--------------|------------------------------------------|
| type        | string       | 'text' (default) or 'payment_request'    |
| metadata    | json/null    | For payment_request: {payment_request_id: int} |
```

### `payment_requests` table

```
| Column          | Type          | Description                           |
|-----------------|---------------|---------------------------------------|
| id              | bigint        | Primary key                           |
| conversation_id | bigint (FK)   | Links to conversations table          |
| message_id      | bigint (FK)   | Links to messages table (nullable)    |
| appointment_id  | bigint (FK)   | Optional link to appointment          |
| requester_id    | bigint (FK)   | Stylist user ID                       |
| payer_id        | bigint (FK)   | Customer user ID                      |
| title           | string        | Payment request title                 |
| description     | text          | Optional description                  |
| total_amount    | decimal(10,2) | Total amount to pay                   |
| status          | string        | pending/accepted/declined/paid/cancelled/expired |
| accepted_at     | timestamp     | When customer accepted                |
| declined_at     | timestamp     | When customer declined                |
| paid_at         | timestamp     | When payment was completed            |
| cancelled_at    | timestamp     | When stylist cancelled                |
| expires_at      | timestamp     | Optional expiration time              |
| transaction_id  | bigint (FK)   | Links to transaction after payment    |
| created_at      | timestamp     |                                       |
| updated_at      | timestamp     |                                       |
| deleted_at      | timestamp     | Soft delete                           |
```

### `payment_request_items` table

```
| Column             | Type          | Description              |
|--------------------|---------------|--------------------------|
| id                 | bigint        | Primary key              |
| payment_request_id | bigint (FK)   | Parent payment request   |
| name               | string        | Item name                |
| description        | text          | Optional description     |
| quantity           | integer       | Default: 1               |
| unit_price         | decimal(10,2) | Price per unit           |
| amount             | decimal(10,2) | quantity × unit_price    |
| created_at         | timestamp     |                          |
| updated_at         | timestamp     |                          |
```

---

## API Endpoints

**Base URL:** `https://appupdate.snipfair.com/api`  
**Auth:** Bearer token (Sanctum)

### 1. Create Payment Request (Stylist)

```
POST /api/payment-requests
```

**Request Body:**

> **Note:** `recipient_id` is always required. The backend will automatically find the existing conversation between the two users, or create a new one if none exists.

```json
{
    "recipient_id": 20, // required: the other user's ID
    "appointment_id": 456, // optional
    "title": "Additional styling products",
    "description": "Products used during session", // optional
    "items": [
        {
            "name": "Hair treatment serum",
            "description": "Deep conditioning", // optional
            "quantity": 1, // optional, default: 1
            "unit_price": 150.0
        },
        {
            "name": "Styling gel",
            "quantity": 2,
            "unit_price": 75.0
        }
    ],
    "expires_in_hours": 48 // optional, max 720 (30 days)
}
```

**Response (201):**

```json
{
    "message": "Payment request created successfully.",
    "data": {
        "id": 1,
        "conversation_id": 123,
        "message_id": 789,
        "appointment_id": 456,
        "requester": {
            "id": 10,
            "name": "Jane's Salon",
            "profile_picture": "https://..."
        },
        "payer": {
            "id": 20,
            "name": "John Customer",
            "profile_picture": "https://..."
        },
        "title": "Additional styling products",
        "description": "Products used during session",
        "total_amount": 300.0,
        "status": "pending",
        "items": [
            {
                "id": 1,
                "name": "Hair treatment serum",
                "description": "Deep conditioning",
                "quantity": 1,
                "unit_price": 150.0,
                "amount": 150.0
            },
            {
                "id": 2,
                "name": "Styling gel",
                "description": null,
                "quantity": 2,
                "unit_price": 75.0,
                "amount": 150.0
            }
        ],
        "accepted_at": null,
        "declined_at": null,
        "paid_at": null,
        "cancelled_at": null,
        "expires_at": "2026-02-24T10:30:00.000000Z",
        "can_accept": true,
        "can_decline": true,
        "can_pay": true,
        "can_cancel": true,
        "created_at": "2026-02-22T10:30:00.000000Z",
        "updated_at": "2026-02-22T10:30:00.000000Z"
    }
}
```

---

### 2. List Payment Requests

```
GET /api/payment-requests
```

**Query Parameters:**

- `per_page` (int) - Items per page, default: 15
- `status` (string) - Filter by status: pending, accepted, declined, paid, cancelled, expired
- `role` (string) - Filter by user role: 'requester' or 'payer'

**Response:**

```json
{
    "data": [
        {
            /* PaymentRequest object */
        },
        {
            /* PaymentRequest object */
        }
    ],
    "meta": {
        "current_page": 1,
        "last_page": 3,
        "per_page": 15,
        "total": 42
    }
}
```

---

### 3. Get Single Payment Request

```
GET /api/payment-requests/{id}
```

**Response:**

```json
{
    "data": {
        /* PaymentRequest object */
    }
}
```

---

### 4. Accept Payment Request (Customer)

```
POST /api/payment-requests/{id}/accept
```

**Response:**

```json
{
    "message": "Payment request accepted.",
    "data": {
        /* PaymentRequest object with status: "accepted" */
    }
}
```

---

### 5. Decline Payment Request (Customer)

```
POST /api/payment-requests/{id}/decline
```

**Response:**

```json
{
    "message": "Payment request declined.",
    "data": {
        /* PaymentRequest object with status: "declined" */
    }
}
```

---

### 6. Cancel Payment Request (Stylist)

```
POST /api/payment-requests/{id}/cancel
```

**Response:**

```json
{
    "message": "Payment request cancelled.",
    "data": {
        /* PaymentRequest object with status: "cancelled" */
    }
}
```

---

### 7. Pay Payment Request (Customer)

```
POST /api/payment-requests/{id}/pay
```

**Success Response:**

```json
{
    "message": "Payment successful.",
    "data": {
        /* PaymentRequest object with status: "paid" */
    },
    "new_wallet_balance": 450.0
}
```

**Insufficient Balance Response (400):**

```json
{
    "message": "Insufficient wallet balance.",
    "wallet_balance": 100.0,
    "required_amount": 300.0,
    "shortfall": 200.0
}
```

---

### 8. Payment Requests for Conversation

```
GET /api/conversations/{conversationId}/payment-requests
```

**Response:**

```json
{
    "data": [
        {
            /* PaymentRequest object */
        }
    ]
}
```

---

## Message Integration

When a payment request is created, a message is automatically added to the conversation:

### Message Structure

```json
{
    "id": "789",
    "conversation_id": "123",
    "sender_id": "10",
    "receiver_id": "20",
    "text": "Payment Request: Additional styling products",
    "type": "payment_request",
    "metadata": {
        "payment_request_id": 1
    },
    "is_read": false,
    "created_at": "2026-02-22T10:30:00.000000Z"
}
```

### How to Render in Chat (Flutter)

```dart
// In your message list builder
Widget buildMessageItem(ChatMessage message) {
  if (message.isPaymentRequest && message.metadata?.paymentRequestId != null) {
    // Fetch and display payment request card
    return FutureBuilder<PaymentRequest>(
      future: paymentRequestService.getPaymentRequest(
        message.metadata!.paymentRequestId!,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return PaymentRequestCard(
            paymentRequest: snapshot.data!,
            isCurrentUserPayer: snapshot.data!.payer.id == currentUserId,
            onAccept: () => _handleAccept(snapshot.data!.id),
            onDecline: () => _handleDecline(snapshot.data!.id),
            onPay: () => _handlePay(snapshot.data!.id),
            onCancel: () => _handleCancel(snapshot.data!.id),
          );
        }
        return const PaymentRequestCardSkeleton();
      },
    );
  }
  // Regular text message bubble
  return MessageBubble(message: message);
}
```

---

## WebSocket Events

### Channel Subscriptions (Flutter with laravel_echo_null)

```dart
// Using laravel_echo_null or pusher_client package
import 'package:laravel_echo_null/laravel_echo_null.dart';

// Subscribe to conversation channel
echo.private('conversation.$conversationId')
  .listen('.payment_request.created', (e) {
    final paymentRequest = PaymentRequest.fromJson(e['payment_request']);
    final message = ChatMessage.fromJson(e['message']);
    // Add message to chat and show payment request
  })
  .listen('.payment_request.updated', (e) {
    final paymentRequest = PaymentRequest.fromJson(e['payment_request']);
    // Update payment request status in UI
  });

// Subscribe to user's personal channel
echo.private('user.$userId')
  .listen('.payment_request.created', (e) {
    // Show notification for new payment request
  })
  .listen('.payment_request.updated', (e) {
    // Show notification for status update
  });
```

### Event Payloads

**payment_request.created:**

```json
{
    "payment_request": {
        /* Full PaymentRequest object */
    },
    "message": {
        "id": "789",
        "conversation_id": "123",
        "sender_id": "10",
        "receiver_id": "20",
        "text": "Payment Request: Additional styling products",
        "type": "payment_request",
        "metadata": { "payment_request_id": 1 },
        "is_read": false,
        "created_at": "2026-02-22T10:30:00.000000Z"
    },
    "conversation_id": "123"
}
```

**payment_request.updated:**

```json
{
    "payment_request": {
        /* Full PaymentRequest object with updated status */
    },
    "conversation_id": "123"
}
```

---

## Push Notifications (Firebase)

Notifications are automatically sent for:

| Event     | Recipient           | Title                                | Body                                                             |
| --------- | ------------------- | ------------------------------------ | ---------------------------------------------------------------- |
| Created   | Payer (Customer)    | "Payment Request from {StylistName}" | "You have received a payment request for R{amount} - {title}"    |
| Accepted  | Requester (Stylist) | "Payment Request Accepted"           | "{CustomerName} has accepted your payment request for R{amount}" |
| Declined  | Requester (Stylist) | "Payment Request Declined"           | "{CustomerName} has declined your payment request for R{amount}" |
| Paid      | Requester (Stylist) | "Payment Received"                   | "You have received R{amount} from {CustomerName}"                |
| Cancelled | Payer (Customer)    | "Payment Request Cancelled"          | "{StylistName} has cancelled the payment request for R{amount}"  |

**Notification Data Payload:**

```json
{
    "type": "payment_request",
    "type_identifier": 1,
    "conversation_id": 123,
    "status": "paid"
}
```

---

## Status State Machine

```
                    ┌─────────────┐
                    │   PENDING   │
                    └──────┬──────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│   ACCEPTED    │  │   DECLINED    │  │   CANCELLED   │
└───────┬───────┘  └───────────────┘  └───────────────┘
        │
        ▼
┌───────────────┐
│     PAID      │
└───────────────┘

Note: PENDING can also transition to EXPIRED (automatic, time-based)
Note: PENDING can transition directly to PAID (customer can pay without accepting first)
```

---

## Dart Models (for Flutter App)

```dart
// Enums
enum PaymentRequestStatus {
  pending,
  accepted,
  declined,
  paid,
  cancelled,
  expired;

  static PaymentRequestStatus fromString(String value) {
    return PaymentRequestStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentRequestStatus.pending,
    );
  }
}

enum MessageType {
  text,
  paymentRequest;

  static MessageType fromString(String value) {
    switch (value) {
      case 'payment_request':
        return MessageType.paymentRequest;
      default:
        return MessageType.text;
    }
  }

  String toJson() {
    switch (this) {
      case MessageType.paymentRequest:
        return 'payment_request';
      default:
        return 'text';
    }
  }
}

// Models
class PaymentRequestItem {
  final int id;
  final String name;
  final String? description;
  final int quantity;
  final double unitPrice;
  final double amount;

  PaymentRequestItem({
    required this.id,
    required this.name,
    this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
  });

  factory PaymentRequestItem.fromJson(Map<String, dynamic> json) {
    return PaymentRequestItem(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unit_price'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'quantity': quantity,
    'unit_price': unitPrice,
  };
}

class PaymentRequestUser {
  final int id;
  final String name;
  final String? profilePicture;

  PaymentRequestUser({
    required this.id,
    required this.name,
    this.profilePicture,
  });

  factory PaymentRequestUser.fromJson(Map<String, dynamic> json) {
    return PaymentRequestUser(
      id: json['id'] as int,
      name: json['name'] as String,
      profilePicture: json['profile_picture'] as String?,
    );
  }
}

class PaymentRequest {
  final int id;
  final int conversationId;
  final int? messageId;
  final int? appointmentId;
  final PaymentRequestUser requester;
  final PaymentRequestUser payer;
  final String title;
  final String? description;
  final double totalAmount;
  final PaymentRequestStatus status;
  final List<PaymentRequestItem> items;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final DateTime? paidAt;
  final DateTime? cancelledAt;
  final DateTime? expiresAt;
  final bool canAccept;
  final bool canDecline;
  final bool canPay;
  final bool canCancel;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentRequest({
    required this.id,
    required this.conversationId,
    this.messageId,
    this.appointmentId,
    required this.requester,
    required this.payer,
    required this.title,
    this.description,
    required this.totalAmount,
    required this.status,
    required this.items,
    this.acceptedAt,
    this.declinedAt,
    this.paidAt,
    this.cancelledAt,
    this.expiresAt,
    required this.canAccept,
    required this.canDecline,
    required this.canPay,
    required this.canCancel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      messageId: json['message_id'] as int?,
      appointmentId: json['appointment_id'] as int?,
      requester: PaymentRequestUser.fromJson(json['requester']),
      payer: PaymentRequestUser.fromJson(json['payer']),
      title: json['title'] as String,
      description: json['description'] as String?,
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: PaymentRequestStatus.fromString(json['status'] as String),
      items: (json['items'] as List<dynamic>)
          .map((e) => PaymentRequestItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      declinedAt: json['declined_at'] != null
          ? DateTime.parse(json['declined_at'] as String)
          : null,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      canAccept: json['can_accept'] as bool? ?? false,
      canDecline: json['can_decline'] as bool? ?? false,
      canPay: json['can_pay'] as bool? ?? false,
      canCancel: json['can_cancel'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  bool get isPending => status == PaymentRequestStatus.pending;
  bool get isAccepted => status == PaymentRequestStatus.accepted;
  bool get isDeclined => status == PaymentRequestStatus.declined;
  bool get isPaid => status == PaymentRequestStatus.paid;
  bool get isCancelled => status == PaymentRequestStatus.cancelled;
  bool get isExpired => status == PaymentRequestStatus.expired;
}

class MessageMetadata {
  final int? paymentRequestId;

  MessageMetadata({this.paymentRequestId});

  factory MessageMetadata.fromJson(Map<String, dynamic>? json) {
    if (json == null) return MessageMetadata();
    return MessageMetadata(
      paymentRequestId: json['payment_request_id'] as int?,
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String text;
  final MessageType type;
  final MessageMetadata? metadata;
  final String? attachment;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.type,
    this.metadata,
    this.attachment,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'].toString(),
      conversationId: json['conversation_id'].toString(),
      senderId: json['sender_id'].toString(),
      receiverId: json['receiver_id'].toString(),
      text: json['text'] as String? ?? '',
      type: MessageType.fromString(json['type'] as String? ?? 'text'),
      metadata: json['metadata'] != null
          ? MessageMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
      attachment: json['attachment'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isPaymentRequest => type == MessageType.paymentRequest;
  bool get isTextMessage => type == MessageType.text;
}

// Request Models
class CreatePaymentRequestDto {
  final int recipientId;
  final int? appointmentId;
  final String title;
  final String? description;
  final List<PaymentRequestItemDto> items;
  final int? expiresInHours;

  CreatePaymentRequestDto({
    required this.recipientId,
    this.appointmentId,
    required this.title,
    this.description,
    required this.items,
    this.expiresInHours,
  });

  Map<String, dynamic> toJson() => {
    'recipient_id': recipientId,
    if (appointmentId != null) 'appointment_id': appointmentId,
    'title': title,
    if (description != null) 'description': description,
    'items': items.map((e) => e.toJson()).toList(),
    if (expiresInHours != null) 'expires_in_hours': expiresInHours,
  };
}

class PaymentRequestItemDto {
  final String name;
  final String? description;
  final int quantity;
  final double unitPrice;

  PaymentRequestItemDto({
    required this.name,
    this.description,
    this.quantity = 1,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    'quantity': quantity,
    'unit_price': unitPrice,
  };
}

// Response Models
class PaymentRequestResponse {
  final String? message;
  final PaymentRequest data;
  final double? newWalletBalance;

  PaymentRequestResponse({
    this.message,
    required this.data,
    this.newWalletBalance,
  });

  factory PaymentRequestResponse.fromJson(Map<String, dynamic> json) {
    return PaymentRequestResponse(
      message: json['message'] as String?,
      data: PaymentRequest.fromJson(json['data'] as Map<String, dynamic>),
      newWalletBalance: json['new_wallet_balance'] != null
          ? (json['new_wallet_balance'] as num).toDouble()
          : null,
    );
  }
}

class PaymentRequestListResponse {
  final List<PaymentRequest> data;
  final PaginationMeta meta;

  PaymentRequestListResponse({
    required this.data,
    required this.meta,
  });

  factory PaymentRequestListResponse.fromJson(Map<String, dynamic> json) {
    return PaymentRequestListResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => PaymentRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
    );
  }
}

class InsufficientBalanceError {
  final String message;
  final double walletBalance;
  final double requiredAmount;
  final double shortfall;

  InsufficientBalanceError({
    required this.message,
    required this.walletBalance,
    required this.requiredAmount,
    required this.shortfall,
  });

  factory InsufficientBalanceError.fromJson(Map<String, dynamic> json) {
    return InsufficientBalanceError(
      message: json['message'] as String,
      walletBalance: (json['wallet_balance'] as num).toDouble(),
      requiredAmount: (json['required_amount'] as num).toDouble(),
      shortfall: (json['shortfall'] as num).toDouble(),
    );
  }
}
```

---

## Flutter App Integration Checklist

### Chat Screen

- [ ] Check `message.isPaymentRequest` when rendering messages
- [ ] For payment request type, fetch full payment request data via API
- [ ] Create `PaymentRequestCard` widget with action buttons
- [ ] Subscribe to WebSocket events using `laravel_echo_null` or `pusher_client`
- [ ] Use `Provider` or `Riverpod` for state management

### PaymentRequestCard Widget

- [ ] Display title, description, items list, total amount
- [ ] Show status chip/badge (pending/accepted/declined/paid/cancelled/expired)
- [ ] Conditional action buttons based on user role and `can*` flags:
    - Payer (Customer): Accept, Decline, Pay buttons
    - Requester (Stylist): Cancel button
- [ ] Handle insufficient balance with dialog/snackbar
- [ ] Use `Card` widget with proper elevation and styling

### Stylist Features

- [ ] "Request Payment" FloatingActionButton or IconButton in chat AppBar
- [ ] Create `PaymentRequestFormScreen` with:
    - Title TextField
    - Description TextField (optional)
    - Dynamic list of line items (name, qty, price)
    - Add/Remove item buttons
    - Optional appointment dropdown
    - Optional expiration time picker
- [ ] View sent payment requests in history screen

### Customer Features

- [ ] View received payment requests
- [ ] Accept/Decline/Pay action handlers
- [ ] Navigate to wallet top-up if insufficient balance

### Push Notifications (Firebase)

- [ ] Configure `firebase_messaging` package
- [ ] Handle `payment_request` notification type in background handler
- [ ] Deep link to conversation using `go_router` or `auto_route`

### Recommended Packages

```yaml
dependencies:
    # WebSocket/Real-time
    laravel_echo_null: ^1.0.0 # or pusher_client
    web_socket_channel: ^2.4.0

    # State Management
    provider: ^6.0.0 # or riverpod

    # HTTP
    dio: ^5.0.0 # or http

    # Push Notifications
    firebase_messaging: ^14.0.0
    firebase_core: ^2.0.0

    # Navigation
    go_router: ^12.0.0

    # UI
    flutter_slidable: ^3.0.0 # for swipe actions
    shimmer: ^3.0.0 # for loading skeletons
```

---

## Error Handling

| Status | Message                                    | Meaning                      |
| ------ | ------------------------------------------ | ---------------------------- |
| 400    | "This payment request cannot be accepted." | Already processed or expired |
| 400    | "Insufficient wallet balance."             | Need to top up wallet        |
| 403    | "You are not part of this conversation."   | User not in conversation     |
| 403    | "Only the payer can accept/decline/pay..." | Wrong user role for action   |
| 403    | "Only the requester can cancel..."         | Wrong user role for action   |
| 404    | Not found                                  | Invalid payment request ID   |

---

## Files Created/Modified (Backend)

```
app/
├── Models/
│   ├── PaymentRequest.php        # NEW
│   ├── PaymentRequestItem.php    # NEW
│   └── Message.php               # MODIFIED (added type, metadata)
├── Http/Controllers/
│   └── PaymentRequestController.php  # NEW
├── Events/
│   ├── PaymentRequestCreated.php     # NEW
│   └── PaymentRequestUpdated.php     # NEW

database/migrations/
├── 2026_02_22_100000_add_type_and_metadata_to_messages_table.php
├── 2026_02_22_100001_create_payment_requests_table.php
└── 2026_02_22_100002_create_payment_request_items_table.php

routes/
└── api.php  # MODIFIED (added payment request routes)
```

---

_Use this document as context when implementing the Payment Request feature in the Flutter mobile app. The Dart models above can be directly copied into your project's models directory._
