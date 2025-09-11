import 'package:flutter/material.dart';

import '../theme/theme.dart';

class ModalPill extends StatelessWidget {
  const ModalPill({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.grey4.withOpacity(0.3),
      ),
    );
  }
}
