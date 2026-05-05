import 'package:flutter/material.dart';
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
  });
  final TextEditingController nameController;
  final TextEditingController priceController;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }

  Map<String, dynamic> toMap() => {
        'name': nameController.text.trim(),
        'unit_price': double.tryParse(priceController.text.trim()) ?? 0.0,
        'quantity': 1,
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
  State<_PaymentRequestFormSheet> createState() => _PaymentRequestFormSheetState();
}

class _PaymentRequestFormSheetState extends State<_PaymentRequestFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_LineItem> _items = [];

  List<StylistAppointment> _appointments = [];
  bool _loadingAppointments = true;
  int? _selectedAppointmentId;

  @override
  void initState() {
    super.initState();
    _addItem(); // start with one blank item
    _selectedAppointmentId = widget.appointmentId;
    _fetchAppointments();
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
        setState(() {
          _appointments = data.data ?? [];
          _loadingAppointments = false;
          // Auto-select if only one appointment and none pre-selected
          if (_selectedAppointmentId == null && _appointments.length == 1) {
            _selectedAppointmentId = _appointments.first.id;
          }
        });
      case Failure():
        setState(() => _loadingAppointments = false);
    }
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
      description:
          _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
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
                        // Appointment selector
                        Text(
                          'Appointment *',
                          style: AppTextStyle.body2.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        if (_loadingAppointments)
                          const Center(child: CircularProgressIndicator())
                        else
                          DropdownButtonFormField<int>(
                            value: _selectedAppointmentId,
                            decoration: InputDecoration(
                              hintText: 'Select an appointment',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 12.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: const BorderSide(color: AppColors.grey1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: const BorderSide(color: AppColors.grey1),
                              ),
                            ),
                            isExpanded: true,
                            items: _appointments.map((apt) {
                              final label = [
                                if (apt.bookingId != null) apt.bookingId.toString(),
                                if (apt.appointmentDate != null) apt.appointmentDate,
                              ].join(' — ');
                              return DropdownMenuItem<int>(
                                value: apt.id,
                                child: Text(
                                  label.isNotEmpty ? label : 'Appointment #${apt.id}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedAppointmentId = v),
                            validator: (v) => v == null ? 'Please select an appointment' : null,
                          ),
                        SizedBox(height: 14.h),

                        // Title
                        LabeledInputField(
                          label: 'Title *',
                          controller: _titleController,
                          onChanged: (_) {},
                          hintText: 'e.g. Additional products used',
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Title is required' : null,
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
                            return CustomButton(
                              title: 'Send Request',
                              isLoading: state.createPaymentRequestState.isLoading,
                              onPressed: state.createPaymentRequestState.isLoading ? null : _submit,
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
              label: 'Item name',
              controller: item.nameController,
              onChanged: (_) {},
              hintText: 'e.g. Hair serum',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ),
          SizedBox(width: 8.w),
          // Price field
          Expanded(
            flex: 3,
            child: LabeledInputField(
              label: 'Price (R)',
              controller: item.priceController,
              onChanged: (_) {},
              hintText: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v.trim()) == null) return 'Invalid';
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
