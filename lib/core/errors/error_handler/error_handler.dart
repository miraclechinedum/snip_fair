import 'package:flutter/material.dart';
import 'package:snip_fair/core/errors/error_handler/error_listener.dart';

abstract class ErrorHandler<E extends Exception, L extends ErrorListener> {
  void proceed(BuildContext context, E exception, L listener);
}
