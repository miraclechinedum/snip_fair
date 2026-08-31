# Snipfair Flutter — QA List Audit (app side only)

Audit date: 2026-08-13. Read-only: no files were edited, staged or committed other than this file.

Card payment paths (`_cardPaymentEnabled = false`) are treated as intentionally disabled and excluded from verdicts.

---

## 0. Git state — what is actually being audited

```
$ git status -sb
## main...origin/main
 M .env
 M android/app/src/main/AndroidManifest.xml
 ... (83 changed paths total)
?? lib/core/domain/entities/stylist_escrow/
?? lib/core/services/analytics_service.dart
?? lib/core/services/chat_draft_service.dart
```

- `git status --porcelain | wc -l` → **83** changed/untracked paths.
- `git tag --points-at HEAD` → **no tags**.
- HEAD = `d2b09b0 feat: Enhance authentication handling with optionalAuth flag; update version in pubspec.yaml`.

**This audit reflects the working tree, not a committed or tagged build.** Large parts of what is described below (escrow breakdown screen, `stylist_escrow/` entities, `analytics_service.dart`, `chat_draft_service.dart`, the modified wallet/conversations/notification files) exist **only as uncommitted local changes**. If the client tested a build produced from `origin/main`, none of the uncommitted work was in it. Before comparing findings to client reports, confirm which commit the tested build came from.

---

## Cross-cutting defect — affects items 2/7, 5, 8, 9

`AppCubit` is registered as a **factory**, not a singleton, so every `getIt<AppCubit>()` returns a brand-new cubit whose state is `AppState.initial()` (`status = AuthStatus.unknown`, `user.role == null`).

`lib/core/di/injector.config.dart:168-169`
```dart
  gh.factory<_i782.AppCubit>(
      () => _i782.AppCubit(gh<_i990.ProfileRepository>()));
```
`lib/core/presentation/cubit/app_state.dart:14`
```dart
    this.status = AuthStatus.unknown,
```

Four call sites read auth/role state through `getIt<AppCubit>()` and therefore always see "not authenticated / not a customer / not a stylist":

| Site | Consequence |
|---|---|
| `lib/core/network/token_interceptor.dart:35-36` — `getIt<AppCubit>().state.status == AuthStatus.authenticated` | `optionalAuth` requests **never** attach the bearer token, even when logged in |
| `lib/features/conversations/cubit/conversations_cubit.dart:491` — `final appState = getIt<AppCubit>().state;` | `_refreshMoneyStateAfterPay()` runs **neither** branch → wallet/earnings are not refreshed after paying a payment request (item 5) |
| `lib/core/presentation/app.dart:46-52` — notification-tap handler bails on `state.status != AuthStatus.authenticated` | dead handler (see note below) |
| `lib/core/services/analytics_service.dart:176` | currency code always null in analytics events |

Note on the third row: `MainScreen._setupNotificationNavigation` (`lib/core/presentation/main_screen.dart:107-113`) reassigns `NotificationService.instance.onNotificationTap` **later** (MainScreen `initState` runs after `App` `initState`) and correctly uses `context.read<AppCubit>()`. So notification taps do work **while MainScreen is mounted**; the `app.dart` copy is unreachable dead code. See item 2/7 for the terminated-state gap.

Runtime check to confirm: log `identityHashCode(getIt<AppCubit>())` twice — two different values proves the factory behaviour; or breakpoint `conversations_cubit.dart:492` after a `pay` and observe `appState.isCustomer == false`.

---

## Item 1 — Appointments not displaying after booking

**Verdict: [BUG — error state is rendered as an empty list; and no appointment refetch after login]**

### Endpoints and parsing (both correct)

Customer list — `GET /customer/appointment/list`:
`lib/core/data/datasources/remote/snip_fair_backend_remote_source.dart:1178-1195`
```dart
      final response = await client.get<Map<String, dynamic>>(
        '${AuthPath.customerAppointment}/list',
        queryParameters: {
          if (page != null) 'page': page,
          if (perPage != null) 'per_page': perPage,
        },
      );
      return ApiResult.success(
        data: CustomerAppointmentList.fromJson(response.data!),
      );
```

