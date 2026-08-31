import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/theme/app_textstyle.dart';
import 'package:snip_fair/core/presentation/widgets/labeled_input.dart';
import 'package:snip_fair/core/domain/entities/apointment/appointment.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/features/conversations/cubit/conversations_cubit.dart';

/// Shows the payment request creation form as a modal bottom sheet.
void showPaymentRequestForm(
  BuildContext context, {
  required int recipientId,
  required String conversationId,
  int? appointmentId,
  VoidCallback? onSuccess,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<ConversationsCubit>(),
      child: _PaymentRequestFormSheet(
        recipientId: recipientId,
        conversationId: conversationId,
        appointmentId: appointmentId,
        onSuccess: onSuccess,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------

class _LineItem {
  _LineItem({
    required this.nameController,
    required this.priceController,
    required this.quantityController,
  });
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController quantityController;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
  }

  /// Quantity defaults to 1 when the field is blank so an existing muscle
  /// memory of "name + price only" still produces a valid line item.
  int get quantity {
    final parsed = int.tryParse(quantityController.text.trim());
    if (parsed == null || parsed < 1) return 1;
    return parsed;
  }

  Map<String, dynamic> toMap() => {
        'name': nameController.text.trim(),
        'unit_price': double.tryParse(priceController.text.trim()) ?? 0.0,
        'quantity': quantity,
      };
}

// ---------------------------------------------------------------------------

class _PaymentRequestFormSheet extends StatefulWidget {
  const _PaymentRequestFormSheet({
    required this.recipientId,
    required this.conversationId,
    this.appointmentId,
    this.onSuccess,
  });

  final int recipientId;
  final String conversationId;
  final int? appointmentId;
  final VoidCallback? onSuccess;

  @override
  State<_PaymentRequestFormSheet> createState() =>
      _PaymentRequestFormSheetState();
}

class _PaymentRequestFormSheetState extends State<_PaymentRequestFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_LineItem> _items = [];

  List<StylistAppointment> _appointments = [];
  bool _loadingAppointments = true;
  int? _selectedAppointmentId;

  /// True when the form was opened with a specific `appointmentId` that we
  /// were able to resolve against the eligible list — i.e. launched from an
  /// appointment details screen. The stylist already chose the appointment
  /// on that screen; re-picking would risk misattribution (two bookings on
  /// the same date look nearly identical), so we show it read-only.
  ///
  /// If the passed-in id turns out to be ineligible (wrong customer, closed
  /// status, deleted) `_fetchAppointments` clears the selection and this
  /// flips to false — the stylist then gets the normal optional picker
  /// rather than a dead end.
  bool get _isLocked =>
      widget.appointmentId != null && _selectedAppointmentId != null;

  /// Informational only. The backend accepts a payment request with a null /
  /// omitted `appointment_id`, so having no open appointments never blocks
  /// submission — it only changes the hint we render next to the picker.
  bool get _hasNoOpenAppointments =>
      !_loadingAppointments && _appointments.isEmpty;

  @override
  void initState() {
    super.initState();
    _addItem(); // start with one blank item
    _selectedAppointmentId = widget.appointmentId;
    _fetchAppointments();
  }

  /// Appointment statuses that are still active and therefore eligible for a
  /// new payment request. Matches the backend's server-side allow-list — the
  /// API returns 400 for a payment request against any other status, so the
  /// client and server stay aligned.
  ///
  /// Note the spelling: appointments use `canceled` (single L), which is
  /// different from the PaymentRequest status enum's `cancelled` (double L).
  /// It's implicitly rejected here because it's not in this set.
  static const _openAppointmentStatuses = {
    'processing',
    'pending',
    'approved',
    'confirmed',
  };

  /// Fails closed: a null / empty / non-open status is treated as NOT
  /// eligible. Safer than defaulting to eligible — a mislabelled appointment
  /// won't slip through and cause a 400 on submit.
  bool _isEligibleForPayment(StylistAppointment a) {
    final s = a.status?.toLowerCase();
    if (s == null || s.isEmpty) return false;
    return _openAppointmentStatuses.contains(s);
  }

  Future<void> _fetchAppointments() async {
    final repo = getIt<AppointmentRepository>();
    final result = await repo.getStylistAppointments(
      customerId: widget.recipientId.toString(),
      perPage: 50,
    );
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        // (1) The endpoint has already scoped by `customer_id` server-side.
        // (2) Residual client-side filter keeps only appointments whose
        //     status is in the open allow-list.
        final eligible = (data.data ?? [])
            .where(_isEligibleForPayment)
            .toList(growable: false);
        setState(() {
          _appointments = eligible;
          _loadingAppointments = false;
          // Deliberately NO auto-select when exactly one appointment exists.
          // Linking money to a booking the stylist never picked is a silent
          // misattribution; "no appointment" is a legitimate, supported
          // outcome, so the default stays empty.
          if (_selectedAppointmentId != null &&
              !_appointments.any((a) => a.id == _selectedAppointmentId)) {
            // A pre-selected appointment id (from widget.appointmentId) was
            // passed in but is either not for this customer or is no longer
            // in an open status — clear it and fall back to the optional
            // picker instead of leaving a phantom selection.
            _selectedAppointmentId = null;
          }
        });
      case Failure():
        setState(() => _loadingAppointments = false);
    }
  }

  /// Builds the human-readable label for an appointment, used by both the
  /// dropdown items and the locked read-only display so they stay in sync.
  ///
  /// Primary line priority:
  ///   service name — date, amount    (e.g. "Cornrow Set — 08 Jul, R60.00")
  /// Fallback if no service name:
  ///   date — amount                  (e.g. "08 Jul — R60.00")
  /// Fallback if nothing usable:
  ///   "Appointment #<id>"
  ///
  /// Secondary is the booking ref (e.g. "BK-1783504974-10") when available.
  /// Callers decide whether to render it — the picker skips it to stay
  /// scannable, the locked card shows it for confirmation.
  ({String primary, String? secondary}) _labelFor(StylistAppointment apt) {
    final service = apt.portfolio?.title?.trim();
    final date = _formatAppointmentDate(apt);
    final amount = apt.amount != null
        ? 'R${apt.amount!.toDouble().toStringAsFixed(2)}'
        : null;

    String primary;
    if (service != null && service.isNotEmpty) {
      final tail = [
        if (date != null) date,
        if (amount != null) amount,
      ].join(', ');
      primary = tail.isEmpty ? service : '$service — $tail';
    } else if (date != null || amount != null) {
      primary = [
        if (date != null) date,
        if (amount != null) amount,
      ].join(' — ');
    } else {
      primary = 'Appointment #${apt.id}';
    }

    final ref = apt.bookingId?.toString();
    return (
      primary: primary,
      secondary: (ref != null && ref.isNotEmpty) ? ref : null,
    );
  }

  /// "08 Jul" if the appointment is in the current year; "08 Jul 2026"
  /// otherwise. Prefers the parsed DateTime; falls back to parsing the
  /// String date if the DateTime field is null.
  String? _formatAppointmentDate(StylistAppointment apt) {
    var dt = apt.appointmentDateTime;
    if (dt == null) {
      final s = apt.appointmentDate;
      if (s != null && s.isNotEmpty) {
        try {
          dt = DateTime.parse(s);
        } catch (_) {
          // Not an ISO date — give up rather than mangle the display.
        }
      }
    }
    if (dt == null) return null;
    final showYear = dt.year != DateTime.now().year;
    return DateFormat(showYear ? 'dd MMM yyyy' : 'dd MMM').format(dt);
  }

  /// Read-only display for the locked-mode case. The stylist sees which
  /// appointment the payment request will be attached to — same label
  /// formula as the dropdown items — but can't change it. Reached only
  /// when `_isLocked` is true, which already implies the pre-selected
  /// appointment resolved against `_appointments`.
  Widget _buildLockedAppointmentDisplay() {
    StylistAppointment? apt;
    for (final a in _appointments) {
      if (a.id == _selectedAppointmentId) {
        apt = a;
        break;
      }
    }
    if (apt == null) return const SizedBox.shrink();

    final labels = _labelFor(apt);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.grey1.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.grey1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 18.sp,
            color: Colors.grey.shade600,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  labels.primary,
                  style: AppTextStyle.body2.copyWith(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (labels.secondary != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    labels.secondary!,
                    style: AppTextStyle.body2.copyWith(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(
        _LineItem(
          nameController: TextEditingController(),
          priceController: TextEditingController(),
          quantityController: TextEditingController(text: '1'),
        ),
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item.')),
      );
      return;
    }

    final cubit = context.read<ConversationsCubit>();
    await cubit.createPaymentRequest(
      recipientId: widget.recipientId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      items: _items.map((i) => i.toMap()).toList(),
      appointmentId: _selectedAppointmentId,
    );

    if (!mounted) return;

    final state = cubit.state;
    if (state.createPaymentRequestState.hasSuccess) {
      cubit.resetCreatePaymentRequestState();
      Navigator.of(context).pop();
      widget.onSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: EdgeInsets.only(top: 12.h, bottom: 4.h),
                child: Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
              ),

              // Title bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    Text(
                      'Request Payment',
                      style: AppTextStyle.subTitle1.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(color: AppColors.grey1, height: 1),

              // Scrollable form body
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Appointment selector.
                        //
                        // Optional by contract: `POST /payment-requests`
                        // accepts a null / omitted `appointment_id`, so a
                        // stylist can bill for an additional service that
                        // isn't tied to any booking. Nothing here may block
                        // submission on the absence of a selection.
                        Text(
                          'Appointment (optional)',
                          style: AppTextStyle.body2.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        if (_loadingAppointments)
                          const Center(child: CircularProgressIndicator())
                        else if (_isLocked)
                          // Locked mode + eligible passed-in appointment:
                          // show a read-only display so the stylist can
                          // confirm the target booking without being able
                          // to reassign it to a nearly-identical sibling.
                          _buildLockedAppointmentDisplay()
                        else
                          DropdownButtonFormField<int?>(
                            key: const Key(
                              'payment_request_appointment_dropdown',
                            ),
                            value: _selectedAppointmentId,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 12.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide:
                                    const BorderSide(color: AppColors.grey1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide:
                                    const BorderSide(color: AppColors.grey1),
                              ),
                            ),
                            isExpanded: true,
                            items: [
                              // Always first, always available — this is the
                              // standalone / additional-service path.
                              DropdownMenuItem<int?>(
                                child: Text(
                                  'No appointment — additional service',
                                  style: AppTextStyle.body2.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ..._appointments.map((apt) {
                                final label = _labelFor(apt).primary;
                                return DropdownMenuItem<int?>(
                                  value: apt.id,
                                  child: Text(
                                    label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedAppointmentId = v),
                            // No validator — an unselected appointment is a
                            // valid, supported request.
                          ),
                        if (_hasNoOpenAppointments && !_loadingAppointments)
                          Padding(
                            padding: EdgeInsets.only(top: 6.h),
                            child: Text(
                              'This customer has no active bookings, so this '
                              'will be sent as an additional-service request.',
                              style: AppTextStyle.body2.copyWith(
                                fontSize: 11.sp,
                                color: Colors.grey.shade600,
                                height: 1.35,
                              ),
                            ),
                          ),
                        SizedBox(height: 14.h),

                        // Title
                        LabeledInputField(
                          key: const Key('payment_request_title'),
                          label: 'Title *',
                          controller: _titleController,
                          onChanged: (_) {},
                          hintText: 'e.g. Additional products used',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Title is required'
                              : null,
                        ),
                        SizedBox(height: 14.h),

                        // Description (optional)
                        LabeledInputField(
                          label: 'Description (optional)',
                          controller: _descriptionController,
                          onChanged: (_) {},
                          hintText: 'Brief description of the request',
                          maxLines: 3,
                          minLines: 2,
                        ),
                        SizedBox(height: 20.h),

                        // Items header
                        Row(
                          children: [
                            Text(
                              'Items',
                              style: AppTextStyle.subTitle2.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _addItem,
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 18,
                                color: AppColors.primaryColor,
                              ),
                              label: Text(
                                'Add item',
                                style: AppTextStyle.body2.copyWith(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),

                        // Item rows
                        ..._items.asMap().entries.map(
                              (entry) => _ItemRow(
                                index: entry.key,
                                item: entry.value,
                                canRemove: _items.length > 1,
                                onRemove: () => _removeItem(entry.key),
                              ),
                            ),

                        SizedBox(height: 24.h),

                        // Submit
                        BlocBuilder<ConversationsCubit, ConversationsState>(
                          builder: (context, state) {
                            // Only the in-flight request disables Send.
                            // Appointment state never does — a request with
                            // no appointment is valid.
                            final disabled =
                                state.createPaymentRequestState.isLoading;
                            return CustomButton(
                              key: const Key('payment_request_submit_button'),
                              title: 'Send Request',
                              isLoading:
                                  state.createPaymentRequestState.isLoading,
                              onPressed: disabled ? null : _submit,
                            );
                          },
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Single item row inside the form
// ---------------------------------------------------------------------------

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.index,
    required this.item,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _LineItem item;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field
          Expanded(
            flex: 5,
            child: LabeledInputField(
              key: Key('payment_request_item_name_$index'),
              label: 'Item name',
              controller: item.nameController,
              onChanged: (_) {},
              hintText: 'e.g. Hair serum',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ),
          SizedBox(width: 8.w),
          // Price field
          Expanded(
            flex: 3,
            child: LabeledInputField(
              key: Key('payment_request_item_price_$index'),
              label: 'Price (R)',
              controller: item.priceController,
              onChanged: (_) {},
              hintText: '0.00',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v.trim()) == null) return 'Invalid';
                return null;
              },
            ),
          ),
          SizedBox(width: 8.w),
          // Quantity field. Blank is tolerated and treated as 1 by
          // `_LineItem.quantity`; anything non-numeric or < 1 is rejected so
          // the stylist notices the typo rather than silently billing for 1.
          Expanded(
            flex: 2,
            child: LabeledInputField(
              key: Key('payment_request_item_qty_$index'),
              label: 'Qty',
              controller: item.quantityController,
              onChanged: (_) {},
              hintText: '1',
              keyboardType: TextInputType.number,
              validator: (v) {
                final raw = v?.trim() ?? '';
                if (raw.isEmpty) return null;
                final parsed = int.tryParse(raw);
                if (parsed == null || parsed < 1) return 'Invalid';
                return null;
              },
            ),
          ),
          // Remove button
          if (canRemove)
            Padding(
              padding: EdgeInsets.only(top: 28.h, left: 4.w),
              child: GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.remove_circle_outline,
                  color: const Color(0xFFC62828),
                  size: 22.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
