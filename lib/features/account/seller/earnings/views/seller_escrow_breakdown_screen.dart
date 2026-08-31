import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/utils/app_extensions.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/stylist_escrow/escrow_item.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/features/account/seller/earnings/cubit/escrow_breakdown_cubit.dart';

/// Full breakdown of a stylist's held escrow funds — reached by tapping the
/// "In Escrow" tile on the Earnings > Overview screen. Data source is the
/// backend endpoint (see EscrowBreakdownCubit); all wording, statuses and
/// amounts are rendered from the payload, never derived client-side.
class SellerEscrowBreakdownScreen extends StatelessWidget {
  const SellerEscrowBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EscrowBreakdownCubit>(
      create: (_) =>
          EscrowBreakdownCubit(getIt<ProfileRepository>())..fetch(),
      child: const _SellerEscrowBreakdownView(),
    );
  }
}

class _SellerEscrowBreakdownView extends StatelessWidget {
  const _SellerEscrowBreakdownView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey5,
      appBar: const CustomAppBar(title: 'Escrow Breakdown'),
      body: SafeArea(
        child: BlocBuilder<EscrowBreakdownCubit, EscrowBreakdownState>(
          builder: (context, state) {
            final s = state.escrowState;

            if (s.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (s.hasError) {
              return _ErrorView(
                error: s.error,
                onRetry: () => context.read<EscrowBreakdownCubit>().fetch(),
              );
            }

            final data = s.data;
            final items = data?.items ?? const <EscrowItem>[];

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<EscrowBreakdownCubit>().fetch(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TotalHeader(total: data?.escrowTotal ?? 0),
                    16.verticalSpace,
                    if (items.isEmpty)
                      const _EmptyState()
                    else
                      ...items.map(
                        (item) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _EscrowItemCard(item: item),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Total header — reconciles with the "In Escrow" tile on Earnings > Overview
// ---------------------------------------------------------------------------

class _TotalHeader extends StatelessWidget {
  const _TotalHeader({required this.total});
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: AppColors.grey1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: 'Total in Escrow',
            color: Colors.grey.shade600,
          ),
          8.verticalSpace,
          AppText(
            text: total.formatAmount(),
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: AppColors.grey1),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          12.verticalSpace,
          AppText(
            text: 'No funds currently held in escrow.',
            color: Colors.grey.shade600,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // Surface the actual failure on screen (status code + backend message)
    // so we don't have to dig through the Flutter console for diagnosis.
    // Kept as a plain readout, not hidden behind a "details" toggle.
    int? statusCode;
    String? serverMessage;
    String? kindLabel;
    if (error is RemoteException) {
      final e = error! as RemoteException;
      statusCode = e.statusCode;
      serverMessage = e.errorResponse?.message;
      kindLabel = e.kind.name;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey.shade500,
            ),
            12.verticalSpace,
            AppText(
              text: "Couldn't load your escrow breakdown.",
              color: Colors.grey.shade700,
              textAlign: TextAlign.center,
            ),
            12.verticalSpace,
            // Diagnostic block — visible to help identify 401/404/500/etc.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                border: Border.all(color: AppColors.grey1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: 'Status: ${statusCode ?? 'n/a'}'
                        '${kindLabel != null ? '  ($kindLabel)' : ''}',
                    fontSize: 12,
                    color: Colors.grey.shade800,
                  ),
                  if ((serverMessage ?? '').isNotEmpty) ...[
                    4.verticalSpace,
                    AppText(
                      text: 'Message: $serverMessage',
                      fontSize: 12,
                      color: Colors.grey.shade800,
                    ),
                  ],
                  4.verticalSpace,
                  AppText(
                    text:
                        'GET /stylist/escrow — see Flutter console for the raw response body.',
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
            16.verticalSpace,
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single item card
// ---------------------------------------------------------------------------

class _EscrowItemCard extends StatelessWidget {
  const _EscrowItemCard({required this.item});
  final EscrowItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: AppColors.grey1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((item.service ?? '').isNotEmpty)
                      AppText(
                        text: item.service!,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    if ((item.bookingRef ?? '').isNotEmpty) ...[
                      2.verticalSpace,
                      AppText(
                        text: 'Ref: ${item.bookingRef}',
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ],
                    if ((item.appointmentDate ?? '').isNotEmpty) ...[
                      2.verticalSpace,
                      AppText(
                        text: _formatAppointmentDate(item.appointmentDate!),
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ],
                  ],
                ),
              ),
              8.horizontalSpace,
              AppText(
                text: (item.heldAmount ?? 0).formatAmount(),
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.primaryColor,
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AppText(
                  text: _releaseCopy(item),
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
              8.horizontalSpace,
              _StatusPill(item: item),
            ],
          ),
        ],
      ),
    );
  }

  /// Date-level release copy only — never a minute-level countdown. The
  /// actual release happens on a scheduled job that can be delayed, so a
  /// finer-grained promise would be dishonest.
  String _releaseCopy(EscrowItem item) {
    switch (item.status) {
      case 'held':
        final r = item.releaseAt;
        if (r == null) return 'Available soon';
        return 'Available after ${DateFormat('d MMM yyyy').format(r.toLocal())}';
      case 'releasing_soon':
        return 'Releasing soon';
      case 'pending_release':
        return 'Pending release';
      default:
        return '';
    }
  }

  String _formatAppointmentDate(String yyyyMmDd) {
    try {
      final parsed = DateTime.parse(yyyyMmDd);
      return DateFormat('d MMM yyyy').format(parsed);
    } catch (_) {
      return yyyyMmDd;
    }
  }
}

// ---------------------------------------------------------------------------
// Status pill — renders backend-provided status_label as the display text,
// with a color scheme keyed off status (not the label). Keeps wording under
// backend control while the visual family stays consistent.
// ---------------------------------------------------------------------------

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.item});
  final EscrowItem item;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(item.status);
    final label = (item.statusLabel ?? '').isEmpty
        ? (item.status ?? '')
        : item.statusLabel!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.text,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _PillPalette _paletteFor(String? status) {
    switch (status) {
      case 'held':
        return const _PillPalette(
          bg: AppColors.warningBg,
          text: AppColors.warningText,
        );
      case 'releasing_soon':
        return const _PillPalette(
          bg: Color(0xFFE3F2FD),
          text: Color(0xFF1565C0),
        );
      case 'pending_release':
        return const _PillPalette(
          bg: AppColors.successBg,
          text: AppColors.success,
        );
      default:
        return _PillPalette(
          bg: AppColors.grey1,
          text: Colors.grey.shade700,
        );
    }
  }
}

class _PillPalette {
  const _PillPalette({required this.bg, required this.text});
  final Color bg;
  final Color text;
}