Stylist list — `GET /stylist/appointment/list`:
`lib/core/data/datasources/remote/snip_fair_backend_remote_source.dart:764-793` (same shape, plus optional `status`, `customer_id`, `sort` query params — **none of which the list screens ever pass**).

Both parse a Laravel cursor page (`data`, `next_cursor`, `prev_cursor`) — `lib/core/domain/entities/customer_appointment_list/customer_appointment_list.dart:20-34`, `lib/core/domain/entities/apointment/appointment_list.dart:18-32`.

**There is no client-side status or date filter on either list screen.** A just-booked appointment in any status will render if it is in the payload.

### Defect 1a — a failed request renders as "No Appointments found"

`lib/features/appointments/customer_appointments/cubit/customer_appointments_cubit.dart:72-79`
```dart
      failure: (error) {
        emit(
          state.copyWith(
            appointments: ProcessState.error(error, state.appointments.data),
          ),
        );
      },
```
`lib/features/appointments/customer_appointments/views/appointements_main_screen.dart:36-37, 49-58`
```dart
          final appointments =
              state.appointments.data ?? <CustomerAppointment>[];
...
                    emptyBuilder: (context) => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: AppText(
                          text: 'No Appointments found',
```
The screen never reads `state.appointments.hasError`. On the first load `data` is null, so a 401/404/500/timeout produces exactly the same UI as a genuinely empty list. Identical code on the stylist side: `seller_appoint_mgt_cubit.dart:70-77` and `seller_appointments_main_screen.dart:33, 45-54`.

This alone is enough to explain "appointments not displaying" with no visible error.

### Defect 1b — appointments are fetched once, before auth, and never refetched on login

`lib/core/presentation/app.dart:142-144`
```dart
              create: (context) => getIt<CustomerAppointmentsCubit>()..getAppointments(),
              child: BlocProvider(
                create: (context) => getIt<SellerAppointMgtCubit>()..getAppointments(),
```
`lib/core/presentation/app.dart:216-229` — the `AuthStatus.authenticated` listener refreshes profile, stats, wallet and transactions, but **not** appointments:
```dart
                                      if (state.isCustomer) {
                                        context.read<CustomerProfileMgtCubit>()
                                          ..getProfileDetails()
                                          ..getStats()
                                          ..getWallet()
                                          ..getWalletTransactions();
                                      }
```
`grep -rn "getAppointments" lib` confirms the only other callers are pull-to-refresh, `InfiniteList.onFetchData`, the booking-success listener, and `seller_appointment_details_screen.dart:65`.

When no token is stored, `TokenInterceptor` rejects the request outright (`lib/core/network/token_interceptor.dart:48-55`), so a guest→login session lands in the error state of 1a and stays there until the user pulls to refresh. Same for a stylist whose device just logged in.

### Booking → refresh (customer path is wired)

`lib/features/appointments/update_create_appointment/views/update_create_appointment_screen.dart:277`
```dart
                      context.read<CustomerAppointmentsCubit>().getAppointments();
```
Uses `context.read` (the provider instance) — correct. The stylist has **no** equivalent: a stylist's list only updates on app start, pull-to-refresh, or returning from the details screen. A stylist looking at an already-open appointments tab will not see a new customer booking appear.

**Cross-repo dependency:** whether `/customer/appointment/list` and `/stylist/appointment/list` actually include a just-created appointment (default status, default page ordering) is backend-side. **Runtime check:** capture the `LogInterceptor` output (`http_service.dart:85-90` logs full request/response) for `GET /customer/appointment/list` immediately after a booking and confirm HTTP 200 with the new id in `data[]`.

---

## Items 2 & 7 — No notification on new chat messages; only a bright-purple indicator

**Verdict: [OK on push plumbing / BUG on the terminated-state tap and the per-row indicator]**

### Push handling is fully implemented

