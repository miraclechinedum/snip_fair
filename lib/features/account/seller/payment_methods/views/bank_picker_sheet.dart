import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/domain/entities/bank/bank.dart';
import 'package:snip_fair/core/presentation/theme/app_colors.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/modal_pill.dart';

/// Searchable bank picker for the payment method form. Pops the chosen
/// [Bank] (one of [banks], unchanged), or null when dismissed — the caller
/// then keeps its current selection.
class BankPickerSheet extends StatefulWidget {
  const BankPickerSheet({required this.banks, this.selected, super.key});

  final List<Bank> banks;
  final Bank? selected;

  /// Opens the picker as a rounded bottom sheet capped at three quarters of
  /// the screen, dismissible by its close button, a tap outside, a drag or
  /// device back.
  static Future<Bank?> show(
    BuildContext context, {
    required List<Bank> banks,
    Bank? selected,
  }) {
    return showModalBottomSheet<Bank>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      builder: (_) => BankPickerSheet(banks: banks, selected: selected),
    );
  }

  /// Case-insensitive, partial match on the bank name; surrounding spaces
  /// in [query] are ignored.
  static List<Bank> filter(List<Bank> banks, String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return banks;
    return banks
        .where((bank) => (bank.name ?? '').toLowerCase().contains(needle))
        .toList();
  }

  /// Banks are compared by name and branch code (the values sent to the
  /// backend), not by object identity.
  static bool isSameBank(Bank? a, Bank? b) =>
      a != null && b != null && a.name == b.name && a.branchCode == b.branchCode;

  @override
  State<BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<BankPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = BankPickerSheet.filter(widget.banks, _search.text);
    return Padding(
      // Lift the content above the keyboard so results stay visible.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            12.verticalSpace,
            const ModalPill(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: AppText(
                      text: 'Select Bank',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    key: const Key('bank_picker_close'),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                key: const Key('bank_picker_search'),
                controller: _search,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: AppColors.inputDecoration.copyWith(
                  hintText: 'Search bank name',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          key: const Key('bank_picker_clear'),
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
              ),
            ),
            Flexible(
              child: results.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: AppText(
                        key: Key('bank_picker_empty'),
                        text: 'No banks found.',
                        color: AppColors.grey3,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      // Scrolling closes the keyboard without selecting.
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final bank = results[index];
                        final selected =
                            BankPickerSheet.isSameBank(bank, widget.selected);
                        return ListTile(
                          key: Key('bank_option_${bank.name}'),
                          title: AppText(
                            text: bank.name ?? '',
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected
                                ? AppColors.primaryColor
                                : AppColors.blackShade1,
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryColor,
                                  semanticLabel: 'Selected',
                                )
                              : null,
                          selected: selected,
                          onTap: () => Navigator.of(context).pop(bank),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
