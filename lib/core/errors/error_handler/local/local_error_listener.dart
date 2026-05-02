import 'package:flutter/material.dart';
import 'package:snip_fair/core/errors/error_handler/error_listener.dart';

abstract class LocalErrorListener extends ErrorListener {
  void onSharedPreferenceError(BuildContext context, String message);

  void onMappingPreferenceError(BuildContext context, String message);
}