- Deps present: `pubspec.yaml:52-54` (`firebase_core`, `firebase_messaging: ^15.1.3`, `flutter_local_notifications: ^18.0.1`).
- Firebase init + background handler registration: `lib/bootstrap.dart:56-64`, then `NotificationService.instance.init()` at `lib/bootstrap.dart:107`.
- Permission request: `lib/core/services/notification_service.dart:48-50`.
- Foreground messages → local notification: `notification_service.dart:84-94`
```dart
    FirebaseMessaging.onMessage.listen((message) async {
      final data = _normalize(message);
      _updatesController.add(data);

      await _showLocalNotification(
        id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
```
- Background tap: `notification_service.dart:97-102`. Terminated-state launch: `notification_service.dart:105` → `_emitInitialMessageIfAny()`.
- Local-notification Android icon `'ic_launcher'` (`notification_service.dart:59`) resolves — `android/app/src/main/res/drawable/ic_launcher.png` exists.
- `POST_NOTIFICATIONS` is not in `android/app/src/main/AndroidManifest.xml` but is merged from both plugin manifests (`~/.pub-cache/.../flutter_local_notifications-18.0.1/android/src/main/AndroidManifest.xml:4`, `firebase_messaging-15.2.10/.../AndroidManifest.xml:7`).

### Token registration to backend is implemented

`lib/core/presentation/cubit/app_cubit.dart:96-102`
```dart
        final fcmToken = await NotificationService.instance.getToken();
        if (fcmToken != null && fcmToken.isNotEmpty) {
...
            await updateDeviceToken(fcmToken);
```
sent as `firebase_device_token` on `PATCH /user` — `snip_fair_backend_remote_source.dart:888`. Rotation is re-registered via `app_cubit.dart:29-33`.

### Defect 2a — terminated-state push tap does not navigate

`_emitInitialMessageIfAny()` fires from `NotificationService.init()` during **bootstrap** (`bootstrap.dart:107`), i.e. before `runApp`. `onNotificationTap` is not assigned until `MainScreen.initState` (`main_screen.dart:107`). At the moment the initial message is processed the callback is null and `_handleNotificationNavigation` logs and returns:

`notification_service.dart:113-115`
```dart
    if (onNotificationTap == null) {
      log('NotificationService: onNotificationTap callback not set');
      return;
    }
```
Tapping a chat push from a killed app therefore opens the app on the default screen, not the conversation.

### In-app signals beyond the purple text — these exist

- Global unread badge on the home app bar, polled every 4 s from `GET /conversations/unread-count`: `main_screen.dart:518-528` + `conversations_cubit.dart:314-337, 350-360`.
- In-app snackbar with an "Open" action on a foreground chat push: `main_screen.dart:270-380`.
- Notifications list screen backed by `GET /user/notifications`: `snip_fair_backend_remote_source.dart:1476-1493`, rendered by `lib/features/notifications/views/notifications_screen.dart`.

### Defect 2b — the conversation list row still has only the purple text

`lib/features/conversations/conversations_list/views/conversation_list_screen.dart:186-192`
```dart
    final unreadFromOther =
        last.senderId != currentUserId && last.isRead == false;
    return AppText(
      text: last.text ?? '',
      color: unreadFromOther ? AppColors.primaryColor : Colors.grey,
    );
```
The row `trailing` (`conversation_list_screen.dart:106-128`) shows a timestamp and a green double-tick for *your own* read messages — there is **no per-row unread count chip**. `ChatConversation.unreadCount` is available (used at `main_screen.dart:531-534` for the global sum) but unused per row. The client's "only a bright-purple indicator" is accurate for this screen.

**Cross-repo dependency:** whether the backend actually *sends* an FCM push on a new chat message, and whether the payload uses `type: "chat" | "message" | "conversation"` with `type_identifier` = conversation id (the values the app switches on — `main_screen.dart:134-144`, `conversations_cubit.dart:27-33`), is entirely backend-side. **Runtime check:** with the app foregrounded, send a message from the other account and look for `FCM Message Data: {...}` in the console (`notification_service.dart:155`). No log line ⇒ the backend never sent the push, and no app change will fix it.

---

## Item 3 — Payment request UI forces choosing an appointment before paying for added services

**Verdict: [BUG — appointment selection is a hard, client-imposed gate on the stylist's compose screen; the customer's pay action has no such gate]**

