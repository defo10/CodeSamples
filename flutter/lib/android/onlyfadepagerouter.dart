import 'package:flutter/material.dart';

/// alternative to [MaterialPageRoute] without the growing from the bottom.
///
/// If you have a transition from one material page to another, you don't see
/// the new app bar appearing, so it appears static.
class OnlyFadeRoute<T> extends MaterialPageRoute<T> {
  OnlyFadeRoute({WidgetBuilder builder, RouteSettings settings})
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return new FadeTransition(opacity: animation, child: child);
  }
}