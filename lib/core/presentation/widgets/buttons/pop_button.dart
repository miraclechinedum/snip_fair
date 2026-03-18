import 'package:flutter/material.dart';
import 'package:snip_fair/core/presentation/theme/theme.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/animation_button_effect.dart';

class PopButton extends StatelessWidget {
  const PopButton({Key? key, this.onTap}) : super(key: key);
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.pop(context);
          },
      child: AnimationButtonEffect(
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          padding: const EdgeInsets.all(14),
          child: const Icon(
            Icons.keyboard_arrow_left,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