The gate is on the **stylist composing** the request, not the customer paying.

`lib/features/conversations/conversation/widgets/payment_request_form_bottom_sheet.dart:426-431`
```dart
                        Text(
                          'Appointment *',
```
`:516-519` — dropdown validator:
```dart
                            validator: (v) => v == null
                                ? 'Please select an appointment'
                                : null,
```
`:588-591` — Send button disabled outright when blocked:
```dart
                            final disabled =
                                state.createPaymentRequestState.isLoading ||
                                    _loadingAppointments ||
                                    _blockedAppointmentState;
```
`:103-105` — blocked when the customer has no *eligible* appointment:
```dart
  bool get _blockedAppointmentState =>
      !_loadingAppointments &&
      (_isLocked ? _selectedAppointmentId == null : _appointments.isEmpty);
```
`:123-137` — the eligibility allow-list, applied client-side after fetching `GET /stylist/appointment/list?customer_id=…`:
```dart
  static const _openAppointmentStatuses = {
    'processing',
    'pending',
    'approved',
    'confirmed',
  };
...
  bool _isEligibleForPayment(StylistAppointment a) {
    final s = a.status?.toLowerCase();
    if (s == null || s.isEmpty) return false;
    return _openAppointmentStatuses.contains(s);
  }
```
Note `completed` is **excluded**. A stylist who finishes a service and then wants to bill for products used is blocked with "You can only send a payment request for an active appointment with this customer" (`:466-470`).

Control flow, both entry points:
- From chat (`conversation_chat_screen.dart:159-163`) — no `appointmentId` passed → dropdown, mandatory.
- From appointment details (`seller_appointment_details_screen.dart:455-461` and `:494-498`) — `appointmentId` passed → locked read-only display.

**The gate is client-only.** The wire format makes `appointment_id` optional:
`snip_fair_backend_remote_source.dart:1684`
```dart
          if (appointmentId != null) 'appointment_id': appointmentId,
```
So removing/relaxing the gate is an app-side change, contingent on the backend accepting `POST /payment-requests` without `appointment_id`.

Customer side — no appointment involvement in paying:
`lib/features/conversations/conversation/widgets/payment_request_card.dart:319-322`
```dart
  bool _shouldShowActions(PaymentRequest pr, bool isStylist) {
    if (isStylist) return pr.isPending && (pr.canCancel ?? false);
    // Customer: pending → accept/decline, accepted → pay, everything else → nothing
    return pr.isPending || pr.isAccepted;
```
`_respond('pay')` (`payment_request_card.dart:61-80`) posts `POST /payment-requests/{id}/pay` (`snip_fair_backend_remote_source.dart:1720-1722`) with no appointment payload.

**Cross-repo dependency:** confirm with backend whether `appointment_id` is truly optional and which appointment statuses it accepts, before relaxing the client allow-list. The in-code comment at `:115-118` claims the allow-list "matches the backend's server-side allow-list" — that claim is unverified from this repo.

---

## Item 4 — Booking email

**Verdict: [NOT IMPLEMENTED — app side, by design. Cross-repo: backend]**

No app code sends or triggers a booking email. The app's only booking action is:
`snip_fair_backend_remote_source.dart:1116-1128`
```dart
      final response = await client.post<Map<String, dynamic>>(
        '${AuthPath.customerAppointment}/book',
        data: {
          'portfolio_id': portfolioId,
          'selected_date': date,
          'selected_time': time,
          'payment_method': 'wallet',
```
Email dispatch is a side effect of `POST /customer/appointment/book` on the backend. `grep -rin "mail\|email" lib` finds only auth/OTP/profile email fields — no booking-mail trigger. **No app change is required; this item belongs entirely to the backend repo.**

---

## Items 5 & 8 (wallet part) — Wallet shows nothing "holding"; funds taken but not visible

**Verdict: [OK — the escrow tile and breakdown exist and are wired to real endpoints] with [BUG — no refresh after paying a payment request] and one unverifiable payload assumption**

### Customer escrow tile — exists, real endpoint, not a stub

