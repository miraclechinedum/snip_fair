import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/utils/base/process_state.dart';
import 'package:snip_fair/core/utils/peach_payment_log.dart';
import 'package:snip_fair/core/domain/entities/tip/tip_response.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/checkout_payment_data.dart';
import 'package:snip_fair/core/domain/entities/checkout_payment/payment_reconciliation.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/domain/entities/seller_details/seller_details.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio.dart';
import 'package:snip_fair/core/domain/entities/customer_appointment_list/customer_appointment.dart';
import 'package:snip_fair/features/account/customer/profile_management/cubit/customer_profile_mgt_cubit.dart';

part 'update_create_appointment_state.dart';

@Injectable()
class UpdateCreateAppointmentCubit extends Cubit<UpdateCreateAppointmentState> {
  UpdateCreateAppointmentCubit(this._appointmentRepository)
      : super(UpdateCreateAppointmentState.initial());

  final AppointmentRepository _appointmentRepository;

  late BuildContext context;

  void initialize(
    BuildContext context, {
    String? portfolioId,
    String? appointmentId,
  }) {
    this.context = context;
    if (portfolioId != null) {
      fetchPortfolioById(portfolioId);
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
    final localizations = MaterialLocalizations.of(context);
    final response = await _appointmentRepository.createAppointmentWithCard(
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
        emit(
          state.copyWith(
            cardPaymentPhase: CardPaymentPhase.failed,
            cardCheckoutState: ProcessState.error(error),
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
          'We could not confirm your payment yet. Please try again shortly.',
        ),
      ),
    );
  }

  /// Reconciles the current attempt against
  /// `GET /customer/payment/peach/{depositId}/status`.
  ///
  /// Guaranteed to leave [CardPaymentPhase.verifying] on every path — including
  /// a thrown exception — so the booking button always stops spinning.
  Future<void> reconcileCardPayment({bool automatic = true}) async {
    final checkout = state.activeCardCheckout;
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
              'We could not confirm your payment yet. Please try again shortly.',
            ),
          ),
        );
      }
      if (!isClosed) {
        peachLog('Final card payment phase=${state.cardPaymentPhase.name}');
      }
    }
  }

  /// Polling body for [reconcileCardPayment]. Never called directly so the
  /// phase bookkeeping in [reconcileCardPayment] always applies.
  Future<void> _verifyCardDeposit(
    CheckoutPaymentData checkout, {
    required bool automatic,
  }) async {
    final attempts = automatic ? 3 : 1;
    const gap = Duration(seconds: 2);
    PaymentReconciliation? lastSeen;

    peachLog('Reconciling deposit=${checkout.depositId} attempts=$attempts');

    for (var i = 0; i < attempts; i++) {
      if (i > 0) await Future<void>.delayed(gap);
      peachLog('Reconcile request ${i + 1}/$attempts starting');
      final result = await _appointmentRepository
          .reconcilePeachPayment(checkout.depositId!);
      var isSuccessful = false;
      var terminal = false;
      result.when(
        success: (payment) {
          lastSeen = payment;
          isSuccessful = payment.isSuccessful;
          terminal = payment.isFailed || payment.isCancelled;
          peachLog(
            'status=${payment.status ?? 'unknown'} '
            'settled=${payment.settled ?? false} '
            'purpose=${payment.purpose ?? 'unknown'}',
          );
        },
        failure: (error) {
          peachLog(
            'Reconcile request failed for deposit=${checkout.depositId}',
          );
          if (error is RemoteException && error.statusCode == 503) {
            emit(state.copyWith(
              cardPaymentPhase: CardPaymentPhase.unknown,
              cardVerificationState: const ProcessState.error(
                'We could not confirm your payment yet. Please try again shortly.',
              ),
            ));
          }
        },
      );
      if (isSuccessful) {
        peachLog('Appointment payment confirmed');
        emit(state.copyWith(
          cardPaymentPhase: CardPaymentPhase.successful,
          cardVerificationState: ProcessState.success(lastSeen!),
        ));
        final appointmentId = lastSeen!.appointmentId ?? checkout.appointmentId;
        if (appointmentId != null) {
          peachLog('Refreshing appointment=$appointmentId');
          await fetchAppointmentById(appointmentId, silent: true);
        }
        _refreshWalletAfterCardSettlement();
        return;
      }
      if (terminal) break;
    }

    if (lastSeen != null) {
      final phase = lastSeen!.isFailed
          ? CardPaymentPhase.failed
          : lastSeen!.isCancelled
              ? CardPaymentPhase.cancelled
              : CardPaymentPhase.pending;
      peachLog('Appointment payment not settled: result=${phase.name}');
      emit(
        state.copyWith(
          cardPaymentPhase: phase,
          cardVerificationState: ProcessState.success(lastSeen!),
        ),
      );
    } else if (state.cardPaymentPhase != CardPaymentPhase.unknown) {
      peachLog('Appointment payment unconfirmed: result=unknown');
      emit(
        state.copyWith(
          cardPaymentPhase: CardPaymentPhase.unknown,
          cardVerificationState: const ProcessState.error(
            'We could not confirm your payment yet. Please try again shortly.',
          ),
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

  Future<void> tipAppointment(double amount) async {
    emit(state.copyWith(tipAppointmentState: const ProcessState.loading()));
    final id = state.fetchAppointmentState.data!.id!.toString();
    final response = await _appointmentRepository.tipCustomerAppointment(
      id,
      amount: amount,
    );

    response.when(
      success: (TipResponse data) {
        final appointment = state.fetchAppointmentState.data!;
        appointment.tipAmount = data.tipAmount;
        appointment.tippedAt = DateTime.now();
        emit(
          state.copyWith(
            tipAppointmentState: ProcessState.success(data),
            fetchAppointmentState: ProcessState.success(appointment),
          ),
        );
      },
      failure: (error) {
        emit(state.copyWith(tipAppointmentState: ProcessState.error(error)));
      },
    );
  }
}
