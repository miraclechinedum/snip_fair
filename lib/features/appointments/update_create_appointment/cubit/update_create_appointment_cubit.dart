import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/services/location_service.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/utils/peach_payment_log.dart';
import 'package:snip_fair/core/services/peach_deposit_reconciler.dart';
import 'package:snip_fair/core/domain/entities/tip/tip_response.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/data/card_tip_attempt_store.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/data/card_tip_recovery.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/utils/app_extensions.dart';
import 'package:snip_fair/core/domain/entities/geo_place.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/checkout_payment_data.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/payment_reconciliation.dart';
import 'package:snip_fair/core/domain/entities/seller_details/seller_details.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio.dart';
import 'package:snip_fair/core/domain/entities/customer_appointment_list/customer_appointment.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';

part 'update_create_appointment_state.dart';

@Injectable()
class UpdateCreateAppointmentCubit extends Cubit<UpdateCreateAppointmentState> {
  UpdateCreateAppointmentCubit(
    this._appointmentRepository, {
    CardTipRecovery? tipRecovery,
    @ignoreParam Future<LocationRefreshResult> Function()? refreshLocation,
  })  : _refreshLocation = refreshLocation ?? _refreshDeviceLocation,
        _tipRecovery = tipRecovery ??
            CardTipRecovery(
              _appointmentRepository,
              store: MemoryCardTipAttemptStore(),
            ),
        super(UpdateCreateAppointmentState.initial()) {
    _tipEvents = _tipRecovery.events.listen(_onTipRecoveryEvent);
  }

  final AppointmentRepository _appointmentRepository;

  /// Sends the customer's current position, so the stylist's distance is
  /// measured from where they are now.
  final Future<LocationRefreshResult> Function() _refreshLocation;

  static Future<LocationRefreshResult> _refreshDeviceLocation() =>
      getIt.isRegistered<LocationService>()
          ? getIt<LocationService>().refreshLocation()
          : Future.value(LocationRefreshResult.unavailable);

  /// The app-wide record of unresolved card tips (persisted, shared with
  /// start-up recovery). Provided by DI; a private one only in tests.
  final CardTipRecovery _tipRecovery;
  late final StreamSubscription<CardTipCheck> _tipEvents;

  /// Identifies this cubit's own checks among [CardTipRecovery.events].
  final Object _tipSource = Object();

  @override
  Future<void> close() async {
    await _tipEvents.cancel();
    return super.close();
  }

  late BuildContext context;

  void initialize(
    BuildContext context, {
    String? portfolioId,
    String? appointmentId,
  }) {
    this.context = context;
    if (portfolioId != null) {
      fetchPortfolioById(portfolioId);
      unawaited(_refreshDistance());
    } else if (appointmentId != null) {
      fetchAppointmentById(appointmentId);
    }
  }

  Future<void> fetchPortfolioById(
    String portfolioId, {
    bool silent = false,
  }) async {
    if (!silent) {
      emit(state.copyWith(fetchPortfolioState: const ProcessState.loading()));
    }
    final response = await _appointmentRepository.customerFetchPortfolioById(
      id: portfolioId,
    );
    if (isClosed) return;
    response.when(
      success: (data) {
        emit(state.copyWith(fetchPortfolioState: ProcessState.success(data)));
        _fetchStylistDetailsById(data.userId.toString());
      },
      failure: (error) {
        if (!silent) {
          emit(state.copyWith(fetchPortfolioState: ProcessState.error(error)));
        }
      },
    );
  }