`lib/features/wallet/views/customer_wallet_screen.dart:289-314`
```dart
                      AppText(
                        text: cubit.state.walletState.data?.escrowBalance
                                ?.formatAmount() ??
                            'R0.00',
...
                  const AppText(
                    text: 'In Escrow',
```
Backed by `GET /wallet` — `snip_fair_backend_remote_source.dart:1017-1027`. Field mapping `lib/core/domain/entities/customer_wallet/customer_wallet.g.dart:11-12`:
```dart
      balance: (json['balance'] as num?)?.toInt(),
      escrowBalance: (json['escrow_balance'] as num?)?.toInt(),
```
Explanatory dialog at `customer_wallet_screen.dart:340-356`.

Two payload risks that **cannot be settled statically**:
1. If `/wallet` wraps its body (`{"data": {...}}`), `escrow_balance` resolves to null and the tile silently reads `R0.00` — the parse does not throw, it just yields nulls.
2. `(json['escrow_balance'] as num?)` throws if the backend serialises the amount as a **string** (`"150.00"`), which would fail the whole wallet parse; and `.toInt()` truncates cents if it is a decimal.

**Runtime check:** capture the raw `GET /wallet` response body from the `LogInterceptor` output and confirm the key is top-level `escrow_balance` and is a JSON number.

### Held/pending transactions in the wallet list

`customer_wallet_screen.dart:150-181` renders `transaction.status` as a coloured pill with a `pending` branch, and `transaction.type` drives the icon with an `else` fallback (`Iconsax.bank`) for any unrecognised type — so an `escrow`/`hold` type is **not** dropped, it just gets the generic icon and a `-` sign. `UserTransaction` (`lib/core/domain/entities/customer_wallet_transaction_list/datum.dart:20-29`) keeps `type` and `status` as free-form strings, so nothing is filtered out client-side.

### Stylist escrow breakdown — exists, calls `/stylist/earnings/escrow`

Entry point: `lib/features/account/seller/earnings/views/seller_earning_screen.dart:529-536` (tappable "In Escrow" tile → plain `MaterialPageRoute`, deliberately not registered in `routes.gr.dart`), value from `statistics.pending_release` (`:566-570`).

Screen: `lib/features/account/seller/earnings/views/seller_escrow_breakdown_screen.dart:25-26`
```dart
      create: (_) =>
          EscrowBreakdownCubit(getIt<ProfileRepository>())..fetch(),
```
→ `getStylistEscrowBreakdown()` → `snip_fair_backend_remote_source.dart:863-873` → `AuthPath.stylistEscrow` = `'/stylist/earnings/escrow'` (`:114`).

**404 handling is correct and visible** — unlike the appointment lists, this screen has a real error branch: `seller_escrow_breakdown_screen.dart:48-53` renders `_ErrorView`, which prints the HTTP status code and server message (`:176-183`, `:216-231`) plus a Retry. A prod 404 will show "Status: 404" on screen rather than a blank list.

**Cosmetic defect:** the diagnostic line names the wrong path —
`seller_escrow_breakdown_screen.dart:234`
```dart
                        'GET /stylist/escrow — see Flutter console for the raw response body.',
```
The call is `/stylist/earnings/escrow`. This will misdirect whoever debugs the 404.

**Cross-repo dependency (flagged as requested):** `/stylist/earnings/escrow` may not be deployed. **Runtime check:** `curl` the endpoint with a stylist token, or open Earnings → In Escrow and read the on-screen "Status:" value.

### Defect 5a — wallet does not refresh after paying a payment request

`lib/features/conversations/cubit/conversations_cubit.dart:490-501`
```dart
  Future<void> _refreshMoneyStateAfterPay() async {
    final appState = getIt<AppCubit>().state;
    if (appState.isCustomer) {
      final cubit = getIt<CustomerProfileMgtCubit>();
```
Two independent failures here:
1. `getIt<AppCubit>()` is a factory (see cross-cutting section) → `isCustomer` and `isStylist` are both **false** → neither branch executes at all.
2. Even if the guard passed, `getIt<CustomerProfileMgtCubit>()` / `getIt<EarningsCubit>()` are also factories (`injector.config.dart:146-147, 150-151`), so it would refresh **throwaway cubit instances**, not the ones the wallet screen is built from (`customer_wallet_screen.dart:23` uses `context.watch<CustomerProfileMgtCubit>()`).