  Future<void> fetchAppointmentById(
    String appointmentId, {
    bool silent = false,
  }) async {
    if (!silent) {
      emit(
        state.copyWith(
          fetchAppointmentState: const ProcessState.loading(),
        ),
      );
    }
    final response =
        await _appointmentRepository.getCustomerAppointmentById(appointmentId);
    if (isClosed) return;
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            fetchAppointmentState: ProcessState.success(data),
          ),
        );
        if (data.createdAt != null) {
          emit(state.copyWith(selectedDate: data.appointmentDateTime));
        }
        if (data.appointmentTime != null) {
          final parsedTime = TimeOfDay(
            hour: int.parse(data.appointmentTime!.split(':')[0]),
            minute: int.parse(data.appointmentTime!.split(':')[1]),
          );
          emit(state.copyWith(selectedTime: parsedTime));
        }
        onNotesChanged(data.extra?.toString() ?? '');
        fetchPortfolioById(
          data.portfolioId.toString(),
        );
        _resumeTipAttempt(appointmentId);
      },
      failure: (error) {
        if (!silent) {
          emit(
            state.copyWith(
              fetchAppointmentState: ProcessState.error(error),
            ),
          );
        }
      },
    );
  }

  /// Before booking: refresh the customer's location (bounded, never
  /// prompting, never blocking the booking) and, when a new position was
  /// sent, the stylist's distance from it.
  Future<void> _refreshDistance() async {
    LocationRefreshResult result;
    try {
      result = await _refreshLocation();
    } catch (_) {
      return;
    }
    if (isClosed || result != LocationRefreshResult.sent) return;
    final stylistId = state.fetchPortfolioState.data?.userId;
    if (stylistId == null || !state.fetchSellerDetailsState.hasSuccess) {
      // The stylist is still loading and will be measured from the new
      // position.
      return;
    }
    await _fetchStylistDetailsById(stylistId.toString(), silent: true);
  }

  Future<void> _fetchStylistDetailsById(
    String stylistId, {
    bool silent = false,
  }) async {
    if (!silent) {
      emit(
        state.copyWith(
          fetchSellerDetailsState: const ProcessState.loading(),
        ),
      );
    }
    final response =
        await _appointmentRepository.customerFetchStylistById(stylistId);
    if (isClosed) return;
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            fetchSellerDetailsState: ProcessState.success(data),
          ),
        );
      },
      failure: (error) {
        if (!silent) {
          emit(
            state.copyWith(
              fetchSellerDetailsState: ProcessState.error(error),
            ),
          );
        }
      },
    );
  }

  void onSelectDate(DateTime date) {
    if (state.fetchAppointmentState.hasSuccess) return;

    emit(state.copyWith(selectedDate: date));
  }

  void onSelectTime(TimeOfDay time) {
    if (state.fetchAppointmentState.hasSuccess) return;

    emit(state.copyWith(selectedTime: time));
  }

  void onAddressChanged(String address) {
    emit(state.copyWith(address: address));
  }

  /// The address field's selection: a picked suggestion keeps its
  /// coordinates; an address typed by hand has none (null coordinates); a
  /// cleared field clears the address.
  void onPlaceSelected(GeoPlace? place) {
    if (place == null) {
      emit(state.copyWith(clearAddress: true));
      return;
    }
    emit(
      state.copyWith(
        address: place.address,
        addressPlace: place.hasValidCoordinates ? place : null,
      ),
    );
  }

  void onNotesChanged(String notes) {
    emit(state.copyWith(notes: notes));
  }

  void setPaymentMethod(String method) {
    if (method != 'wallet' && method != 'card') return;
    emit(state.copyWith(paymentMethod: method));
  }

  Future<void> createAppointment() async {
    if (state.paymentMethod == 'card') {
      return initializeCardPayment();
    }
    emit(
      state.copyWith(
        updateOrCreateAppointmentState: const ProcessState.loading(),
      ),
    );
    final localizations = MaterialLocalizations.of(context);
    final response = await _appointmentRepository.createAppointment(
      portfolioId: state.fetchPortfolioState.data!.id!.toString(),
      date: DateFormat('yyyy-MM-dd').format(state.selectedDate!),
      time: localizations.formatTimeOfDay(state.selectedTime!),
      note: state.notes,
      address: state.address,
    );
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            updateOrCreateAppointmentState: const ProcessState.success(true),
            fetchAppointmentState: ProcessState.success(data),
          ),
        );
      },
      failure: (error) {
        emit(
          state.copyWith(
            updateOrCreateAppointmentState: ProcessState.error(error),
          ),
        );
      },
    );
  }

  Future<void> initializeCardPayment() async {
    if (state.isCardPaymentBusy || state.activeCardCheckout != null) return;
    peachLog('Card payment initialization started');
    emit(
      state.copyWith(
        cardPaymentPhase: CardPaymentPhase.initializing,
        cardCheckoutState: const ProcessState.loading(),
      ),
    );
    final retryId = state.retryAppointmentId;
    if (retryId != null) {
      peachLog('Retrying card payment for appointment=$retryId');
    }
    final localizations = MaterialLocalizations.of(context);
    final response = retryId != null
        ? await _appointmentRepository.retryAppointmentCardPayment(retryId)
        : await _appointmentRepository.createAppointmentWithCard(
            portfolioId: state.fetchPortfolioState.data!.id!.toString(),
            date: DateFormat('yyyy-MM-dd').format(state.selectedDate!),
            time: localizations.formatTimeOfDay(state.selectedTime!),
            note: state.notes,
            address: state.address,
          );
    response.when(
      success: (paymentData) {
        if (!paymentData.canOpenCheckout) {
          peachLog(
            'Checkout not openable: '
            'deposit=${paymentData.depositId ?? 'none'} '
            'initialized=${paymentData.isInitialized ?? false}',
          );
          emit(state.copyWith(
            cardPaymentPhase: CardPaymentPhase.failed,
            cardCheckoutState: const ProcessState.error(
              'Unable to start payment. Please try again.',
            ),
          ));
          return;
        }
        peachLog(
          'Checkout created: deposit=${paymentData.depositId} '
          'appointment=${paymentData.appointmentId ?? 'pending'} '
          'checkout=${paymentData.checkoutId ?? 'none'}',
        );
        peachLog(
          'Redirect URL: ${redactedCheckoutUrl(paymentData.redirectUrl)}',
        );
        emit(
          state.copyWith(
            cardPaymentPhase: CardPaymentPhase.checkoutOpen,
            cardCheckoutState: ProcessState.success(paymentData),
          ),
        );
      },
      failure: (error) {
        peachLog('Card payment initialization failed');
        // A retry refused because the booking is paid, expired or not payable
        // by card can never succeed: stop retrying that booking.
        final code = error.responseBody?['code'];
        final bookingClosed = retryId != null &&
            const [
              'APPOINTMENT_ALREADY_PAID',
              'APPOINTMENT_EXPIRED',
              'APPOINTMENT_NOT_PAYABLE',
            ].contains(code);
        emit(
          state.copyWith(
            cardPaymentPhase: CardPaymentPhase.failed,
            cardCheckoutState: ProcessState.error(error),
            clearRetryAppointmentId: bookingClosed,
          ),
        );
      },
    );
  }

  /// Entry point for "the hosted checkout is no longer in front of the user".
  ///
  /// Closing checkout is never payment proof, so this only ever starts a
  /// Laravel reconciliation. Every branch either starts that reconciliation or
  /// moves the phase out of [CardPaymentPhase.checkoutOpen], so the booking
  /// button can never stay in its loading state after checkout returns.
  Future<void> onCardCheckoutClosed() async {
    final checkout = state.activeCardCheckout;
    if (checkout?.depositId == null) {
      peachLog('Checkout close ignored: no deposit to reconcile');
      _failOutOfCheckoutOpen('no deposit id available');
      return;
    }
    if (state.cardPaymentPhase == CardPaymentPhase.verifying) {
      peachLog('Checkout close ignored: reconciliation already running');
      return;
    }
    if (state.cardPaymentPhase.isTerminal) {
      peachLog(
        'Checkout close ignored: already settled as '
        '${state.cardPaymentPhase.name}',
      );
      return;
    }
    peachLog('Hosted checkout closed, starting reconciliation');
    await reconcileCardPayment();
  }

  /// Last-resort transition so a stuck [CardPaymentPhase.checkoutOpen] can
  /// never keep the booking button spinning. The deposit is deliberately left
  /// on state — `unknown` is retryable via "Check Payment Status".
  void _failOutOfCheckoutOpen(String reason) {
    if (isClosed) return;
    if (state.cardPaymentPhase != CardPaymentPhase.checkoutOpen &&
        state.cardPaymentPhase != CardPaymentPhase.initializing) {
      return;
    }
    peachLog('Phase -> unknown ($reason)');
    emit(
      state.copyWith(
        cardPaymentPhase: CardPaymentPhase.unknown,
        cardVerificationState: const ProcessState.error(
          paymentUnconfirmedMessage,
        ),
      ),
    );
  }

  /// Reconciles the current attempt against
  /// `GET /customer/payment/peach/{depositId}/status`.
  ///
  /// Guaranteed to leave [CardPaymentPhase.verifying] on every path — including
  /// a thrown exception — so the booking button always stops spinning.
  Future<void> reconcileCardPayment({
    bool automatic = true,
    CheckoutPaymentData? attempt,
  }) async {
    final checkout = attempt ?? state.activeCardCheckout;
    if (checkout?.depositId == null) {
      peachLog('Reconciliation skipped: attempt has no deposit id');
      _failOutOfCheckoutOpen('reconciliation had no deposit id');
      return;
    }
    if (state.cardPaymentPhase == CardPaymentPhase.verifying) {
      peachLog('Reconciliation skipped: a verification is already running');
      return;
    }
    emit(
      state.copyWith(
        cardPaymentPhase: CardPaymentPhase.verifying,
        cardVerificationState: const ProcessState.loading(),
      ),
    );
    try {
      await _verifyCardDeposit(checkout!, automatic: automatic);
    } catch (e) {
      peachLog('Reconciliation threw: ${e.runtimeType}');
    } finally {
      if (!isClosed && state.cardPaymentPhase == CardPaymentPhase.verifying) {
        peachLog('Phase -> unknown (reconciliation ended without a verdict)');
        emit(
          state.copyWith(
            cardPaymentPhase: CardPaymentPhase.unknown,
            cardVerificationState: const ProcessState.error(
              paymentUnconfirmedMessage,
            ),
          ),
        );
      }
      if (!isClosed) {
        peachLog('Final card payment phase=${state.cardPaymentPhase.name}');
      }
    }
  }

  /// Shown whenever Laravel could not tell whether the payment went through.
  static const paymentUnconfirmedMessage =
      "We couldn't confirm your payment status yet. Your payment has not been "
      'confirmed. Please check again shortly.';

  /// Spacing between automatic verification attempts.
  @visibleForTesting
  static Duration cardReconcileRetryGap = const Duration(seconds: 2);

  /// Polling body for [reconcileCardPayment]. Never called directly so the
  /// phase bookkeeping in [reconcileCardPayment] always applies.
  ///
  /// Booking keeps its own success rule (`successful` *and* `settled`); the
  /// shared [PeachDepositReconciler] only does the polling.
  Future<void> _verifyCardDeposit(
    CheckoutPaymentData checkout, {
    required bool automatic,
  }) async {
    final check = await PeachDepositReconciler(
      _appointmentRepository.reconcilePeachPayment,
    ).reconcile(
      checkout.depositId!,
      isVerified: (payment) => payment.isSuccessful,
      retryDelays: automatic
          ? [cardReconcileRetryGap, cardReconcileRetryGap]
          : const [],
      shouldStop: () => isClosed,
      logLabel: 'deposit',
    );
    if (isClosed) {
      peachLog('Reconciliation stopped: booking screen already disposed');
      return;
    }

    final lastSeen = check.payment;
    if (check.verdict == PeachDepositVerdict.verified) {
      peachLog('Appointment payment confirmed');
      emit(state.copyWith(
        cardPaymentPhase: CardPaymentPhase.successful,
        cardVerificationState: ProcessState.success(lastSeen!),
        clearRetryAppointmentId: true,
      ));
      final appointmentId = lastSeen.appointmentId ?? checkout.appointmentId;
      if (appointmentId != null) {
        peachLog('Refreshing appointment=$appointmentId');
        await fetchAppointmentById(appointmentId, silent: true);
      }
      _refreshWalletAfterCardSettlement();
      return;
    }

    if (lastSeen != null) {
      final phase = check.verdict == PeachDepositVerdict.failed
          ? CardPaymentPhase.failed
          : check.verdict == PeachDepositVerdict.cancelled
              ? CardPaymentPhase.cancelled
              : CardPaymentPhase.pending;
      peachLog('Appointment payment not settled: result=${phase.name}');
      emit(
        state.copyWith(
          cardPaymentPhase: phase,
          cardVerificationState: ProcessState.success(lastSeen),
          // Laravel says the SAME booking may be paid again: booking by card
          // now retries it instead of creating a second booking. An older
          // server that does not say keeps the previous behaviour.
          retryAppointmentId: phase != CardPaymentPhase.pending &&
                  lastSeen.canRetry == true
              ? lastSeen.appointmentId ?? checkout.appointmentId
              : null,
          clearRetryAppointmentId:
              phase == CardPaymentPhase.pending || lastSeen.canRetry != true,
          // A definitive failure or cancellation ends this attempt: release
          // the checkout so the customer can retry. Pending keeps it, so an
          // unconfirmed charge is never followed by a second checkout.
          cardCheckoutState: phase == CardPaymentPhase.pending
              ? null
              : const ProcessState.init(null),
        ),
      );
      // An opened booking shows its card payment state: refresh it.
      final appointmentId = lastSeen.appointmentId ?? checkout.appointmentId;
      if (state.fetchAppointmentState.hasSuccess && appointmentId != null) {
        await fetchAppointmentById(appointmentId, silent: true);
      }
    } else {
      peachLog('Appointment payment status unavailable: result=unknown');
      emit(
        state.copyWith(
          cardPaymentPhase: CardPaymentPhase.unknown,
          cardVerificationState:
              const ProcessState.error(paymentUnconfirmedMessage),
        ),
      );
    }
  }

  /// Re-pulls the customer's wallet and transaction history once a card
  /// booking settles.
  ///
  /// The wallet-top-up path already did this; the card-booking path did not,
  /// which is why a freshly paid card booking showed neither the new escrow
  /// balance nor the payment row until the app was relaunched.
  ///
  /// Read-only: both calls are plain GETs. Nothing here computes or
  /// synthesises a balance — Laravel stays authoritative, and this does not
  /// touch Peach settlement.
  void _refreshWalletAfterCardSettlement() {
    peachLog('Refreshing customer wallet + transactions after settlement');
    getIt<CustomerProfileMgtCubit>()
      ..getWallet(true)
      ..getWalletTransactions();
  }

  /// What the customer is told after a card payment check.
  static String cardPaymentMessage(
    CardPaymentPhase phase, {
    bool canRetry = false,
  }) =>
      switch (phase) {
        CardPaymentPhase.successful =>
          'Payment verified. Awaiting stylist approval.',
        CardPaymentPhase.pending =>
          'Peach has not confirmed your payment yet. Please check again '
              'shortly.',
        CardPaymentPhase.cancelled => canRetry
            ? 'Payment was cancelled. Your appointment has not been paid. '
                'You can retry the payment.'
            : 'Payment was cancelled. Your appointment has not been paid.',
        CardPaymentPhase.failed => canRetry
            ? 'Payment failed. Your appointment has not been paid. '
                'You can retry the payment.'
            : 'Payment failed. Your appointment has not been paid.',
        _ => paymentUnconfirmedMessage,
      };

  /// "Retry Payment" on an unpaid booking whose last card payment Peach
  /// confirmed cancelled or failed: a new attempt for THIS booking. Refused
  /// by Laravel (and never started here) while an attempt may still be paid.
  Future<void> retryAppointmentPayment(String appointmentId) async {
    if (state.isCardPaymentBusy || state.hasUnresolvedCardPayment) return;
    emit(
      state.copyWith(
        retryAppointmentId: appointmentId,
        cardCheckoutState: const ProcessState.init(null),
      ),
    );
    await initializeCardPayment();
  }

  /// "Check Payment Status" on an opened booking whose latest card payment
  /// Peach has not confirmed yet. Read-only: never starts a payment.
  Future<void> checkAppointmentPayment({
    required String appointmentId,
    required String depositId,
  }) =>
      reconcileCardPayment(
        automatic: false,
        attempt: CheckoutPaymentData(
          appointmentId: appointmentId,
          depositId: depositId,
        ),
      );

  void clearCardPaymentAttempt() {
    if (!state.cardPaymentPhase.isTerminal) return;
    emit(
      state.copyWith(
        cardPaymentPhase: CardPaymentPhase.idle,
        cardCheckoutState: const ProcessState.init(null),
        cardVerificationState: const ProcessState.init(null),
      ),
    );
  }

  Future<void> cancelAppointment() async {
    emit(state.copyWith(cancelBookingState: const ProcessState.loading()));
    final response = await _appointmentRepository.updateCustomerAppointment(
      state.fetchAppointmentState.data!.id!.toString(),
      verdict: 'cancel',
    );

    response.when(
      success: (data) {
        emit(
          state.copyWith(
            cancelBookingState: const ProcessState.success(true),
          ),
        );
      },
      failure: (error) {
        emit(state.copyWith(cancelBookingState: ProcessState.error(error)));
      },
    );
  }

  Future<void> rescheduleAppointment() async {
    emit(state.copyWith(rescheduleBookingState: const ProcessState.loading()));
    final response = await _appointmentRepository.updateCustomerAppointment(
      state.fetchAppointmentState.data!.id!.toString(),
      verdict: 'reschedule',
    );

    response.when(
      success: (data) {
        emit(
          state.copyWith(
            rescheduleBookingState: const ProcessState.success(true),
          ),
        );
      },
      failure: (error) {
        emit(state.copyWith(rescheduleBookingState: ProcessState.error(error)));
      },
    );
  }

  Future<void> reviewAppointment({required int rating, String? comment}) async {
    Fluttertoast.showToast(msg: 'Submitting review...');
    final response = await _appointmentRepository.reviewCustomerAppointment(
      state.fetchAppointmentState.data!.id!.toString(),
      rating: rating,
      comment: comment,
    );

    response.when(
      success: (data) {
        Fluttertoast.showToast(msg: 'Review submitted');
      },
      failure: (error) {
        Fluttertoast.showToast(msg: 'Failed to submit review');
      },
    );
  }

  Future<void> submitDispute(
      {required String comment, required List<String> images}) async {
    Fluttertoast.showToast(msg: 'Initiating dispute...');
    final response = await _appointmentRepository.disputeCustomerAppointment(
      state.fetchAppointmentState.data!.id!.toString(),
      images: images,
      comment: comment,
    );

    response.when(
      success: (data) {
        Fluttertoast.showToast(msg: 'Dispute submitted');
      },
      failure: (error) {
        Fluttertoast.showToast(msg: 'Failed to submit dispute');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Tipping the stylist — wallet or card
  //
  // `POST /customer/appointment/{id}/tip` with `payment_method`:
  //   wallet → the tip is sent at once (`code: tipped`);
  //   card   → a Peach checkout (the booking's hosted checkout), then
  //            `GET /customer/payment/peach/{deposit}/status`, whose
  //            `tip.status` alone decides the outcome.
  // Balances are never computed here: wallet and booking are re-fetched.
  // ---------------------------------------------------------------------------

  /// Starts a tip of [amount] by [paymentMethod] (`wallet` or `card`).
  /// Refused while another tip is in progress or a card tip is unresolved.
  Future<TipStartResult> startTip(
    double amount, {
    required String paymentMethod,
  }) async {
    final current = state.tipPayment;
    if (current.phase.isBusy) return TipStartResult.busy;
    // A card tip saved earlier (even before an app restart) that is not yet
    // decided blocks a new tip: it is checked, never paid again.
    final bookingId = state.fetchAppointmentState.data?.id?.toString();
    final saved =
        bookingId == null ? null : _tipRecovery.unresolvedFor(bookingId);
    if (saved != null && !current.phase.isUnresolved) {
      _setTip(
        TipPaymentPhase.pending,
        checkout: _checkoutFor(saved),
        amount: saved.amount,
        paymentMethod: 'card',
        message: tipUnresolvedMessage,
      );
      unawaited(verifyTipPayment(automatic: false));
      return TipStartResult.unresolved;
    }
    if (current.phase.isUnresolved) {
      _setTip(
        current.phase,
        checkout: current.checkout,
        amount: current.amount,
        paymentMethod: current.paymentMethod,
        message: tipUnresolvedMessage,
      );
      return TipStartResult.unresolved;
    }
    final appointmentId = state.fetchAppointmentState.data?.id?.toString();
    if (appointmentId == null) {
      _setTip(TipPaymentPhase.failed, message: tipFailedMessage);
      return TipStartResult.failed;
    }

    emit(
      state.copyWith(
        tipAppointmentState: const ProcessState.loading(),
        tipPayment: _tipProgress(
          TipPaymentPhase.submitting,
          amount: amount,
          paymentMethod: paymentMethod,
        ),
      ),
    );
    final response = await _appointmentRepository.tipCustomerAppointment(
      appointmentId,
      amount: amount,
      paymentMethod: paymentMethod,
    );
    if (isClosed) return TipStartResult.failed;

    return response.when(
      success: (tip) async {
        if (paymentMethod == 'wallet' && tip.isTipped) {
          emit(
            state.copyWith(
              tipAppointmentState: ProcessState.success(tip),
              tipPayment: _tipProgress(
                TipPaymentPhase.tipped,
                amount: tip.tipAmount,
                paymentMethod: paymentMethod,
                message: tip.message.isNotEmpty ? tip.message : tipSentMessage,
              ),
            ),
          );
          _refreshAfterTip(appointmentId);
          return TipStartResult.tipped;
        }
        if (paymentMethod == 'card' && tip.isCheckoutStarted) {
          peachLog('Tip checkout created deposit=${tip.checkout!.depositId}');
          // Saved before the checkout opens: if the app is closed or killed
          // during checkout, start-up recovery still asks Laravel.
          await _tipRecovery.record(
            CardTipAttempt(
              appointmentId: appointmentId,
              depositId: tip.checkout!.depositId!,
              checkoutId: tip.checkout!.checkoutId,
              amount: amount,
              createdAt: CardTipRecovery.clock(),
            ),
          );
          _setTip(
            TipPaymentPhase.checkoutOpen,
            checkout: tip.checkout,
            amount: amount,
            paymentMethod: paymentMethod,
          );
          return TipStartResult.checkoutStarted;
        }
        // A 2xx that is neither a sent tip nor an openable checkout.
        peachLog('Tip response unusable: code=${tip.code ?? 'none'}');
        _setTip(
          TipPaymentPhase.failed,
          amount: amount,
          paymentMethod: paymentMethod,
          message: tipFailedMessage,
        );
        return TipStartResult.failed;
      },
      failure: (error) {
        emit(state.copyWith(tipAppointmentState: ProcessState.error(error)));
        final (result, message) = _tipRefusal(error);
        _setTip(
          TipPaymentPhase.failed,
          amount: amount,
          paymentMethod: paymentMethod,
          message: message,
        );
        if (error.code == 'already_tipped') _refreshAfterTip(appointmentId);
        return result;
      },
    );
  }

  /// Each documented refusal, as Laravel means it. Nothing was paid.
  static (TipStartResult, String) _tipRefusal(RemoteException error) {
    final backend = (error.errorResponse?.message ?? '').trim();
    String orBackend(String fallback) =>
        error.kind == RemoteExceptionKind.server && backend.isNotEmpty
            ? backend
            : fallback;
    switch (error.code) {
      case 'payment_method_unavailable':
        return (TipStartResult.cardUnavailable, tipCardUnavailableMessage);
      case 'insufficient_wallet_balance':
        final balance = error.numberField('wallet_balance');
        return (
          TipStartResult.insufficientBalance,
          balance == null
              ? 'Your wallet balance is too low for this tip. '
                  'You can pay by card instead.'
              : 'Your wallet balance (${balance.toDouble().formatAmount()}) '
                  'is too low for this tip. You can pay by card instead.',
        );
      case 'already_tipped':
        return (
          TipStartResult.failed,
          orBackend('You have already tipped for this appointment.'),
        );
      case 'checkout_initialization_failed':
        return (
          TipStartResult.failed,
          orBackend('Card payment could not be started. '
              'You have not been charged.'),
        );
    }
    final status = error.statusCode;
    if (error.kind == RemoteExceptionKind.server &&
        status != null &&
        status >= 400 &&
        status < 500 &&
        status != 401 &&
        status != 404 &&
        backend.isNotEmpty) {
      // `not_tippable`, validation errors (422) and other refusals.
      return (TipStartResult.failed, backend);
    }
    return (TipStartResult.failed, tipFailedMessage);
  }

  /// The card tip's checkout is no longer in front of the customer. Closing
  /// it is never proof of payment: only Laravel's `tip.status` decides.
  Future<void> onTipCheckoutClosed() async {
    final phase = state.tipPayment.phase;
    if (phase != TipPaymentPhase.checkoutOpen && !phase.isUnresolved) return;
    await verifyTipPayment();
  }

  /// Spacing between automatic tip verification attempts.
  @visibleForTesting
  static Duration tipReconcileRetryGap = const Duration(seconds: 2);

  /// Checks the card tip with Laravel (after checkout, or Check Payment
  /// Status). Always leaves [TipPaymentPhase.verifying].
  Future<void> verifyTipPayment({bool automatic = true}) async {
    final current = state.tipPayment;
    final depositId = current.checkout?.depositId;
    if (depositId == null ||
        current.phase == TipPaymentPhase.verifying ||
        !(current.phase == TipPaymentPhase.checkoutOpen ||
            current.phase.isUnresolved)) {
      return;
    }
    final appointmentId =
        state.fetchAppointmentState.data?.id?.toString() ??
            _tipRecovery.unresolved
                .where((a) => a.depositId == depositId)
                .firstOrNull
                ?.appointmentId;
    if (appointmentId == null) return;
    _setTip(
      TipPaymentPhase.verifying,
      checkout: current.checkout,
      amount: current.amount,
      paymentMethod: current.paymentMethod,
    );
    try {
      final result = await _tipRecovery.check(
        appointmentId,
        retryDelays: automatic
            ? [tipReconcileRetryGap, tipReconcileRetryGap]
            : const [],
        source: _tipSource,
      );
      if (isClosed) return;
      _applyTipVerdict(result, current);
    } catch (e) {
      peachLog('Tip verification threw: ${e.runtimeType}');
    } finally {
      if (!isClosed && state.tipPayment.phase == TipPaymentPhase.verifying) {
        _setTip(
          TipPaymentPhase.unknown,
          checkout: current.checkout,
          amount: current.amount,
          paymentMethod: current.paymentMethod,
          message: tipUnconfirmedMessage,
        );
      }
    }
  }

  /// Turns Laravel's verdict into the booking's tip state. Only `tipped`
  /// says the stylist was tipped.
  void _applyTipVerdict(
    CardTipCheck result,
    TipPaymentProgress attempt, {
    bool announced = false,
  }) {
    final amount = result.amount ?? attempt.amount;
    switch (result.verdict) {
      case CardTipVerdict.tipped:
        _setTip(
          TipPaymentPhase.tipped,
          amount: amount,
          paymentMethod: 'card',
          message: result.message ?? tipSentMessage,
          announced: announced,
        );
        _refreshAfterTip(result.appointmentId);
      case CardTipVerdict.creditedToWallet:
        _setTip(
          TipPaymentPhase.creditedToWallet,
          amount: amount,
          paymentMethod: 'card',
          message: tipCreditedToWalletMessage,
          announced: announced,
        );
        _refreshAfterTip(result.appointmentId);
      case CardTipVerdict.notPaid:
        _setTip(
          TipPaymentPhase.notPaid,
          amount: amount,
          paymentMethod: 'card',
          message: result.message ?? tipNotPaidMessage,
          announced: announced,
        );
      case CardTipVerdict.pending:
        _setTip(
          TipPaymentPhase.pending,
          checkout: attempt.checkout,
          amount: amount,
          paymentMethod: 'card',
          message: tipPendingMessage,
          announced: announced,
        );
      case CardTipVerdict.unknown:
        _setTip(
          TipPaymentPhase.unknown,
          checkout: attempt.checkout,
          amount: amount,
          paymentMethod: 'card',
          message: tipUnconfirmedMessage,
          announced: announced,
        );
      case CardTipVerdict.unverifiable:
        _setTip(
          TipPaymentPhase.failed,
          amount: amount,
          paymentMethod: 'card',
          message: "We couldn't verify this card payment. If you were "
              'charged, please contact Snipfair support.',
          announced: announced,
        );
    }
  }

  /// A check of this booking's card tip run elsewhere (start-up or resume
  /// recovery, or another screen): reflect it without announcing it again.
  void _onTipRecoveryEvent(CardTipCheck event) {
    if (isClosed || identical(event.source, _tipSource)) return;
    final bookingId = state.fetchAppointmentState.data?.id?.toString();
    if (bookingId == null || event.appointmentId != bookingId) return;
    final current = state.tipPayment;
    // While the checkout is still open, only a final outcome is applied;
    // closing it then checks again.
    if (current.phase == TipPaymentPhase.checkoutOpen &&
        !event.verdict.isTerminal) {
      return;
    }
    if (current.phase == TipPaymentPhase.verifying) return;
    _applyTipVerdict(event, current, announced: true);
  }

  /// Opening a booking with an unresolved card tip shows it as pending and
  /// asks Laravel once (sharing any check already running).
  void _resumeTipAttempt(String appointmentId) {
    final saved = _tipRecovery.unresolvedFor(appointmentId);
    final phase = state.tipPayment.phase;
    if (saved == null || phase.isBusy || phase.isUnresolved) return;
    _setTip(
      TipPaymentPhase.pending,
      checkout: _checkoutFor(saved),
      amount: saved.amount,
      paymentMethod: 'card',
      message: tipPendingMessage,
      announced: true,
    );
    unawaited(verifyTipPayment(automatic: false));
  }

  static CheckoutPaymentData _checkoutFor(CardTipAttempt attempt) =>
      CheckoutPaymentData(
        isInitialized: true,
        processor: 'peachpayment',
        depositId: attempt.depositId,
        checkoutId: attempt.checkoutId,
      );

  /// Check Payment Status for this booking's undecided card tip, whether it
  /// started in this session or was saved by an earlier one.
  Future<void> checkUnresolvedTip() async {
    if (state.tipPayment.phase.isUnresolved) {
      return verifyTipPayment(automatic: false);
    }
    final bookingId = state.fetchAppointmentState.data?.id?.toString();
    if (bookingId != null) _resumeTipAttempt(bookingId);
  }

  /// Whether this booking has a card tip whose outcome is not yet known —
  /// in this session or saved from an earlier one.
  bool get hasUnresolvedCardTip {
    if (state.tipPayment.phase.isUnresolved) return true;
    final bookingId = state.fetchAppointmentState.data?.id?.toString();
    return bookingId != null && _tipRecovery.unresolvedFor(bookingId) != null;
  }

  /// Re-fetches the booking (its tip) from the server. The wallet and
  /// transactions are refreshed by the screen through the app's own
  /// `CustomerProfileMgtCubit` (see `TipOutcomePresenter`).
  void _refreshAfterTip(String appointmentId) {
    fetchAppointmentById(appointmentId, silent: true);
  }

  TipPaymentProgress _tipProgress(
    TipPaymentPhase phase, {
    CheckoutPaymentData? checkout,
    double? amount,
    String? paymentMethod,
    String? message,
    bool announced = false,
  }) =>
      TipPaymentProgress(
        phase: phase,
        checkout: checkout,
        amount: amount,
        paymentMethod: paymentMethod,
        message: message,
        revision: state.tipPayment.revision + 1,
        announced: announced,
      );

  void _setTip(
    TipPaymentPhase phase, {
    CheckoutPaymentData? checkout,
    double? amount,
    String? paymentMethod,
    String? message,
    bool announced = false,
  }) {
    if (isClosed) return;
    emit(
      state.copyWith(
        tipPayment: _tipProgress(
          phase,
          checkout: checkout,
          amount: amount,
          paymentMethod: paymentMethod,
          message: message,
          announced: announced,
        ),
      ),
    );
  }

  static const tipSentMessage =
      'Tip sent successfully. Thank you for appreciating your stylist!';
  static const tipFailedMessage =
      "We couldn't send your tip. Please try again.";
  static const tipCardUnavailableMessage =
      "Card tipping isn't available yet. Nothing was charged. "
      'You can tip from your wallet instead.';
  static const tipPendingMessage =
      'Your card payment has not been confirmed yet, so your tip has not '
      'been sent. Please check again shortly.';
  static const tipUnconfirmedMessage =
      "We couldn't confirm your card payment yet. Your tip has not been "
      'confirmed. Please check again shortly.';
  static const tipUnresolvedMessage =
      'Your previous card tip is still being confirmed. '
      'Check its status before trying again.';
  static const tipNotPaidMessage =
      'The card payment was not completed. No tip was sent.';
  static const tipCreditedToWalletMessage =
      'Your card payment was received, but this booking had already been '
      'tipped through another payment, so your stylist did not receive this '
      'tip. The amount has been added to your Snipfair wallet instead.';
}

/// What starting a tip did.
enum TipStartResult {
  /// Wallet tip sent.
  tipped,

  /// Card checkout ready to open (nothing paid yet).
  checkoutStarted,

  /// Card tipping is switched off on the server; nothing was charged.
  cardUnavailable,
  insufficientBalance,

  /// An earlier card tip must be checked first.
  unresolved,
  busy,
  failed,
}