Result: after a customer pays an added-services request, the wallet balance and "In Escrow" tile stay stale until the user pull-to-refreshes or restarts. This matches "funds taken but not visible" exactly.

The booking path does **not** have this bug — it uses `context.read` (`update_create_appointment_screen.dart:278-280`).

---

## Item 6 — No payment history displayed

**Verdict: [OK — screen exists, calls the endpoint, renders pending/holding rows] with one reachability caveat**

`lib/features/account/customer/payment_history/view/customer_payment_history_screen.dart:19, 38, 50, 59`
```dart
    final cubit = context.watch<CustomerProfileMgtCubit>();
...
                  await cubit.getWalletTransactions();
...
                    cubit.getWalletTransactions(loadMore: true);
...
                  itemCount: cubit.state.transactionsState.data?.length ?? 0,
```
Endpoint: `GET /wallet/transactions` — `snip_fair_backend_remote_source.dart:1030-1047`. Pagination handled at `customer_profile_mgt_cubit.dart:98-141`.

Pending / non-standard types are rendered, not filtered: status pill with a `pending` branch at `:112-140`, and the type-icon chain falls back to `Iconsax.bank` for unknown types at `:66-81`.

Reachable from `lib/features/account/views/account_main_screen.dart:267` (`CustomerPaymentHistoryRoute`) and registered at `lib/core/routing/routes.dart:81`.

**Caveats:**
1. The screen has **no initial fetch of its own**. It relies on `getWalletTransactions()` having been called by the app-level auth listener (`app.dart:226`). If that call failed, the screen falls to `InfiniteList.onFetchData` → `getWalletTransactions(loadMore: true)`, which sends `page: null` and does re-fetch page 1 — so it self-heals, but only after one frame.
2. Same error-swallow shape as item 1: `transactionsState` error is stored (`customer_profile_mgt_cubit.dart:132-139`) but the screen only reads `.data`, so a failed request shows "No transactions found" (`:42-46`).
3. The export icon at `:24-27` is a bare `Icon`, not a button — export is decorative, not implemented.

**Cross-repo dependency:** whether `/wallet/transactions` returns escrow/hold rows at all is backend-side. **Runtime check:** inspect the raw `GET /wallet/transactions` body for rows with an escrow/hold `type`.

---

## Item 8 — "Pending, no link in mail to complete booking" (app side)

**Verdict: [NOT IMPLEMENTED — the app has no deep-link entry point at all]**

- No deep-link package: `grep -rn "app_links\|uni_links\|deep_link\|getInitialLink" pubspec.yaml lib` → **no matches**.
- Android: `android/app/src/main/AndroidManifest.xml:29-32` has only the LAUNCHER intent filter. No `android.intent.action.VIEW`, no `<data android:scheme=…>`, no App Links `autoVerify`.
- iOS: `ios/Runner/Runner.entitlements` contains only `aps-environment` — **no `com.apple.developer.associated-domains`**, so Universal Links cannot work.

A link in an email therefore cannot open the app, into a pending booking or anywhere else.

The only in-app route to a pending item is a **push notification tap** (`main_screen.dart:145-162` for `type: 'appointment'` → `UpdateCreateAppointmentRoute` for customers) or the notifications list (`notifications_screen.dart:168-190`) — both subject to the terminated-state gap in item 2a.

**Cross-repo dependency:** the email content and its link target are backend. Making the link land in the app requires **both** a backend change (link format) and an app change (deep-link package + manifest intent filter + iOS associated domains + Apple/Google site-association files hosted on the domain).

---

## Item 9 — No in-app notification of pending payment

**Verdict: [OK — a dedicated pending-payment indicator exists and is wired] but [CANNOT DETERMINE STATICALLY — the backing endpoint fails silently, so it is invisible if not deployed]**

Dedicated app-bar indicator, customer-only, with a numeric badge:
`lib/core/presentation/main_screen.dart:444-455`
```dart
            BlocBuilder<ConversationsCubit, ConversationsState>(
              buildWhen: (prev, curr) =>
                  prev.pendingPaymentCount != curr.pendingPaymentCount,
              builder: (context, convState) {
                final isStylist = context.read<AppCubit>().state.isStylist;
                final count = convState.pendingPaymentCount ?? 0;
                if (isStylist || count <= 0) {
                  return const SizedBox.shrink();
                }
```
Fed by a 4-second poll of `GET /conversations/pending-payments-count`:
`conversations_cubit.dart:314-337` (timer) → `:367-378`
```dart
  Future<void> _fetchPendingPaymentsCount() async {
    final result = await _profileRepository.getPendingPaymentsCount();
    result.when(
      success: (count) {
        emit(state.copyWith(pendingPaymentCount: count));
      },
      failure: (_) {
        // Silently ignore — endpoint may not exist yet in this env, and next
        // tick retries once it does.
      },
```
Endpoint + parse: `snip_fair_backend_remote_source.dart:1226-1234` (`AuthPath.conversationsPendingPaymentsCount` = `'/conversations/pending-payments-count'`, `:81-82`), reading `response.data['pending_count']`.

Other pending-payment surfaces that do exist:
- "ACTION REQUIRED" chip on the payment-request card, customer-only: `payment_request_card.dart:157-178`.
- Notifications list handles `type: 'payment_request'` and routes to the conversation list: `notifications_screen.dart:203-209`.

**Why this may read as "not implemented" to the client:** the failure branch is a deliberate silent no-op, and `pendingPaymentCount` stays `null` → `count = 0` → `SizedBox.shrink()`. If `/conversations/pending-payments-count` 404s in prod, the indicator is simply absent with no error anywhere in the UI. Note also that the indicator is guarded by `context.read<AppCubit>().state.isStylist` — that one **is** the correct provider instance, so the role check here is sound.

**Cross-repo dependency:** endpoint deployment + the `pending_count` key name. **Runtime check:** watch the `LogInterceptor` output for `GET /conversations/pending-payments-count` while a pending request exists — a 404/500 there, or a response whose key is not `pending_count`, explains a missing indicator with zero app changes needed.

---

## One-line verdicts

1. **[BUG]** — endpoints and parsing correct, no status/date filter, but both list screens render the error state as "No Appointments found", and appointments are never refetched on login (only profile/wallet are).
2 & 7. **[BUG]** — full FCM stack (token registration, foreground local notification, background/terminated handlers) is implemented; broken: terminated-state taps don't navigate (callback set after bootstrap fires it), and the conversation list row still has only the purple text (a global badge exists, no per-row count). Whether the backend sends the push at all is unverified.
3. **[BUG]** — appointment selection is a hard client-side gate (required dropdown + disabled Send + a status allow-list excluding `completed`); `appointment_id` is optional on the wire, so this is app-side and removable.
4. **[NOT IMPLEMENTED — by design]** — no app-side email trigger; entirely a `POST /customer/appointment/book` side effect in the backend repo.
5 & 8 (wallet). **[BUG]** — the customer "In Escrow" tile and the stylist escrow breakdown (`/stylist/earnings/escrow`, with a visible status-code error view) are real and wired, but nothing refreshes after paying a payment request because `_refreshMoneyStateAfterPay` reads factory-registered cubits and its role guard is always false.
6. **[OK]** — payment-history screen exists, calls `GET /wallet/transactions`, renders pending/unknown types; caveats: no self-initiated first fetch, same error-as-empty masking, export icon is decorative.
8 (link). **[NOT IMPLEMENTED]** — zero deep-link support: no `app_links`/`uni_links`, no VIEW intent filter, no `associated-domains` entitlement; an email link cannot open the app.
9. **[CANNOT DETERMINE STATICALLY — needs a live `GET /conversations/pending-payments-count` response]** — a dedicated badge exists and polls every 4 s, but its failure branch is a silent no-op, so a 404 or a key other than `pending_count` renders it invisible with no error.

**Overriding caveat:** the tree is dirty (83 changed paths, no tag). Everything above describes the working copy, not a shipped build.
